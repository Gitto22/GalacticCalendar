//
//  UniverseMessageViewModel.swift
//  GalacticCalendar
//

import Foundation

/// Presentation model for the Home Universe Message card.
///
/// Loads today’s message from ``UniverseMessageEngine`` and refreshes when
/// the calendar day changes. Records each display day in history via the repository.
@MainActor
@Observable
final class UniverseMessageViewModel {

    // MARK: - Dependencies

    /// Day-selection engine (sole decision maker for which message applies).
    private let engine: UniverseMessageEngine

    /// Repository used to persist display history (optional for previews/tests).
    private let repository: (any UniverseMessageRepositoryProtocol)?

    /// Calendar used to detect day boundaries.
    private let calendar: Calendar

    /// Clock provider (injectable for tests).
    private let now: () -> Date

    // MARK: - Published State

    /// Localized message body for ``date``.
    private(set) var message: String = ""

    /// Category of the current message (exposed for Observation / future UI).
    private(set) var category: UniverseCategory = .motivation

    /// Calendar day the current ``message`` corresponds to.
    private(set) var date: Date = Date()

    /// Catalog id of the current message, if any.
    private(set) var messageId: String?

    /// Whether the current message is favorited (synced from persistence / engine).
    private(set) var isFavorite: Bool = false

    // MARK: - Lifecycle

    /// Creates a Universe Message presentation model.
    /// - Parameters:
    ///   - engine: Selection engine.
    ///   - repository: Optional repository for display history recording.
    ///   - calendar: Calendar for day boundaries.
    ///   - now: Clock provider.
    init(
        engine: UniverseMessageEngine,
        repository: (any UniverseMessageRepositoryProtocol)? = nil,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.engine = engine
        self.repository = repository
        self.calendar = calendar
        self.now = now
    }

    // MARK: - Share

    /// Builds the native share payload for the currently displayed Home message.
    /// - Returns: Localized text ready for ``ShareLink``.
    func shareText() -> String {
        Self.makeShareText(message: message, date: date, calendar: calendar)
    }

    /// Builds a localized share payload for any Universe Message + day.
    ///
    /// Format (localizable):
    /// 1. Headline (“Mensaje del Universo”)
    /// 2. Message body (or empty-message fallback)
    /// 3. Date
    /// 4. App name (“Galactic Calendar”)
    /// - Parameters:
    ///   - message: Message body to share.
    ///   - date: Calendar day associated with the message.
    ///   - calendar: Calendar used to format ``date``.
    /// - Returns: Share sheet text.
    static func makeShareText(
        message: String,
        date: Date,
        calendar: Calendar = .current
    ) -> String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let body: String
        if trimmed.isEmpty {
            body = String(localized: "universe_share_empty_message")
        } else {
            body = trimmed
        }

        let headline = String(localized: "universe_share_headline")
        let appName = String(localized: "universe_share_app_name")
        let dateText = date.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted)
                .calendar(calendar)
        )

        return String(
            format: String(localized: "universe_share_payload_format"),
            locale: .current,
            headline,
            body,
            dateText,
            appName
        )
    }

    // MARK: - Intents

    /// Loads the catalog if needed and publishes today’s message.
    ///
    /// Never surfaces errors — the engine always supplies a displayable message.
    func loadInitial() async {
        await engine.refreshIfNeeded()
        await publish(for: now())
    }

    /// Re-reads favorite state for the current message after History mutations.
    ///
    /// Does not change Home layout; keeps Observation state accurate.
    func syncFavoriteState() async {
        guard let messageId, let repository else {
            return
        }
        do {
            if let live = try await repository.fetch(by: messageId) {
                isFavorite = live.isFavorite
            }
        } catch {
            // Silent — Home never surfaces favorite sync errors.
        }
    }

    /// Re-publishes when the calendar day differs from ``date``.
    func refreshIfDayChanged() {
        let current = now()
        guard calendar.isDate(date, inSameDayAs: current) == false else {
            return
        }
        Task { await publish(for: current) }
    }

    /// Keeps ``message`` in sync across midnight without view-layer selection logic.
    func observeDayBoundary() async {
        await loadInitial()

        while Task.isCancelled == false {
            let current = now()
            guard let nextMidnight = calendar.nextDate(
                after: current,
                matching: DateComponents(hour: 0, minute: 0, second: 0),
                matchingPolicy: .nextTime
            ) else {
                return
            }

            let delay = nextMidnight.timeIntervalSince(current)
            guard delay > 0 else {
                await publish(for: now())
                continue
            }

            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } catch {
                return
            }

            guard Task.isCancelled == false else {
                return
            }
            await publish(for: now())
        }
    }

    // MARK: - Publishing

    /// Publishes the engine selection for an explicit calendar day and records history.
    /// - Parameter day: Day to resolve.
    func publish(for day: Date) async {
        let selected = engine.message(for: day)
        date = calendar.startOfDay(for: day)
        messageId = selected.id
        message = String(localized: String.LocalizationValue(selected.textKey))
        category = selected.category
        isFavorite = selected.isFavorite
        await recordDisplay(selected, on: date)
    }

    // MARK: - Private

    /// Persists that this message was shown on ``day`` (silent on failure).
    private func recordDisplay(_ message: UniverseMessage, on day: Date) async {
        guard let repository else {
            return
        }
        do {
            try await repository.recordDisplay(message, on: day)
        } catch {
            // History recording must never interrupt Home.
        }
    }
}
