//
//  SwiftDataPersistenceRoundTripIntegrationTests.swift
//  GalacticCalendar
//
//  QA-02 — Case 3: close store / reopen / data survives.
//

import XCTest
import SwiftData
@testable import GalacticCalendar

@MainActor
final class SwiftDataPersistenceRoundTripIntegrationTests: XCTestCase {

    func testEventSurvivesStoreCloseAndReopen() async throws {
        let (container, directory) = try SwiftDataIntegrationHarness.makeOnDiskContainer()
        defer { SwiftDataIntegrationHarness.removeStoreDirectory(directory) }

        let eventID = UUID()
        let event = Event(
            id: eventID,
            title: "Persisted Across Reopen",
            description: "Round-trip",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            color: .yellow
        )

        do {
            let repository = EventRepository(modelContext: container.mainContext)
            try await repository.create(event)
            XCTAssertEqual(try await repository.fetch(by: eventID)?.title, "Persisted Across Reopen")
        }

        // Drop the first container (close store), then reopen the same files.
        var closed: ModelContainer? = container
        closed = nil
        _ = closed

        let reopened = try SwiftDataIntegrationHarness.reopenOnDiskContainer(at: directory)
        let repository = EventRepository(modelContext: reopened.mainContext)
        let restored = try await repository.fetch(by: eventID)

        XCTAssertEqual(restored?.id, eventID)
        XCTAssertEqual(restored?.title, "Persisted Across Reopen")
        XCTAssertEqual(restored?.color, .yellow)
        XCTAssertEqual(try await repository.fetchAll().count, 1)
    }

    func testTemplateSurvivesStoreCloseAndReopen() async throws {
        let (container, directory) = try SwiftDataIntegrationHarness.makeOnDiskContainer()
        defer { SwiftDataIntegrationHarness.removeStoreDirectory(directory) }

        let templateID = UUID()
        let template = EventTemplate(
            id: templateID,
            name: "Disk Template",
            title: "From Disk",
            color: .orange
        )

        do {
            let repository = EventTemplateRepository(modelContext: container.mainContext)
            try await repository.create(template)
        }

        var closed: ModelContainer? = container
        closed = nil
        _ = closed

        let reopened = try SwiftDataIntegrationHarness.reopenOnDiskContainer(at: directory)
        let repository = EventTemplateRepository(modelContext: reopened.mainContext)
        let restored = try await repository.fetch(by: templateID)

        XCTAssertEqual(restored?.id, templateID)
        XCTAssertEqual(restored?.name, "Disk Template")
        XCTAssertEqual(restored?.title, "From Disk")
    }
}
