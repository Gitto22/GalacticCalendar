//
//  UniverseMessageHistoryEntry.swift
//  GalacticCalendar
//

import Foundation

/// One day the user was shown a Universe Message on Home.
///
/// Persisted so History can list messages actually displayed, ordered by day.
struct UniverseMessageHistoryEntry: Identifiable, Equatable, Sendable, Hashable, Codable {

    // MARK: - Identity

    /// Stable identity: start-of-day of the display date.
    var id: Date { dayStart }

    // MARK: - Content

    /// Calendar day (start-of-day) the message was shown.
    let dayStart: Date

    /// Catalog message identifier that was shown.
    let messageId: String

    /// Localization key for the message body (snapshot at display time).
    let textKey: String

    /// Category snapshot at display time (`nil` = uncategorized / unresolved legacy).
    let category: UniverseCategory?

    /// Favorite snapshot at display time.
    let isFavorite: Bool

    /// Wall-clock time when the display was recorded.
    let recordedAt: Date

    // MARK: - Lifecycle

    /// Creates a history entry.
    /// - Parameters:
    ///   - dayStart: Start of the calendar day shown.
    ///   - messageId: Catalog message id.
    ///   - textKey: Localization key for the body.
    ///   - category: Message category, or `nil` when unresolved.
    ///   - isFavorite: Favorite flag snapshot.
    ///   - recordedAt: Recording timestamp.
    init(
        dayStart: Date,
        messageId: String,
        textKey: String,
        category: UniverseCategory?,
        isFavorite: Bool = false,
        recordedAt: Date = Date()
    ) {
        self.dayStart = dayStart
        self.messageId = messageId
        self.textKey = textKey
        self.category = category
        self.isFavorite = isFavorite
        self.recordedAt = recordedAt
    }
}
