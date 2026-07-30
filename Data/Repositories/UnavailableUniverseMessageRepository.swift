//
//  UnavailableUniverseMessageRepository.swift
//  GalacticCalendar
//

import Foundation

/// Universe repository used when the on-disk store cannot be opened.
///
/// Reads return empty results. Writes / seeding throw ``saveFailed``.
@MainActor
final class UnavailableUniverseMessageRepository: UniverseMessageRepositoryProtocol {

    func fetchAll() async throws -> [UniverseMessage] { [] }

    func fetch(by id: String) async throws -> UniverseMessage? { nil }

    func ensureSeeded() async throws {
        throw UniverseMessageRepositoryError.saveFailed
    }

    func fetchHistory() async throws -> [UniverseMessageHistoryEntry] { [] }

    func recordDisplay(_ message: UniverseMessage, on day: Date) async throws {
        throw UniverseMessageRepositoryError.saveFailed
    }

    func toggleFavorite(_ message: UniverseMessage) async throws -> UniverseMessage {
        throw UniverseMessageRepositoryError.saveFailed
    }

    func favoriteMessages() async throws -> [UniverseMessage] { [] }

    func isFavorite(_ message: UniverseMessage) async throws -> Bool { false }
}
