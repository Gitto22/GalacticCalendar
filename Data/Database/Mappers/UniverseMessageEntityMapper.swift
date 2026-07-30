//
//  UniverseMessageEntityMapper.swift
//  GalacticCalendar
//

import Foundation

/// Maps between Domain ``UniverseMessage`` and persistence ``UniverseMessageEntity``.
enum UniverseMessageEntityMapper {

    // MARK: - To Persistence

    /// Creates a new SwiftData entity from a domain message.
    /// - Parameter message: Domain message.
    /// - Returns: Persistence entity ready for insertion.
    static func makeEntity(from message: UniverseMessage) -> UniverseMessageEntity {
        UniverseMessageEntity(
            id: message.id,
            textKey: message.textKey,
            categoryRawValue: message.category.rawValue,
            isFavorite: message.isFavorite,
            createdAt: message.createdAt,
            updatedAt: message.updatedAt
        )
    }

    /// Writes domain values onto an existing persistence entity.
    /// - Parameters:
    ///   - message: Source domain message.
    ///   - entity: Target persistence entity.
    static func apply(_ message: UniverseMessage, to entity: UniverseMessageEntity) {
        entity.textKey = message.textKey
        entity.categoryRawValue = message.category.rawValue
        entity.isFavorite = message.isFavorite
        entity.updatedAt = message.updatedAt
    }

    // MARK: - To Domain

    /// Creates a domain message from a persistence entity.
    /// - Parameter entity: Persisted entity.
    /// - Returns: Domain ``UniverseMessage``.
    static func makeDomain(from entity: UniverseMessageEntity) -> UniverseMessage {
        UniverseMessage(
            id: entity.id,
            textKey: entity.textKey,
            category: UniverseCategory.resolve(entity.categoryRawValue) ?? .motivation,
            isFavorite: entity.isFavorite,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }
}
