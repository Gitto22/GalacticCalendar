//
//  UniverseMessageRepository.swift
//  GalacticCalendar
//

import Foundation
import SwiftData

/// SwiftData-backed repository for the Universe Message catalog and display history.
///
/// ## Role
/// Sole data-access boundary for ``UniverseMessage`` and ``UniverseMessageHistoryEntry``.
/// Seeds a bundled local catalog on first use. No day-selection logic.
@MainActor
final class UniverseMessageRepository: UniverseMessageRepositoryProtocol {

    // MARK: - Properties

    /// SwiftData model context used for local persistence.
    private let modelContext: ModelContext

    /// Calendar used for day-boundary identity when recording history.
    private let calendar: Calendar

    // MARK: - Lifecycle

    /// Creates a repository bound to a model context.
    /// - Parameters:
    ///   - modelContext: SwiftData context.
    ///   - calendar: Calendar for history day keys.
    init(modelContext: ModelContext, calendar: Calendar = .current) {
        self.modelContext = modelContext
        self.calendar = calendar
    }

    // MARK: - Catalog

    func fetchAll() async throws -> [UniverseMessage] {
        try await ensureSeeded()

        do {
            let descriptor = FetchDescriptor<UniverseMessageEntity>(
                sortBy: [SortDescriptor(\.id, order: .forward)]
            )
            let entities = try modelContext.fetch(descriptor)
            let messages = entities.map(UniverseMessageEntityMapper.makeDomain(from:))
            guard messages.isEmpty == false else {
                throw UniverseMessageRepositoryError.emptyCatalog
            }
            return messages
        } catch let error as UniverseMessageRepositoryError {
            throw error
        } catch {
            throw UniverseMessageRepositoryError.catalogUnavailable
        }
    }

    func fetch(by id: String) async throws -> UniverseMessage? {
        try await ensureSeeded()
        return try fetchEntity(id: id).map(UniverseMessageEntityMapper.makeDomain(from:))
    }

    func ensureSeeded() async throws {
        do {
            let descriptor = FetchDescriptor<UniverseMessageEntity>()
            let existing = try modelContext.fetch(descriptor)
            guard existing.isEmpty else {
                return
            }

            for message in Self.bundledCatalog {
                modelContext.insert(UniverseMessageEntityMapper.makeEntity(from: message))
            }
            try save()
        } catch let error as UniverseMessageRepositoryError {
            throw error
        } catch {
            throw UniverseMessageRepositoryError.catalogUnavailable
        }
    }

    // MARK: - History

    func fetchHistory() async throws -> [UniverseMessageHistoryEntry] {
        do {
            let descriptor = FetchDescriptor<UniverseMessageHistoryEntity>(
                sortBy: [SortDescriptor(\.dayStart, order: .reverse)]
            )
            let entities = try modelContext.fetch(descriptor)
            return entities.map(UniverseMessageHistoryEntityMapper.makeDomain(from:))
        } catch {
            throw UniverseMessageRepositoryError.historyUnavailable
        }
    }

    func recordDisplay(_ message: UniverseMessage, on day: Date) async throws {
        let dayStart = calendar.startOfDay(for: day)
        // Prefer live catalog favorite so history stays aligned with persistence.
        let favoriteFlag: Bool
        if let live = try? fetchEntity(id: message.id) {
            favoriteFlag = live.isFavorite
        } else {
            favoriteFlag = message.isFavorite
        }

        let entry = UniverseMessageHistoryEntry(
            dayStart: dayStart,
            messageId: message.id,
            textKey: message.textKey,
            category: message.category,
            isFavorite: favoriteFlag,
            recordedAt: Date()
        )

        do {
            if let existing = try fetchHistoryEntity(dayStart: dayStart) {
                UniverseMessageHistoryEntityMapper.apply(entry, to: existing)
            } else {
                modelContext.insert(UniverseMessageHistoryEntityMapper.makeEntity(from: entry))
            }
            try save()
        } catch let error as UniverseMessageRepositoryError {
            throw error
        } catch {
            throw UniverseMessageRepositoryError.saveFailed
        }
    }

    // MARK: - Favorites

    @discardableResult
    func toggleFavorite(_ message: UniverseMessage) async throws -> UniverseMessage {
        try await ensureSeeded()

        guard let entity = try fetchEntity(id: message.id) else {
            throw UniverseMessageRepositoryError.notFound(message.id)
        }

        let newValue = !entity.isFavorite
        entity.isFavorite = newValue
        entity.updatedAt = Date()
        try syncHistoryFavorites(messageId: message.id, isFavorite: newValue)
        try save()

        return UniverseMessageEntityMapper.makeDomain(from: entity)
    }

    func favoriteMessages() async throws -> [UniverseMessage] {
        let all = try await fetchAll()
        return all.filter(\.isFavorite)
    }

    func isFavorite(_ message: UniverseMessage) async throws -> Bool {
        try await ensureSeeded()
        guard let entity = try fetchEntity(id: message.id) else {
            throw UniverseMessageRepositoryError.notFound(message.id)
        }
        return entity.isFavorite
    }

    // MARK: - Private

    /// Mirrors catalog favorite onto all history rows for the message.
    private func syncHistoryFavorites(messageId: String, isFavorite: Bool) throws {
        let predicate = #Predicate<UniverseMessageHistoryEntity> { entity in
            entity.messageId == messageId
        }
        let descriptor = FetchDescriptor<UniverseMessageHistoryEntity>(predicate: predicate)
        let entities = try modelContext.fetch(descriptor)
        for entity in entities {
            entity.isFavorite = isFavorite
        }
    }

    /// Fetches a catalog entity by id.
    private func fetchEntity(id: String) throws -> UniverseMessageEntity? {
        let predicate = #Predicate<UniverseMessageEntity> { entity in
            entity.id == id
        }
        var descriptor = FetchDescriptor<UniverseMessageEntity>(predicate: predicate)
        descriptor.fetchLimit = 1
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            throw UniverseMessageRepositoryError.catalogUnavailable
        }
    }

    /// Fetches a history entity for a start-of-day key.
    private func fetchHistoryEntity(dayStart: Date) throws -> UniverseMessageHistoryEntity? {
        let predicate = #Predicate<UniverseMessageHistoryEntity> { entity in
            entity.dayStart == dayStart
        }
        var descriptor = FetchDescriptor<UniverseMessageHistoryEntity>(predicate: predicate)
        descriptor.fetchLimit = 1
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            throw UniverseMessageRepositoryError.historyUnavailable
        }
    }

    /// Saves the model context.
    private func save() throws {
        do {
            try modelContext.save()
        } catch {
            throw UniverseMessageRepositoryError.saveFailed
        }
    }

    // MARK: - Bundled Defaults

    /// Default on-device messages. Keys resolve through Localizable.strings.
    private static let bundledCatalog: [UniverseMessage] = [
        UniverseMessage(id: "um_001", textKey: "universe_message_body", category: .motivation),
        UniverseMessage(id: "um_002", textKey: "universe_message_body_02", category: .reflection),
        UniverseMessage(id: "um_003", textKey: "universe_message_body_03", category: .productivity),
        UniverseMessage(id: "um_004", textKey: "universe_message_body_04", category: .gratitude),
        UniverseMessage(id: "um_005", textKey: "universe_message_body_05", category: .calm),
        UniverseMessage(id: "um_006", textKey: "universe_message_body_06", category: .personalGrowth),
        UniverseMessage(id: "um_007", textKey: "universe_message_body_07", category: .success),
        UniverseMessage(id: "um_008", textKey: "universe_message_body_08", category: .relationships)
    ]
}
