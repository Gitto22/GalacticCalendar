//
//  UniverseMessage.swift
//  GalacticCalendar
//

import Foundation

/// Domain value representing one Universe Message in the local catalog.
///
/// Pure Foundation model prepared for SwiftData / CloudKit persistence.
/// Display text is resolved from ``textKey`` via localization in Presentation.
struct UniverseMessage: Identifiable, Equatable, Sendable, Hashable, Codable {

    // MARK: - Identity

    /// Stable catalog identifier (independent of localization).
    let id: String

    // MARK: - Content

    /// Localization key for the message body.
    let textKey: String

    /// Single category for History filtering (does not affect daily selection).
    let category: UniverseCategory

    // MARK: - Favorites (prepared)

    /// Whether the user marked this message as a favorite.
    ///
    /// Persisted on the catalog and mirrored onto history rows.
    var isFavorite: Bool

    // MARK: - Sync Metadata (prepared)

    /// Creation timestamp for local / future CloudKit mirroring.
    let createdAt: Date

    /// Last update timestamp for local / future CloudKit mirroring.
    var updatedAt: Date

    // MARK: - Lifecycle

    /// Creates a Universe Message catalog entry.
    /// - Parameters:
    ///   - id: Stable identifier.
    ///   - textKey: Localization key for the body.
    ///   - category: Message category.
    ///   - isFavorite: Favorite flag (default `false`).
    ///   - createdAt: Creation date.
    ///   - updatedAt: Last update date.
    init(
        id: String,
        textKey: String,
        category: UniverseCategory,
        isFavorite: Bool = false,
        createdAt: Date = Date(timeIntervalSince1970: 0),
        updatedAt: Date = Date(timeIntervalSince1970: 0)
    ) {
        self.id = id
        self.textKey = textKey
        self.category = category
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
