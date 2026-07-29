//
//  EventEditorViewModelTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for ``EventEditorViewModel``.
@MainActor
final class EventEditorViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makePersistence(seed: [Event] = []) -> EventPersistenceService {
        EventPersistenceService(repository: InMemoryEventRepository(seed: seed))
    }

    private func makeViewModel(
        seed: [Event] = [],
        initialDate: Date = Date(timeIntervalSince1970: 1_900_000_000),
        event: Event? = nil
    ) -> EventEditorViewModel {
        EventEditorViewModel(
            persistenceService: makePersistence(seed: seed),
            initialDate: initialDate,
            event: event
        )
    }

    // MARK: - Modes

    func testInitWithoutEventIsCreateMode() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.mode, .create)
        XCTAssertFalse(viewModel.isEditing)
        XCTAssertEqual(viewModel.reminderOption, .fifteenMinutes)
    }

    func testInitWithEventIsEditMode() {
        let event = Event(
            title: "Existing",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            color: .red
        )
        let viewModel = makeViewModel(seed: [event], event: event)

        XCTAssertEqual(viewModel.mode, .edit)
        XCTAssertTrue(viewModel.isEditing)
        XCTAssertEqual(viewModel.title, "Existing")
        XCTAssertEqual(viewModel.editingEventID, event.id)
        XCTAssertEqual(viewModel.color, .red)
    }

    // MARK: - Validation

    func testValidateEmptyTitleFails() {
        let viewModel = makeViewModel()
        viewModel.title = "   "
        XCTAssertFalse(viewModel.validate())
        XCTAssertTrue(viewModel.hasValidationIssues)
        XCTAssertTrue(viewModel.validationIssues.contains(.titleRequired))
    }

    func testCreateDoesNotPersistWhenInvalid() async {
        let persistence = makePersistence()
        let viewModel = EventEditorViewModel(
            persistenceService: persistence,
            initialDate: Date(timeIntervalSince1970: 1_900_000_000)
        )
        viewModel.title = ""

        await viewModel.createEvent()

        XCTAssertFalse(viewModel.didCompleteMutation)
        XCTAssertTrue(persistence.events.isEmpty)
    }

    // MARK: - Mutations

    func testCreatePersistsValidEvent() async {
        let persistence = makePersistence()
        let viewModel = EventEditorViewModel(
            persistenceService: persistence,
            initialDate: Date(timeIntervalSince1970: 1_900_000_000)
        )
        viewModel.title = "Launch"
        viewModel.reminderOption = .none

        await viewModel.createEvent()

        XCTAssertTrue(viewModel.didCompleteMutation)
        XCTAssertNil(viewModel.lastError)
        XCTAssertEqual(persistence.events.map(\.title), ["Launch"])
    }

    func testUpdatePersistsChanges() async throws {
        let event = Event(
            title: "Old",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            reminder: nil,
            color: .green
        )
        let persistence = makePersistence(seed: [event])
        try await persistence.bootstrap()

        let viewModel = EventEditorViewModel(
            persistenceService: persistence,
            event: event
        )
        viewModel.title = "New"
        viewModel.reminderOption = .none

        await viewModel.updateEvent()

        XCTAssertTrue(viewModel.didCompleteMutation)
        XCTAssertEqual(persistence.event(id: event.id)?.title, "New")
    }

    func testDeleteRemovesEvent() async throws {
        let event = Event(
            title: "Gone",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            color: .green
        )
        let persistence = makePersistence(seed: [event])
        try await persistence.bootstrap()

        let viewModel = EventEditorViewModel(
            persistenceService: persistence,
            event: event
        )
        await viewModel.deleteEvent()

        XCTAssertTrue(viewModel.didCompleteMutation)
        XCTAssertTrue(persistence.events.isEmpty)
    }

    func testDateChangeRecomputesReminder() {
        let viewModel = makeViewModel()
        viewModel.reminderOption = .thirtyMinutes
        let newDate = Date(timeIntervalSince1970: 2_000_000_000)
        viewModel.date = newDate

        XCTAssertEqual(
            viewModel.reminder,
            EventReminderOption.thirtyMinutes.reminderDate(relativeTo: newDate)
        )
    }

    func testDateChangePreservesEndDuration() {
        let viewModel = makeViewModel()
        let start = Date(timeIntervalSince1970: 2_000_000_000)
        viewModel.date = start
        viewModel.endDate = start.addingTimeInterval(7_200)

        let shifted = start.addingTimeInterval(86_400)
        viewModel.date = shifted

        XCTAssertEqual(viewModel.endDate.timeIntervalSince(viewModel.date), 7_200, accuracy: 0.5)
    }

    func testPrepareForEditingLoadsScheduleFields() {
        let start = Date(timeIntervalSince1970: 1_900_000_000)
        let event = Event(
            title: "Existing",
            date: start,
            endDate: start.addingTimeInterval(1_800),
            timeZoneIdentifier: "UTC",
            color: .red
        )
        let viewModel = makeViewModel(seed: [event], event: event)

        XCTAssertEqual(viewModel.endDate, start.addingTimeInterval(1_800))
        XCTAssertEqual(viewModel.timeZoneIdentifier, "UTC")
    }

    func testSaveEventRoutesByMode() async {
        let persistence = makePersistence()
        let viewModel = EventEditorViewModel(
            persistenceService: persistence,
            initialDate: Date(timeIntervalSince1970: 1_900_000_000)
        )
        viewModel.title = "Via save"
        viewModel.reminderOption = .none

        await viewModel.saveEvent()

        XCTAssertTrue(viewModel.didCompleteMutation)
        XCTAssertEqual(persistence.events.count, 1)
    }

    func testCreateSurfacesReminderUnauthorized() async {
        let notifications = MockNotificationRepository()
        notifications.status = .denied
        let persistence = EventPersistenceService(
            repository: InMemoryEventRepository(),
            notificationService: NotificationService(
                repository: notifications,
                now: { Date(timeIntervalSince1970: 1_000_000_000) }
            )
        )
        let viewModel = EventEditorViewModel(
            persistenceService: persistence,
            initialDate: Date(timeIntervalSince1970: 1_900_000_000)
        )
        viewModel.title = "Needs reminder"
        viewModel.reminderOption = .fifteenMinutes

        await viewModel.createEvent()

        XCTAssertFalse(viewModel.didCompleteMutation)
        XCTAssertEqual(viewModel.lastError, .reminderUnauthorized)
        XCTAssertEqual(persistence.events.count, 1)
    }
}

// MARK: - Mock Notifications

@MainActor
private final class MockNotificationRepository: NotificationRepositoryProtocol {

    var status: NotificationAuthorizationStatus = .authorized
    var authorizationGrant: Bool = true

    func authorizationStatus() async -> NotificationAuthorizationStatus { status }

    func requestAuthorization() async throws -> Bool {
        status = authorizationGrant ? .authorized : .denied
        return authorizationGrant
    }

    func schedule(_ request: NotificationScheduleRequest) async throws {}

    func cancel(identifiers: [String]) async throws {}
}
