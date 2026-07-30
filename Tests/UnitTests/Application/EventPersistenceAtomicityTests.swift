//
//  EventPersistenceAtomicityTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Verifies persist → reminders → catalog refresh atomicity and rollback.
@MainActor
final class EventPersistenceAtomicityTests: XCTestCase {

    // MARK: - Fixtures

    private let fixedNow = Date(timeIntervalSince1970: 1_000_000_000)
    private let eventStart = Date(timeIntervalSince1970: 1_900_000_000)

    private func makeService(
        seed: [Event] = [],
        notifications: FailingNotificationRepository
    ) -> EventPersistenceService {
        EventPersistenceService(
            repository: InMemoryEventRepository(seed: seed),
            notificationService: NotificationService(
                repository: notifications,
                now: { [fixedNow] in fixedNow }
            )
        )
    }

    private func futureEvent(
        title: String = "Atomic",
        reminderOffset: TimeInterval = -900
    ) -> Event {
        Event(
            title: title,
            date: eventStart,
            reminder: eventStart.addingTimeInterval(reminderOffset),
            color: .green
        )
    }

    func testCreateDoesNotWriteWhenValidationFails() async {
        let notifications = FailingNotificationRepository()
        let service = makeService(notifications: notifications)
        let event = Event(title: "   ", date: eventStart, color: .green)

        do {
            try await service.create(event)
            XCTFail("Expected validationFailed")
        } catch EventPersistenceError.validationFailed {
            XCTAssertTrue(service.events.isEmpty)
            XCTAssertEqual(notifications.scheduledCount, 0)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Create

    func testCreateRollsBackWhenReminderUnauthorized() async {
        let notifications = FailingNotificationRepository()
        notifications.status = .denied
        let service = makeService(notifications: notifications)
        let event = futureEvent()

        do {
            try await service.create(event)
            XCTFail("Expected reminderUnauthorized")
        } catch EventPersistenceError.reminderUnauthorized {
            XCTAssertTrue(service.events.isEmpty)
            XCTAssertNil(service.event(id: event.id))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreateRollsBackWhenScheduleFails() async {
        let notifications = FailingNotificationRepository()
        notifications.status = .authorized
        notifications.scheduleError = NotificationRepositoryError.schedulingFailed
        let service = makeService(notifications: notifications)
        let event = futureEvent()

        do {
            try await service.create(event)
            XCTFail("Expected reminderSchedulingFailed")
        } catch EventPersistenceError.reminderSchedulingFailed {
            XCTAssertTrue(service.events.isEmpty)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreateSucceedsAndPublishesCatalog() async throws {
        let notifications = FailingNotificationRepository()
        notifications.status = .authorized
        let service = makeService(notifications: notifications)
        let event = futureEvent()

        try await service.create(event)

        XCTAssertEqual(service.events.map(\.id), [event.id])
        XCTAssertEqual(notifications.scheduledCount, 1)
        XCTAssertNil(service.lastError)
    }

    // MARK: - Update

    func testUpdateRestoresPreviousWhenReminderFails() async throws {
        let original = futureEvent(title: "Original")
        let notifications = FailingNotificationRepository()
        notifications.status = .authorized
        let service = makeService(seed: [original], notifications: notifications)
        try await service.refresh()

        notifications.scheduleError = NotificationRepositoryError.schedulingFailed
        let updated = Event(
            id: original.id,
            title: "Changed",
            description: original.description,
            date: original.date,
            endDate: original.endDate,
            timeZoneIdentifier: original.timeZoneIdentifier,
            reminder: original.reminder,
            repeatRule: original.repeatRule,
            category: original.category,
            priority: original.priority,
            status: original.status,
            color: original.color,
            createdAt: original.createdAt,
            updatedAt: Date()
        )

        do {
            try await service.update(updated)
            XCTFail("Expected reminderSchedulingFailed")
        } catch EventPersistenceError.reminderSchedulingFailed {
            XCTAssertEqual(service.event(id: original.id)?.title, "Original")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Delete

    func testDeleteDoesNotRemoveEventWhenCancelFails() async throws {
        let event = futureEvent(title: "Keep")
        let notifications = FailingNotificationRepository()
        notifications.status = .authorized
        notifications.cancelError = NotificationRepositoryError.schedulingFailed
        let service = makeService(seed: [event], notifications: notifications)
        try await service.refresh()

        do {
            try await service.delete(id: event.id)
            XCTFail("Expected reminderSchedulingFailed")
        } catch EventPersistenceError.reminderSchedulingFailed {
            XCTAssertEqual(service.events.map(\.id), [event.id])
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDeleteCancelsThenRemovesThenRefreshes() async throws {
        let event = futureEvent(title: "Gone")
        let notifications = FailingNotificationRepository()
        notifications.status = .authorized
        let service = makeService(seed: [event], notifications: notifications)
        try await service.refresh()

        try await service.delete(id: event.id)

        XCTAssertTrue(service.events.isEmpty)
        XCTAssertEqual(notifications.cancelledIdentifiers, [event.reminderNotificationIdentifier])
    }
}

// MARK: - Mock Notifications

@MainActor
private final class FailingNotificationRepository: NotificationRepositoryProtocol {

    var status: NotificationAuthorizationStatus = .authorized
    var scheduleError: Error?
    var cancelError: Error?
    var scheduledCount: Int = 0
    var cancelledIdentifiers: [String] = []

    func authorizationStatus() async -> NotificationAuthorizationStatus { status }

    func requestAuthorization() async throws -> Bool {
        status = .authorized
        return true
    }

    func schedule(_ request: NotificationScheduleRequest) async throws {
        if let scheduleError {
            throw scheduleError
        }
        scheduledCount += 1
    }

    func cancel(identifiers: [String]) async throws {
        if let cancelError {
            throw cancelError
        }
        cancelledIdentifiers.append(contentsOf: identifiers)
    }
}
