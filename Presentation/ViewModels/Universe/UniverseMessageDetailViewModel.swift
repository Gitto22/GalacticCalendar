//
//  UniverseMessageDetailViewModel.swift
//  GalacticCalendar
//

import Foundation

/// Immutable launch payload for ``UniverseMessageDetailViewModel``.
struct UniverseMessageDetailContext: Equatable, Sendable {

    // MARK: - Properties

    /// Catalog message identifier.
    let messageId: String

    /// Calendar day associated with this display (Home day or history day).
    let dayStart: Date

    /// Localized message body snapshot from the caller.
    let message: String

    /// Category snapshot (`nil` = uncategorized).
    let category: UniverseCategory?

    /// Favorite snapshot from the caller.
    let isFavorite: Bool
}

/// Presentation model for the Universe Message detail screen.
///
/// Owns display state, catalog refresh, favorite toggle, and share payload.
/// Does not participate in daily message selection.
@MainActor
@Observable
final class UniverseMessageDetailViewModel {

    // MARK: - Dependencies

    /// Catalog lookup for ``load()``.
    private let repository: any UniverseMessageRepositoryProtocol

    /// Favorite mutations (keeps engine cache aligned).
    private let favoriteService: UniverseMessageService

    /// Calendar used for date formatting.
    private let calendar: Calendar

    // MARK: - State

    /// Catalog message identifier.
    private(set) var messageId: String

    /// Day associated with this detail presentation.
    private(set) var dayStart: Date

    /// Localized full message body.
    private(set) var message: String

    /// Resolved category (`nil` = uncategorized).
    private(set) var category: UniverseCategory?

    /// Whether the message is favorited.
    private(set) var isFavorite: Bool

    /// `true` after the first ``load()`` completes.
    private(set) var didLoad: Bool = false

    // MARK: - Lifecycle

    /// Creates a detail presentation model from a navigation snapshot.
    /// - Parameters:
    ///   - context: Snapshot from Home or History.
    ///   - repository: Catalog repository.
    ///   - favoriteService: Favorite toggle façade.
    ///   - calendar: Calendar for date labels.
    init(
        context: UniverseMessageDetailContext,
        repository: any UniverseMessageRepositoryProtocol,
        favoriteService: UniverseMessageService,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.favoriteService = favoriteService
        self.calendar = calendar
        self.messageId = context.messageId
        self.dayStart = calendar.startOfDay(for: context.dayStart)
        self.message = context.message
        self.category = context.category
        self.isFavorite = context.isFavorite
    }

    // MARK: - Derived

    /// Localized category label when a category is present.
    var categoryText: String? {
        category.map(UniverseCategoryDisplayNames.displayName(for:))
    }

    /// Localized date label for the associated day.
    var dateText: String {
        dayStart.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted)
                .calendar(calendar)
        )
    }

    /// Native share payload for the detail screen.
    var shareText: String {
        UniverseMessageViewModel.makeShareText(
            message: message,
            date: dayStart,
            calendar: calendar
        )
    }

    // MARK: - Intents

    /// Refreshes catalog fields (body, category, favorite) for ``messageId``.
    ///
    /// Failures keep the snapshot from ``UniverseMessageDetailContext``.
    func load() async {
        defer { didLoad = true }

        do {
            guard let live = try await repository.fetch(by: messageId) else {
                return
            }
            messageId = live.id
            message = String(localized: String.LocalizationValue(live.textKey))
            category = live.category
            isFavorite = live.isFavorite
        } catch {
            // Keep snapshot; detail never surfaces catalog errors.
        }
    }

    /// Toggles favorite for the displayed message and updates local state.
    func toggleFavorite() async {
        let stub = UniverseMessage(
            id: messageId,
            textKey: "",
            category: category ?? .motivation,
            isFavorite: isFavorite
        )

        do {
            let updated = try await favoriteService.toggleFavorite(stub)
            isFavorite = updated.isFavorite
            category = updated.category
            if updated.textKey.isEmpty == false {
                message = String(localized: String.LocalizationValue(updated.textKey))
            }
        } catch {
            // Keep UI stable; next load() reconciles.
        }
    }
}
