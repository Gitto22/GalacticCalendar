//
//  SwiftDataStoreOpenIntegrationTests.swift
//  GalacticCalendar
//
//  QA-02 — Case 1: store creation / initialization.
//

import XCTest
import SwiftData
@testable import GalacticCalendar

@MainActor
final class SwiftDataStoreOpenIntegrationTests: XCTestCase {

    func testTemporaryInMemoryStoreInitializes() throws {
        let container = try SwiftDataIntegrationHarness.makeInMemoryContainer()
        XCTAssertNotNil(container.mainContext)

        let events = try container.mainContext.fetch(FetchDescriptor<EventEntity>())
        let templates = try container.mainContext.fetch(FetchDescriptor<EventTemplateEntity>())
        XCTAssertTrue(events.isEmpty)
        XCTAssertTrue(templates.isEmpty)
    }

    func testTemporaryOnDiskStoreInitializes() throws {
        let (container, directory) = try SwiftDataIntegrationHarness.makeOnDiskContainer()
        defer { SwiftDataIntegrationHarness.removeStoreDirectory(directory) }

        XCTAssertNotNil(container.mainContext)
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))

        let events = try container.mainContext.fetch(FetchDescriptor<EventEntity>())
        XCTAssertTrue(events.isEmpty)
    }

    func testProductionFactoryInMemoryOpens() throws {
        let container = try ModelContainerFactory.make(inMemory: true, enableCloudKit: false)
        XCTAssertNotNil(container.mainContext)
    }
}
