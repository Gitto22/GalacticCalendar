//
//  InMemoryEventRepository.swift
//  GalacticCalendar
//

import Foundation
@testable import GalacticCalendar

/// Shared in-memory ``EventRepositoryProtocol`` for unit tests.
@MainActor
final class InMemoryEventRepository: EventRepositoryProtocol {

    // MARK: - State

    private var storage: [UUID: Event]

    // MARK: - Lifecycle

    init(seed: [Event] = []) {
        storage = Dictionary(uniqueKeysWithValues: seed.map { ($0.id, $0) })
    }

    // MARK: - EventRepositoryProtocol

    func create(_ event: Event) async throws {
        storage[event.id] = event
    }

    func fetchAll() async throws -> [Event] {
        Array(storage.values)
    }

    func fetch(by id: UUID) async throws -> Event? {
        storage[id]
    }

    func fetch(on date: Date) async throws -> [Event] {
        let calendar = Calendar.current
        return storage.values.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func fetch(in interval: DateInterval) async throws -> [Event] {
        storage.values.filter { interval.contains($0.date) }
    }

    func fetchGroupedByDay(in interval: DateInterval) async throws -> [Date: [Event]] {
        let events = try await fetch(in: interval)
        return Dictionary(grouping: events) { Calendar.current.startOfDay(for: $0.date) }
    }

    func fetch(matching criteria: EventSearchCriteria) async throws -> [Event] {
        let all = Array(storage.values)
        guard criteria.isEmpty == false else {
            return all
        }
        return criteria.filter(all)
    }

    func update(_ event: Event) async throws {
        guard storage[event.id] != nil else {
            throw EventRepositoryError.notFound(event.id)
        }
        storage[event.id] = event
    }

    func delete(_ event: Event) async throws {
        try await delete(id: event.id)
    }

    func delete(id: UUID) async throws {
        guard storage.removeValue(forKey: id) != nil else {
            throw EventRepositoryError.notFound(id)
        }
    }

    func duplicate(_ event: Event) async throws -> Event {
        let copy = event.duplicated()
        try await create(copy)
        return copy
    }
}
