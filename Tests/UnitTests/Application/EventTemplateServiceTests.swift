//
//  EventTemplateServiceTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for ``EventTemplate`` / ``EventTemplateService`` (Sprint 6.5).
@MainActor
final class EventTemplateServiceTests: XCTestCase {

    // MARK: - Helpers

    private func makeService(seed: [EventTemplate] = []) -> EventTemplateService {
        EventTemplateService(repository: InMemoryEventTemplateRepository(seed: seed))
    }

    private func sampleTemplate(
        name: String = "Standup",
        title: String = "Daily standup",
        description: String = "Notes for standup",
        isAllDay: Bool = false,
        durationSeconds: TimeInterval = 1_800,
        priority: EventPriority = .high,
        color: EventColor = .green,
        tags: [EventTag] = [.preset(.work)],
        repeatRule: RepeatRule = .daily
    ) -> EventTemplate {
        EventTemplate(
            name: name,
            title: title,
            description: description,
            isAllDay: isAllDay,
            durationSeconds: durationSeconds,
            repeatRule: repeatRule,
            category: .work,
            tags: tags,
            priority: priority,
            status: .pending,
            color: color
        )
    }

    // MARK: - Creation

    func testCreatePersistsTemplate() async throws {
        let service = makeService()
        let template = sampleTemplate()

        try await service.create(template)

        XCTAssertEqual(service.templates.count, 1)
        XCTAssertEqual(service.templates.first?.title, "Daily standup")
        XCTAssertEqual(service.templates.first?.priority, .high)
        XCTAssertEqual(service.templates.first?.color, .green)
        XCTAssertEqual(service.templates.first?.tags, [.preset(.work)])
        XCTAssertEqual(service.templates.first?.repeatRule.frequency, .daily)
        XCTAssertEqual(service.templatesRevision, 1)
    }

    func testSaveEventAsTemplateStripsScheduleAndReminders() async throws {
        let start = Date(timeIntervalSince1970: 1_900_000_000)
        let event = Event(
            title: "Launch",
            description: "Ship notes",
            date: start,
            endDate: start.addingTimeInterval(7_200),
            isAllDay: false,
            reminder: start.addingTimeInterval(-900),
            repeatRule: .weekly,
            category: .work,
            tags: [.preset(.work), .preset(.studies)],
            priority: .urgent,
            status: .pending,
            color: .red
        )
        let service = makeService()

        let template = try await service.saveEventAsTemplate(event, name: "Launch blueprint")

        XCTAssertEqual(template.name, "Launch blueprint")
        XCTAssertEqual(template.title, "Launch")
        XCTAssertEqual(template.description, "Ship notes")
        XCTAssertEqual(template.durationSeconds, 7_200)
        XCTAssertEqual(template.priority, .urgent)
        XCTAssertEqual(template.color, .red)
        XCTAssertEqual(template.tags.count, 2)
        XCTAssertEqual(template.repeatRule.frequency, .weekly)
        XCTAssertEqual(service.templates.count, 1)
    }

    // MARK: - Edit

    func testUpdatePersistsEdits() async throws {
        let original = sampleTemplate()
        let service = makeService(seed: [original])
        try await service.refresh()

        var edited = original
        edited.name = "Standup v2"
        edited.title = "Team standup"
        edited.priority = .urgent
        edited.color = .orange
        edited.description = "Updated notes"

        try await service.update(edited)

        XCTAssertEqual(service.templates.count, 1)
        XCTAssertEqual(service.templates.first?.name, "Standup v2")
        XCTAssertEqual(service.templates.first?.title, "Team standup")
        XCTAssertEqual(service.templates.first?.priority, .urgent)
        XCTAssertEqual(service.templates.first?.color, .orange)
        XCTAssertEqual(service.templates.first?.description, "Updated notes")
    }

    // MARK: - Delete

    func testDeleteRemovesTemplate() async throws {
        let template = sampleTemplate()
        let service = makeService(seed: [template])
        try await service.refresh()
        XCTAssertEqual(service.templates.count, 1)

        try await service.delete(id: template.id)

        XCTAssertTrue(service.templates.isEmpty)
    }

    // MARK: - Duplicate

    func testDuplicateCreatesIndependentCopy() async throws {
        let template = sampleTemplate(name: "Review")
        let service = makeService(seed: [template])
        try await service.refresh()

        let copy = try await service.duplicate(template)

        XCTAssertEqual(service.templates.count, 2)
        XCTAssertNotEqual(copy.id, template.id)
        XCTAssertTrue(copy.name.contains("Review"))
        XCTAssertEqual(copy.title, template.title)
        XCTAssertEqual(copy.durationSeconds, template.durationSeconds)
        XCTAssertEqual(copy.priority, template.priority)
    }

    // MARK: - Create event from template

    func testScheduleBoundsDoNotCopyAbsoluteDates() {
        let template = sampleTemplate(isAllDay: false, durationSeconds: 3_600)
        let anchor = Date(timeIntervalSince1970: 2_000_000_000)

        let bounds = template.scheduleBounds(on: anchor)

        XCTAssertEqual(bounds.date, anchor)
        XCTAssertEqual(bounds.endDate, anchor.addingTimeInterval(3_600))
    }

    func testEditorApplyTemplateFillsContentWithoutReminderFireDate() async throws {
        let template = sampleTemplate(
            title: "Focus block",
            description: "Deep work notes",
            durationSeconds: 5_400,
            priority: .normal,
            color: .green,
            tags: [.preset(.personal)],
            repeatRule: .weekly
        )
        let persistence = EventPersistenceService(repository: InMemoryEventRepository())
        let templateService = makeService(seed: [template])
        try await templateService.refresh()

        let anchor = Date(timeIntervalSince1970: 2_100_000_000)
        let editor = EventEditorViewModel(
            persistenceService: persistence,
            templateService: templateService,
            initialDate: anchor
        )
        editor.prepareForCreation(from: template, on: anchor)

        XCTAssertEqual(editor.mode, .create)
        XCTAssertEqual(editor.title, "Focus block")
        XCTAssertEqual(editor.description, "Deep work notes")
        XCTAssertEqual(editor.priority, .normal)
        XCTAssertEqual(editor.color, .green)
        XCTAssertEqual(editor.tags, [.preset(.personal)])
        XCTAssertEqual(editor.repeatRule.frequency, .weekly)
        XCTAssertEqual(editor.date, anchor)
        XCTAssertEqual(editor.endDate, anchor.addingTimeInterval(5_400))
        XCTAssertEqual(editor.reminderOption, .fifteenMinutes)
        XCTAssertNotEqual(editor.reminder, Date(timeIntervalSince1970: 1_900_000_000))

        editor.title = "Focus block"
        editor.reminderOption = .none
        await editor.createEvent()

        XCTAssertTrue(editor.didCompleteMutation)
        XCTAssertEqual(persistence.events.count, 1)
        let created = try XCTUnwrap(persistence.events.first)
        XCTAssertEqual(created.title, "Focus block")
        XCTAssertEqual(created.description, "Deep work notes")
        XCTAssertEqual(created.priority, .normal)
        XCTAssertEqual(created.color, .green)
        XCTAssertEqual(created.tags, [.preset(.personal)])
        XCTAssertEqual(created.repeatRule.frequency, .weekly)
        XCTAssertNil(created.reminder)
        XCTAssertEqual(created.date, anchor)
    }

    func testSaveCurrentAsTemplateFromEditor() async throws {
        let persistence = EventPersistenceService(repository: InMemoryEventRepository())
        let templateService = makeService()
        let editor = EventEditorViewModel(
            persistenceService: persistence,
            templateService: templateService,
            initialDate: Date(timeIntervalSince1970: 2_200_000_000)
        )
        editor.prepareForCreation(on: Date(timeIntervalSince1970: 2_200_000_000))
        editor.title = "Workshop"
        editor.description = "Agenda notes"
        editor.priority = .high
        editor.color = .yellow
        editor.tags = [.preset(.studies)]
        editor.reminderOption = .oneHour

        let saved = await editor.saveCurrentAsTemplate(name: "Workshop kit")

        XCTAssertNotNil(saved)
        XCTAssertTrue(editor.didSaveAsTemplate)
        XCTAssertEqual(templateService.templates.count, 1)
        XCTAssertEqual(templateService.templates.first?.name, "Workshop kit")
        XCTAssertEqual(templateService.templates.first?.title, "Workshop")
        XCTAssertEqual(templateService.templates.first?.description, "Agenda notes")
    }
}
