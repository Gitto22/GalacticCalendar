//
//  UniverseMessageHistoryEntityMapper.swift
//  GalacticCalendar
//

import Foundation

/// Maps between Domain ``UniverseMessageHistoryEntry`` and ``UniverseMessageHistoryEntity``.
enum UniverseMessageHistoryEntityMapper {

    // MARK: - To Persistence

    /// Creates a new SwiftData entity from a domain history entry.
    static func makeEntity(from entry: UniverseMessageHistoryEntry) -> UniverseMessageHistoryEntity {
        UniverseMessageHistoryEntity(
            dayStart: entry.dayStart,
            messageId: entry.messageId,
            textKey: entry.textKey,
            categoryRawValue: entry.category?.rawValue ?? "",
            isFavorite: entry.isFavorite,
            recordedAt: entry.recordedAt
        )
    }

    /// Writes domain values onto an existing persistence entity.
    static func apply(_ entry: UniverseMessageHistoryEntry, to entity: UniverseMessageHistoryEntity) {
        entity.messageId = entry.messageId
        entity.textKey = entry.textKey
        entity.categoryRawValue = entry.category?.rawValue ?? ""
        entity.isFavorite = entry.isFavorite
        entity.recordedAt = entry.recordedAt
    }

    // MARK: - To Domain

    /// Creates a domain history entry from a persistence entity.
    static func makeDomain(from entity: UniverseMessageHistoryEntity) -> UniverseMessageHistoryEntry {
        UniverseMessageHistoryEntry(
            dayStart: entity.dayStart,
            messageId: entity.messageId,
            textKey: entity.textKey,
            category: UniverseCategory.resolve(entity.categoryRawValue),
            isFavorite: entity.isFavorite,
            recordedAt: entity.recordedAt
        )
    }
}
