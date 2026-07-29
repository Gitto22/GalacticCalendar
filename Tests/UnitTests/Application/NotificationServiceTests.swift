//
//  NotificationServiceTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for ``NotificationService`` using a mock repository.
@MainActor
final class NotificationServiceTests: XCTestCase {

    // MARK: - Fixtures

    private var fixedNow: Date!
    private var repository: MockNotificationRepository!
    private var service: NotificationService!

    override func setUp() async throws {
        try await super.setUp()
        fixedNow = Date(timeIntervalSince1970: 1_700_000_000)
        repository = MockNotificationRepository()
        service = NotificationService(
            repository: repository,
            now: { [fixedNow] in fixedNow! }
        )
    }

    // MARK: - Authorization

    func testRequestAuthorizationWhenNotDeterminedPromptsAndReturnsGrant() async {
        repository.status = .notDetermined
        repository.authorizationGrant = true

        let allowed = await service.requestAuthorizationIfNeeded()

        XCTAssertTrue(allowed)
        XCTAssertEqual(repository.requestAuthorizationCallCount, 1)
    }

    func testRequestAuthorizationWhenAuthorizedDoesNotPrompt() async {
        repository.status = .authorized

        let allowed = await service.requestAuthorizationIfNeeded()

        XCTAssertTrue(allowed)
        XCTAssertEqual(repository.requestAuthorizationCallCount, 0)
    }

    func testRequestAuthorizationWhenDeniedReturnsFalse() async {
        repository.status = .denied

        let allowed = await service.requestAuthorizationIfNeeded()

        XCTAssertFalse(allowed)
        XCTAssertEqual(repository.requestAuthorizationCallCount, 0)
    }

    // MARK: - Synchronize

    func testSynchronizeSchedulesFutureReminder() async throws {
        repository.status = .authorized
        let eventDate = fixedNow.addingTimeInterval(3_600)
        let reminder = eventDate.addingTimeInterval(-900)
        let event = Event(title: "Standup", date: eventDate, reminder: reminder, color: .green)

        try await service.synchronizeReminder(for: event)

        XCTAssertEqual(repository.cancelledIdentifiers, [event.reminderNotificationIdentifier])
        XCTAssertEqual(repository.scheduledRequests.count, 1)
        XCTAssertEqual(repository.scheduledRequests.first?.identifier, event.reminderNotificationIdentifier)
        XCTAssertEqual(repository.scheduledRequests.first?.title, "Standup")
        XCTAssertEqual(repository.scheduledRequests.first?.fireDate, reminder)
    }

    func testSynchronizeCancelsWhenReminderIsNil() async throws {
        repository.status = .authorized
        let event = Event(title: "No reminder", date: fixedNow.addingTimeInterval(3_600), reminder: nil, color: .green)

        try await service.synchronizeReminder(for: event)

        XCTAssertEqual(repository.cancelledIdentifiers, [event.reminderNotificationIdentifier])
        XCTAssertTrue(repository.scheduledRequests.isEmpty)
    }

    func testSynchronizeCancelsWhenReminderIsInThePast() async throws {
        repository.status = .authorized
        let eventDate = fixedNow.addingTimeInterval(60)
        let pastReminder = fixedNow.addingTimeInterval(-120)
        let event = Event(title: "Past", date: eventDate, reminder: pastReminder, color: .green)

        try await service.synchronizeReminder(for: event)

        XCTAssertEqual(repository.cancelledIdentifiers, [event.reminderNotificationIdentifier])
        XCTAssertTrue(repository.scheduledRequests.isEmpty)
    }

    func testSynchronizeThrowsWhenUnauthorized() async {
        repository.status = .denied
        let eventDate = fixedNow.addingTimeInterval(3_600)
        let reminder = eventDate.addingTimeInterval(-300)
        let event = Event(title: "Denied", date: eventDate, reminder: reminder, color: .green)

        do {
            try await service.synchronizeReminder(for: event)
            XCTFail("Expected unauthorized error")
        } catch NotificationRepositoryError.unauthorized {
            XCTAssertTrue(repository.scheduledRequests.isEmpty)
            XCTAssertEqual(repository.cancelledIdentifiers, [event.reminderNotificationIdentifier])
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSynchronizeReschedulesAfterDateChange() async throws {
        repository.status = .authorized
        let eventID = UUID()
        let firstDate = fixedNow.addingTimeInterval(3_600)
        let firstReminder = firstDate.addingTimeInterval(-900)
        let first = Event(
            id: eventID,
            title: "Move me",
            date: firstDate,
            reminder: firstReminder,
            color: .green
        )

        try await service.synchronizeReminder(for: first)

        let secondDate = fixedNow.addingTimeInterval(7_200)
        let secondReminder = secondDate.addingTimeInterval(-1_800)
        let second = Event(
            id: eventID,
            title: "Move me",
            date: secondDate,
            reminder: secondReminder,
            color: .green
        )

        try await service.synchronizeReminder(for: second)

        XCTAssertEqual(repository.scheduledRequests.count, 2)
        XCTAssertEqual(repository.scheduledRequests.last?.fireDate, secondReminder)
        XCTAssertEqual(
            repository.cancelledIdentifiers.filter { $0 == first.reminderNotificationIdentifier }.count,
            2
        )
    }

    // MARK: - Cancel

    func testCancelReminderUsesStableIdentifier() async throws {
        let eventID = UUID()

        try await service.cancelReminder(for: eventID)

        XCTAssertEqual(
            repository.cancelledIdentifiers,
            [Event.reminderNotificationIdentifier(for: eventID)]
        )
    }

    // MARK: - Offsets

    func testReminderOffsetsMatchSupportedOptions() {
        let eventDate = Date(timeIntervalSince1970: 2_000_000_000)

        XCTAssertNil(EventReminderOption.none.reminderDate(relativeTo: eventDate))
        XCTAssertEqual(
            EventReminderOption.atEventTime.reminderDate(relativeTo: eventDate),
            eventDate
        )
        XCTAssertEqual(
            EventReminderOption.fiveMinutes.reminderDate(relativeTo: eventDate),
            eventDate.addingTimeInterval(-5 * 60)
        )
        XCTAssertEqual(
            EventReminderOption.fifteenMinutes.reminderDate(relativeTo: eventDate),
            eventDate.addingTimeInterval(-15 * 60)
        )
        XCTAssertEqual(
            EventReminderOption.thirtyMinutes.reminderDate(relativeTo: eventDate),
            eventDate.addingTimeInterval(-30 * 60)
        )
        XCTAssertEqual(
            EventReminderOption.oneHour.reminderDate(relativeTo: eventDate),
            eventDate.addingTimeInterval(-60 * 60)
        )
        XCTAssertEqual(
            EventReminderOption.oneDay.reminderDate(relativeTo: eventDate),
            eventDate.addingTimeInterval(-1_440 * 60)
        )
    }
}

// MARK: - Mock Repository

@MainActor
private final class MockNotificationRepository: NotificationRepositoryProtocol {

    var status: NotificationAuthorizationStatus = .authorized
    var authorizationGrant: Bool = true
    var requestAuthorizationCallCount: Int = 0
    var scheduledRequests: [NotificationScheduleRequest] = []
    var cancelledIdentifiers: [String] = []

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        status
    }

    func requestAuthorization() async throws -> Bool {
        requestAuthorizationCallCount += 1
        status = authorizationGrant ? .authorized : .denied
        return authorizationGrant
    }

    func schedule(_ request: NotificationScheduleRequest) async throws {
        scheduledRequests.append(request)
    }

    func cancel(identifiers: [String]) async throws {
        cancelledIdentifiers.append(contentsOf: identifiers)
    }
}
