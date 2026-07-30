//
//  UniverseHistoryViewModel.swift
//  GalacticCalendar
//

import Foundation

/// Favorite scope filter for the history list.
enum UniverseHistoryFavoriteFilter: String, CaseIterable, Identifiable, Sendable {

    // MARK: - Cases

    /// Show every history entry (subject to category / search).
    case all

    /// Show only favorited entries.
    case favorites

    // MARK: - Identifiable

    var id: String { rawValue }
}

/// Row model for ``UniverseMessageRow`` (Presentation-ready, no SwiftUI).
struct UniverseHistoryRowItem: Identifiable, Equatable, Sendable {

    // MARK: - Properties

    /// Stable identity matching the history day.
    let id: Date

    /// Catalog message id (for favorite toggles).
    let messageId: String

    /// Calendar day shown.
    let dayStart: Date

    /// Localized date label.
    let dateText: String

    /// Localized full message body.
    let message: String

    /// Localized category label when present.
    let categoryText: String?

    /// Resolved category (`nil` = uncategorized).
    let category: UniverseCategory?

    /// Favorite indicator.
    let isFavorite: Bool
}

/// Presentation model for the Universe Message history screen.
///
/// Loads display history; filters by category, favorites, and search.
/// Filter state is retained while this ViewModel remains alive (view open).
/// Can present ``UniverseMessageDetailViewModel`` for a selected row.
@MainActor
@Observable
final class UniverseHistoryViewModel {

    // MARK: - Dependencies

    /// History + catalog data access.
    private let repository: any UniverseMessageRepositoryProtocol

    /// Favorite mutations + category metadata façade.
    private let favoriteService: UniverseMessageService

    /// Calendar used for date formatting.
    private let calendar: Calendar

    // MARK: - State

    /// Unfiltered history loaded from persistence.
    private(set) var entries: [UniverseMessageHistoryEntry] = []

    /// Real-time search query (message text and category).
    var searchText: String = ""

    /// Todos / Favoritos scope filter.
    var favoriteFilter: UniverseHistoryFavoriteFilter = .all

    /// Category filter (`nil` = all categories). Retained while the view stays open.
    var selectedCategory: UniverseCategory? = nil

    /// `true` while the detail screen is presented from History.
    var isPresentingDetail: Bool = false

    /// Detail ViewModel for the selected history row, if any.
    private(set) var detailViewModel: UniverseMessageDetailViewModel?

    /// `true` after the first load attempt completes.
    private(set) var didLoad: Bool = false

    // MARK: - Lifecycle

    /// Creates a history presentation model.
    /// - Parameters:
    ///   - repository: Universe message repository.
    ///   - favoriteService: Favorite toggle / category metadata service.
    ///   - calendar: Calendar for day formatting.
    init(
        repository: any UniverseMessageRepositoryProtocol,
        favoriteService: UniverseMessageService,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.favoriteService = favoriteService
        self.calendar = calendar
    }

    // MARK: - Derived

    /// Categories for the horizontal selector (does not affect daily engine).
    var selectableCategories: [UniverseCategory] {
        favoriteService.selectableCategories
    }

    /// Rows visible after category, favorite, search filters, and date sort.
    var displayedRows: [UniverseHistoryRowItem] {
        var working = entries.sorted { $0.dayStart > $1.dayStart }

        if let selectedCategory {
            working = working.filter { $0.category == selectedCategory }
        }

        if favoriteFilter == .favorites {
            working = working.filter(\.isFavorite)
        }

        let query = normalizedQuery
        if query.isEmpty == false {
            working = working.filter { matches($0, query: query) }
        }

        return working.map(makeRow(from:))
    }

    /// `true` when there is no history at all (ignores filters).
    var isHistoryEmpty: Bool {
        didLoad && entries.isEmpty
    }

    /// `true` when history exists but the current filters match nothing.
    var isFilterEmpty: Bool {
        didLoad && entries.isEmpty == false && displayedRows.isEmpty
    }

    // MARK: - Intents

    /// Loads history from the repository (failures yield an empty list).
    func load() async {
        do {
            entries = try await repository.fetchHistory()
        } catch {
            entries = []
        }
        didLoad = true
    }

    /// Toggles favorite for the row’s catalog message and updates local state immediately.
    /// - Parameter item: History row to toggle.
    func toggleFavorite(for item: UniverseHistoryRowItem) async {
        let stub = UniverseMessage(
            id: item.messageId,
            textKey: "",
            category: item.category ?? .motivation,
            isFavorite: item.isFavorite
        )

        do {
            let updated = try await favoriteService.toggleFavorite(stub)
            applyFavorite(messageId: updated.id, isFavorite: updated.isFavorite)
        } catch {
            // Keep UI stable; next load() reconciles.
        }
    }

    /// Returns the native share payload for a history row.
    func shareText(for item: UniverseHistoryRowItem) -> String {
        UniverseMessageViewModel.makeShareText(
            message: item.message,
            date: item.dayStart,
            calendar: calendar
        )
    }

    /// Presents the detail screen for a history row.
    /// - Parameter item: Row selected by the user.
    func presentDetail(for item: UniverseHistoryRowItem) {
        let context = UniverseMessageDetailContext(
            messageId: item.messageId,
            dayStart: item.dayStart,
            message: item.message,
            category: item.category,
            isFavorite: item.isFavorite
        )
        detailViewModel = UniverseMessageDetailViewModel(
            context: context,
            repository: repository,
            favoriteService: favoriteService,
            calendar: calendar
        )
        isPresentingDetail = true
    }

    /// Dismisses the detail screen and mirrors favorite state into history rows.
    func dismissDetail() {
        if let detailViewModel {
            applyFavorite(
                messageId: detailViewModel.messageId,
                isFavorite: detailViewModel.isFavorite
            )
        }
        isPresentingDetail = false
        detailViewModel = nil
    }

    // MARK: - Private

    /// Applies a favorite flag to all in-memory history entries for a message.
    private func applyFavorite(messageId: String, isFavorite: Bool) {
        entries = entries.map { entry in
            guard entry.messageId == messageId else {
                return entry
            }
            return UniverseMessageHistoryEntry(
                dayStart: entry.dayStart,
                messageId: entry.messageId,
                textKey: entry.textKey,
                category: entry.category,
                isFavorite: isFavorite,
                recordedAt: entry.recordedAt
            )
        }
    }

    /// Lowercased trimmed search query.
    private var normalizedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Returns whether an entry matches the search query by message or category.
    private func matches(_ entry: UniverseMessageHistoryEntry, query: String) -> Bool {
        let message = localizedMessage(for: entry).lowercased()
        if message.contains(query) {
            return true
        }
        if let category = entry.category {
            let name = localizedCategory(for: category).lowercased()
            if name.contains(query) {
                return true
            }
            return category.rawValue.lowercased().contains(query)
        }
        return false
    }

    /// Builds a presentation row from a domain history entry.
    private func makeRow(from entry: UniverseMessageHistoryEntry) -> UniverseHistoryRowItem {
        UniverseHistoryRowItem(
            id: entry.dayStart,
            messageId: entry.messageId,
            dayStart: entry.dayStart,
            dateText: formattedDate(entry.dayStart),
            message: localizedMessage(for: entry),
            categoryText: entry.category.map(localizedCategory(for:)),
            category: entry.category,
            isFavorite: entry.isFavorite
        )
    }

    /// Localizes the message body from the stored text key.
    private func localizedMessage(for entry: UniverseMessageHistoryEntry) -> String {
        String(localized: String.LocalizationValue(entry.textKey))
    }

    /// Localizes a category for display and search.
    private func localizedCategory(for category: UniverseCategory) -> String {
        UniverseCategoryDisplayNames.displayName(for: category)
    }

    /// Formats a day for the history row.
    private func formattedDate(_ dayStart: Date) -> String {
        dayStart.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted)
                .calendar(calendar)
        )
    }
}

// MARK: - Category Display Names

/// Localized labels for ``UniverseCategory`` (Presentation-only).
enum UniverseCategoryDisplayNames {

    // MARK: - Lookup

    /// Returns a localized display name for a category.
    static func displayName(for category: UniverseCategory) -> String {
        switch category {
        case .motivation:
            return String(localized: "universe_category_motivation")
        case .productivity:
            return String(localized: "universe_category_productivity")
        case .calm:
            return String(localized: "universe_category_calm")
        case .reflection:
            return String(localized: "universe_category_reflection")
        case .gratitude:
            return String(localized: "universe_category_gratitude")
        case .relationships:
            return String(localized: "universe_category_relationships")
        case .success:
            return String(localized: "universe_category_success")
        case .personalGrowth:
            return String(localized: "universe_category_personal_growth")
        }
    }
}
