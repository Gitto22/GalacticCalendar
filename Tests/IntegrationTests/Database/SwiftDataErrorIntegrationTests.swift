//
//  SwiftDataErrorIntegrationTests.swift
//  GalacticCalendar
//
//  QA-02 — Case 6: failed open / write / read responses.
//

import XCTest
import SwiftData
@testable import GalacticCalendar

@MainActor
final class SwiftDataErrorIntegrationTests: XCTestCase {

    // MARK: - Failed open (unavailable store path)

    func testUnavailableStoreBlocksWritesAndExposesStoreUnavailable() async throws {
        let persistence = EventPersistenceService(
            repository: UnavailableEventRepository(),
            storageAvailability: .unavailable
        )

        XCTAssertFalse(persistence.isWritable)
        XCTAssertEqual(persistence.lastError, .storeUnavailable)

        let event = Event(
            title: "Should Fail",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            color: .red
        )

        do {
            try await persistence.create(event)
            XCTFail("Expected storeUnavailable on create")
        } catch let error as EventPersistenceError {
            XCTAssertEqual(error, .storeUnavailable)
        }

        try await persistence.refresh()
        XCTAssertTrue(persistence.events.isEmpty)
    }

    // MARK: - Failed write

    func testUnavailableRepositoryWriteFails() async {
        let repository = UnavailableEventRepository()
        let event = Event(
            title: "Write Fail",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            color: .red
        )

        do {
            try await repository.create(event)
            XCTFail("Expected saveFailed")
        } catch let error as EventRepositoryError {
            XCTAssertEqual(error, .saveFailed)
        }

        do {
            try await repository.update(event)
            XCTFail("Expected saveFailed on update")
        } catch let error as EventRepositoryError {
            XCTAssertEqual(error, .saveFailed)
        }

        do {
            try await repository.delete(id: event.id)
            XCTFail("Expected saveFailed on delete")
        } catch let error as EventRepositoryError {
            XCTAssertEqual(error, .saveFailed)
        }
    }

    func testUnavailableTemplateRepositoryWriteFails() async {
        let repository = UnavailableEventTemplateRepository()
        let template = EventTemplate(name: "X", title: "Y", color: .green)

        do {
            try await repository.create(template)
            XCTFail("Expected saveFailed")
        } catch let error as EventTemplateRepositoryError {
            XCTAssertEqual(error, .saveFailed)
        }
    }

    // MARK: - Failed read (corrupt single row)

    func testCorruptSingleRowReadFailsWhileCatalogLoadContinues() async throws {
        let container = try SwiftDataIntegrationHarness.makeInMemoryContainer()
        let repository = EventRepository(modelContext: container.mainContext)

        let healthy = Event(
            title: "Healthy",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            color: .green
        )
        try await repository.create(healthy)

        let corruptID = UUID()
        try SwiftDataIntegrationHarness.insertCorruptEventEntity(
            into: container.mainContext,
            id: corruptID
        )

        do {
            _ = try await repository.fetch(by: corruptID)
            XCTFail("Expected corruptData for single-row read")
        } catch let error as EventRepositoryError {
            XCTAssertEqual(error, .corruptData)
        }

        let all = try await repository.fetchAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, healthy.id)

        let persistence = EventPersistenceService(repository: repository)
        try await persistence.refresh()
        XCTAssertEqual(persistence.events.count, 1)
        XCTAssertNil(persistence.lastError)
    }
}
