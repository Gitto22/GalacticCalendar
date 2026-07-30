//
//  UniverseMessageHistoryEntity.swift
//  GalacticCalendar
//

import Foundation
import SwiftData

/// SwiftData persistence model for a day a Universe Message was shown.
@Model
final class UniverseMessageHistoryEntity {

    // MARK: - Identity

    /// Start-of-day for the display date (unique: one entry per calendar day).
    @Attribute(.unique) var dayStart: Date

    // MARK: - Snapshot

    /// Catalog message id shown that day.
    var messageId: String

    /// Localization key snapshot.
    var textKey: String

    /// Raw ``UniverseCategory`` value.
    var categoryRawValue: String

    /// Favorite snapshot (mutations later).
    var isFavorite: Bool

    /// When the display was recorded.
    var recordedAt: Date

    // MARK: - Lifecycle

    /// Creates a history persistence entity.
    init(
        dayStart: Date,
        messageId: String,
        textKey: String,
        categoryRawValue: String,
        isFavorite: Bool = false,
        recordedAt: Date = Date()
    ) {
        self.dayStart = dayStart
        self.messageId = messageId
        self.textKey = textKey
        self.categoryRawValue = categoryRawValue
        self.isFavorite = isFavorite
        self.recordedAt = recordedAt
    }
}
