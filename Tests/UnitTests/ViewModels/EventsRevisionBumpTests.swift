//
//  EventsRevisionBumpTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Verifies the reactive catalog published by ``EventPersistenceService``.
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

    func testBootstrapLoadsCatalog() async throws {
        let event = sampleEvent()
        let service = makeService(seed: [event])
        try await service.refresh()
        XCTAssertEqual(service.events.map(\.id), [event.id])
        XCTAssertNil(service.lastError)
    }

    func testCreateUpdatesCatalogAndRevision() async throws {
        let service = makeService()
        try await service.refresh()
        let before = service.eventsRevision

        try await service.create(sampleEvent())
        XCTAssertEqual(service.events.count, 1)
        XCTAssertEqual(service.eventsRevision, before + 1)
    }

    func testDeleteRemovesFromCatalog() async throws {
        let event = sampleEvent()
        let service = makeService(seed: [event])
        try await service.refresh()

        try await service.delete(event)
        XCTAssertTrue(service.events.isEmpty)
    }

    func testEventsOnDateFiltersCatalog() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let service = makeService()
        try await service.refresh()
        try await service.create(Event(title: "Today", date: today, color: .green))
        try await service.create(Event(title: "Tomorrow", date: tomorrow, color: .red))

        XCTAssertEqual(service.events(on: today).map(\.title), ["Today"])
    }

    func testRefreshFailureSurfacesCatalogLoadError() async {
        let service = EventPersistenceService(
            repository: FailingFetchEventRepository()
        )

        do {
            try await service.refresh()
            XCTFail("Expected catalogLoadFailed")
        } catch EventPersistenceError.catalogLoadFailed {
            XCTAssertEqual(service.lastError, .catalogLoadFailed)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - Failing Fetch Repository

@MainActor
private final class FailingFetchEventRepository: EventRepositoryProtocol {

    func create(_ event: Event) async throws {}

    func fetchAll() async throws -> [Event] {
        throw EventRepositoryError.saveFailed
    }

    func fetch(by id: UUID) async throws -> Event? { nil }

    func fetch(on date: Date) async throws -> [Event] { [] }

    func fetch(in interval: DateInterval) async throws -> [Event] { [] }

    func fetchGroupedByDay(in interval: DateInterval) async throws -> [Date: [Event]] { [:] }

    func update(_ event: Event) async throws {}

    func delete(_ event: Event) async throws {}

    func delete(id: UUID) async throws {}

    func duplicate(_ event: Event) async throws -> Event { event.duplicated() }
}
