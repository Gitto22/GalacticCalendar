//
//  EventsRevisionBumpTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Verifies the reactive catalog on ``EventPersistenceService``.
@MainActor
final class EventsRevisionBumpTests: XCTestCase {

    // MARK: - Helpers

    private func makeService(seed: [Event] = []) -> EventPersistenceService {
        EventPersistenceService(repository: InMemoryEventRepository(seed: seed))
    }

    private func sampleEvent(title: String = "Sync") -> Event {
        Event(title: title, date: Date(), color: .green)
    }

    // MARK: - Tests

    func testBootstrapLoadsCatalog() async {
        let event = sampleEvent()
        let service = makeService(seed: [event])
        await service.bootstrap()
        XCTAssertEqual(service.events.map(\.id), [event.id])
    }

    func testCreateUpdatesCatalogAndRevision() async throws {
        let service = makeService()
        await service.bootstrap()
        let before = service.eventsRevision

        try await service.create(sampleEvent())
        XCTAssertEqual(service.events.count, 1)
        XCTAssertEqual(service.eventsRevision, before + 1)
    }

    func testDeleteRemovesFromCatalog() async throws {
        let event = sampleEvent()
        let service = makeService(seed: [event])
        await service.bootstrap()

        try await service.delete(event)
        XCTAssertTrue(service.events.isEmpty)
    }

    func testEventsOnDateFiltersCatalog() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let service = makeService()
        await service.bootstrap()
        try await service.create(Event(title: "Today", date: today, color: .green))
        try await service.create(Event(title: "Tomorrow", date: tomorrow, color: .red))

        XCTAssertEqual(service.events(on: today).map(\.title), ["Today"])
    }
}

// MARK: - In-Memory Repository

@MainActor
private final class InMemoryEventRepository: EventRepositoryProtocol {

    private var storage: [UUID: Event]

    init(seed: [Event] = []) {
        storage = Dictionary(uniqueKeysWithValues: seed.map { ($0.id, $0) })
    }

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
