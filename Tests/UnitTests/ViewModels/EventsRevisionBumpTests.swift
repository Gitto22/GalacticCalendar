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
