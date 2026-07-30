//
//  SwiftDataCatalogIntegrationTests.swift
//  GalacticCalendar
//
//  QA-02 — Case 5: catalog refresh / coherence (bootstrap → refresh).
//

import XCTest
import SwiftData
@testable import GalacticCalendar

@MainActor
final class SwiftDataCatalogIntegrationTests: XCTestCase {

    private var container: ModelContainer!
    private var repository: EventRepository!
    private var persistence: EventPersistenceService!

    override func setUp() async throws {
        try await super.setUp()
        container = try SwiftDataIntegrationHarness.makeInMemoryContainer()
        repository = EventRepository(modelContext: container.mainContext)
        persistence = EventPersistenceService(repository: repository)
    }

    override func tearDown() async throws {
        persistence = nil
        repository = nil
        container = nil
        try await super.tearDown()
    }

    func testRefreshPublishesCatalogAndAdvancesRevision() async throws {
        XCTAssertEqual(persistence.eventsRevision, 0)
        XCTAssertTrue(persistence.events.isEmpty)

        let event = Event(
            title: "Catalog A",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            color: .green
        )
        try await repository.create(event)

        // Catalog is empty until refresh (repository write does not auto-publish).
        XCTAssertTrue(persistence.events.isEmpty)

        try await persistence.refresh()
        let revisionAfterFirst = persistence.eventsRevision

        XCTAssertEqual(persistence.events.count, 1)
        XCTAssertEqual(persistence.events.first?.title, "Catalog A")
        XCTAssertGreaterThan(revisionAfterFirst, 0)
        XCTAssertNil(persistence.lastError)

        let second = Event(
            title: "Catalog B",
            date: Date(timeIntervalSince1970: 1_900_003_600),
            color: .yellow
        )
        try await repository.create(second)
        try await persistence.refresh()

        XCTAssertEqual(persistence.events.count, 2)
        XCTAssertEqual(Set(persistence.events.map(\.title)), Set(["Catalog A", "Catalog B"]))
        XCTAssertGreaterThan(persistence.eventsRevision, revisionAfterFirst)
    }

    func testCreateThroughPersistenceUpdatesCatalogCoherently() async throws {
        // EventPersistenceService.create → persist → refresh catalog.
        let event = Event(
            title: "Via Facade",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            color: .orange
        )
        try await persistence.create(event)

        XCTAssertEqual(persistence.events.count, 1)
        XCTAssertEqual(persistence.events.first?.id, event.id)
        XCTAssertEqual(try await repository.fetchAll().count, 1)

        try await persistence.delete(id: event.id)
        XCTAssertTrue(persistence.events.isEmpty)
        XCTAssertTrue(try await repository.fetchAll().isEmpty)
    }
}
