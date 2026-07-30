//
//  UnavailableEventRepository.swift
//  GalacticCalendar
//

import Foundation

/// Event repository used when the on-disk store cannot be opened.
///
/// ## Contract
/// - Reads return empty / `nil` (safe; no invented rows).
/// - Every write throws ``EventRepositoryError/saveFailed`` so Application maps to ``storeUnavailable``.
@MainActor
final class UnavailableEventRepository: EventRepositoryProtocol {

    // MARK: - Create / Write

    func create(_ event: Event) async throws {
        throw EventRepositoryError.saveFailed
    }

    func update(_ event: Event) async throws {
        throw EventRepositoryError.saveFailed
    }

    func delete(_ event: Event) async throws {
        try await delete(id: event.id)
    }

    func delete(id: UUID) async throws {
        throw EventRepositoryError.saveFailed
    }

    func duplicate(_ event: Event) async throws -> Event {
        throw EventRepositoryError.saveFailed
    }

    // MARK: - Read (safe empty)

    func fetchAll() async throws -> [Event] { [] }

    func fetch(by id: UUID) async throws -> Event? { nil }

    func fetch(on date: Date) async throws -> [Event] { [] }

    func fetch(in interval: DateInterval) async throws -> [Event] { [] }

    func fetchGroupedByDay(in interval: DateInterval) async throws -> [Date: [Event]] { [:] }
}
