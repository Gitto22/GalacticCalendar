//
//  ResilientEventCatalogIntegrationTests.swift
//  GalacticCalendar
//
//  QA-03 — Event catalog never fails because of corrupt rows.
//

import XCTest
import SwiftData
@testable import GalacticCalendar

/// Integration coverage for resilient catalog load → ``EventPersistenceService/refresh()``.
@MainActor
final class ResilientEventCatalogIntegrationTests: XCTestCase {

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

    // MARK: - Empty catalog

    func testEmptyCatalogRefreshSucceeds() async throws {
        try await persistence.refresh()

        XCTAssertTrue(persistence.events.isEmpty)
        XCTAssertGreaterThan(persistence.eventsRevision, 0)
        XCTAssertNil(persistence.lastError)
    }

    // MARK: - Fully valid catalog

    func testFullyValidCatalogLoadsAllEvents() async throws {
        let a = Event(
            title: "Valid A",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            color: .green
        )
        let b = Event(
            title: "Valid B",
            date: Date(timeIntervalSince1970: 1_900_003_600),
            color: .orange
        )
        let c = Event(
            title: "Valid C",
            date: Date(timeIntervalSince1970: 1_900_007_200),
            color: .yellow
        )
        try await repository.create(a)
        try await repository.create(b)
        try await repository.create(c)

        try await persistence.refresh()

        XCTAssertEqual(persistence.events.count, 3)
        XCTAssertEqual(
            Set(persistence.events.map(\.title)),
            Set(["Valid A", "Valid B", "Valid C"])
        )
        XCTAssertNil(persistence.lastError)
    }

    // MARK: - One corrupt entity

    func testSingleCorruptEntityIsIsolatedAndCatalogUpdates() async throws {
        let healthy = Event(
            title: "Healthy Solo",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            color: .green
        )
        try await repository.create(healthy)

        let corruptID = UUID()
        try SwiftDataIntegrationHarness.insertCorruptEventEntity(
            into: container.mainContext,
            id: corruptID,
            title: "Corrupt Solo",
            date: Date(timeIntervalSince1970: 1_900_001_800)
        )

        try await persistence.refresh()

        XCTAssertEqual(persistence.events.count, 1)
        XCTAssertEqual(persistence.events.first?.id, healthy.id)
        XCTAssertFalse(persistence.events.contains(where: { $0.id == corruptID }))
        XCTAssertNil(persistence.lastError)
        XCTAssertGreaterThan(persistence.eventsRevision, 0)
    }

    // MARK: - Several corrupt entities

    func testMultipleCorruptEntitiesDoNotAbortCatalogLoad() async throws {
        let healthy = Event(
            title: "Survivor",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            color: .orange
        )
        try await repository.create(healthy)
        try SwiftDataIntegrationHarness.insertCorruptEventEntity(
            into: container.mainContext,
            title: "Corrupt A",
            date: Date(timeIntervalSince1970: 1_900_001_000)
        )
        try SwiftDataIntegrationHarness.insertCorruptEventEntity(
            into: container.mainContext,
            title: "Corrupt B",
            date: Date(timeIntervalSince1970: 1_900_002_000)
        )
        try SwiftDataIntegrationHarness.insertCorruptEventEntity(
            into: container.mainContext,
            title: "Corrupt C",
            date: Date(timeIntervalSince1970: 1_900_004_000)
        )

        try await persistence.refresh()

        XCTAssertEqual(persistence.events.count, 1)
        XCTAssertEqual(persistence.events.first?.title, "Survivor")
        XCTAssertNil(persistence.lastError)
    }

    // MARK: - Mixed valid + invalid

    func testMixedValidAndInvalidEntitiesLoadOnlyValid() async throws {
        let first = Event(
            title: "Alpha",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            color: .green
        )
        let second = Event(
            title: "Beta",
            date: Date(timeIntervalSince1970: 1_900_003_600),
            color: .yellow
        )
        try await repository.create(first)
        try await repository.create(second)

        let corruptID = UUID()
        try SwiftDataIntegrationHarness.insertCorruptEventEntity(
            into: container.mainContext,
            id: corruptID,
            title: "Corrupt Mid",
            date: Date(timeIntervalSince1970: 1_900_001_800)
        )

        let fetched = try await repository.fetchAll()
        XCTAssertEqual(fetched.count, 2)
        XCTAssertEqual(Set(fetched.map(\.title)), Set(["Alpha", "Beta"]))

        try await persistence.refresh()
        XCTAssertEqual(persistence.events.count, 2)
        XCTAssertEqual(Set(persistence.events.map(\.title)), Set(["Alpha", "Beta"]))
        XCTAssertFalse(persistence.events.contains(where: { $0.id == corruptID }))
        XCTAssertNil(persistence.lastError)
    }

    // MARK: - All corrupt → empty catalog, not failure

    func testAllCorruptCatalogRefreshYieldsEmptyWithoutFailing() async throws {
        try SwiftDataIntegrationHarness.insertCorruptEventEntity(
            into: container.mainContext,
            title: "Only Corrupt A"
        )
        try SwiftDataIntegrationHarness.insertCorruptEventEntity(
            into: container.mainContext,
            title: "Only Corrupt B",
            date: Date(timeIntervalSince1970: 1_900_002_000)
        )

        try await persistence.refresh()

        XCTAssertTrue(persistence.events.isEmpty)
        XCTAssertNil(persistence.lastError)
        XCTAssertGreaterThan(persistence.eventsRevision, 0)
    }
}
