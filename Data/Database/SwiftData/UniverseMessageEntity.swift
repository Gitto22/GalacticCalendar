//
//  UniverseMessageEntity.swift
//  GalacticCalendar
//

import Foundation
import SwiftData

/// SwiftData persistence model for ``UniverseMessage``.
///
/// Kept separate from the Domain model. Raw category strings stay CloudKit-friendly.
/// Favorite and timestamp fields are ready for future sync / favorites sprints.
@Model
final class UniverseMessageEntity {

    // MARK: - Identity

    /// Stable unique catalog identifier mirrored from the domain model.
    @Attribute(.unique) var id: String

    // MARK: - Content

    /// Localization key for the message body.
    var textKey: String

    /// Raw value for ``UniverseCategory``.
    var categoryRawValue: String

    // MARK: - Favorites (prepared)

    /// Persisted favorite flag (mutations ship in a later sprint).
    var isFavorite: Bool

    // MARK: - Sync Metadata (prepared)

    /// Creation timestamp.
    var createdAt: Date

    /// Last update timestamp.
    var updatedAt: Date

    // MARK: - Lifecycle

    /// Creates a persistence entity.
    init(
        id: String,
        textKey: String,
        categoryRawValue: String,
        isFavorite: Bool = false,
        createdAt: Date = Date(timeIntervalSince1970: 0),
        updatedAt: Date = Date(timeIntervalSince1970: 0)
    ) {
        self.id = id
        self.textKey = textKey
        self.categoryRawValue = categoryRawValue
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
