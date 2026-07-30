//
//  SwiftDataTemplateIntegrationTests.swift
//  GalacticCalendar
//
//  QA-02 — Case 4: templates CRUD + create event from template.
//

import XCTest
import SwiftData
@testable import GalacticCalendar

@MainActor
final class SwiftDataTemplateIntegrationTests: XCTestCase {

    private var container: ModelContainer!
    private var templateRepository: EventTemplateRepository!
    private var eventRepository: EventRepository!

    override func setUp() async throws {
        try await super.setUp()
        container = try SwiftDataIntegrationHarness.makeInMemoryContainer()
        templateRepository = EventTemplateRepository(modelContext: container.mainContext)
        eventRepository = EventRepository(modelContext: container.mainContext)
    }

    override func tearDown() async throws {
        templateRepository = nil
        eventRepository = nil
        container = nil
        try await super.tearDown()
    }

    func testTemplateCreateEditDelete() async throws {
        let template = EventTemplate(
            name: "Standup",
            title: "Daily standup",
            color: .yellow
        )

        try await templateRepository.create(template)
        var all = try await templateRepository.fetchAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.name, "Standup")

        let renamed = EventTemplate(
            id: template.id,
            name: "Standup Renamed",
            title: template.title,
            description: template.description,
            isAllDay: template.isAllDay,
            durationSeconds: template.durationSeconds,
            repeatRule: template.repeatRule,
            category: template.category,
            tags: template.tags,
            priority: template.priority,
            status: template.status,
            color: template.color,
            timeZoneIdentifier: template.timeZoneIdentifier,
            createdAt: template.createdAt,
            updatedAt: Date()
        )
        try await templateRepository.update(renamed)
        all = try await templateRepository.fetchAll()
        XCTAssertEqual(all.first?.name, "Standup Renamed")

        try await templateRepository.delete(id: template.id)
        XCTAssertTrue(try await templateRepository.fetchAll().isEmpty)
    }

    func testCreateEventFromTemplatePersistsExpectedFields() async throws {
        let template = EventTemplate(
            name: "Focus Block",
            title: "Deep Work",
            description: "No meetings",
            isAllDay: false,
            durationSeconds: 7_200,
            repeatRule: .weekly,
            category: .work,
            priority: .high,
            color: .orange,
            timeZoneIdentifier: "UTC"
        )
        try await templateRepository.create(template)

        let stored = try await templateRepository.fetch(by: template.id)
        XCTAssertNotNil(stored)

        let event = SwiftDataIntegrationHarness.makeEvent(from: template)
        try await eventRepository.create(event)

        let fetched = try await eventRepository.fetch(by: event.id)
        XCTAssertEqual(fetched?.title, "Deep Work")
        XCTAssertEqual(fetched?.description, "No meetings")
        XCTAssertEqual(fetched?.color, .orange)
        XCTAssertEqual(fetched?.priority, .high)
        XCTAssertEqual(fetched?.repeatRule.frequency, .weekly)
        XCTAssertEqual(fetched?.category, .work)
        XCTAssertNotNil(fetched?.endDate)
        XCTAssertEqual(
            fetched?.endDate?.timeIntervalSince(fetched?.date ?? .distantPast),
            7_200,
            accuracy: 1
        )
    }
}
