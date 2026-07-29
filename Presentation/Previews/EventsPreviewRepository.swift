//
//  EventsPreviewRepository.swift
//  GalacticCalendar
//

#if DEBUG
import Foundation

/// Shared in-memory repository for Events module SwiftUI previews.
///
/// Avoids duplicating empty ``EventRepositoryProtocol`` stubs in each Events view.
@MainActor
final class EventsPreviewRepository: EventRepositoryProtocol {

    // MARK: - State

    private var storage: [UUID: Event]

    // MARK: - Lifecycle

    /// Creates a preview repository.
    /// - Parameter seed: Optional events available via ``fetchAll()``.
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

    func fetchRecurring() async throws -> [Event] {
        storage.values.filter(\.repeatRule.isRecurring)
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
#endif
