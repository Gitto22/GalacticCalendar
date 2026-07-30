//
//  SwiftDataEventCRUDIntegrationTests.swift
//  GalacticCalendar
//
//  QA-02 — Case 2: full event CRUD against SwiftData.
//

import XCTest
import SwiftData
@testable import GalacticCalendar

@MainActor
final class SwiftDataEventCRUDIntegrationTests: XCTestCase {

    private var container: ModelContainer!
    private var repository: EventRepository!

    override func setUp() async throws {
        try await super.setUp()
        container = try SwiftDataIntegrationHarness.makeInMemoryContainer()
        repository = EventRepository(modelContext: container.mainContext)
    }

    override func tearDown() async throws {
        repository = nil
        container = nil
        try await super.tearDown()
    }

    func testCreateReadUpdateDeleteEvent() async throws {
        let id = UUID()
        let created = Event(
            id: id,
            title: "Integration Create",
            description: "Body",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            color: .green
        )

        try await repository.create(created)

        let fetched = try await repository.fetch(by: id)
        XCTAssertEqual(fetched?.title, "Integration Create")
        XCTAssertEqual(fetched?.color, .green)
        XCTAssertEqual(try await repository.fetchAll().count, 1)

        let updated = Event(
            id: id,
            title: "Integration Update",
            description: "Body",
            date: Date(timeIntervalSince1970: 1_900_003_600),
            color: .orange,
            createdAt: created.createdAt,
            updatedAt: Date(timeIntervalSince1970: 1_900_010_000)
        )
        try await repository.update(updated)

        let afterUpdate = try await repository.fetch(by: id)
        XCTAssertEqual(afterUpdate?.title, "Integration Update")
        XCTAssertEqual(afterUpdate?.color, .orange)

        try await repository.delete(id: id)
        XCTAssertNil(try await repository.fetch(by: id))
        XCTAssertTrue(try await repository.fetchAll().isEmpty)
    }
}
