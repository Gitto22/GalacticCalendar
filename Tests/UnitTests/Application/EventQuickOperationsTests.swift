//
//  EventQuickOperationsTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for Sprint 6.6 quick operations (duplicate / move / copy / notifications).
@MainActor
final class EventQuickOperationsTests: XCTestCase {

    // MARK: - Fixtures

    private let fixedNow = Date(timeIntervalSince1970: 1_000_000_000)
    private let sourceStart = Date(timeIntervalSince1970: 1_900_000_000)

    private func makeService(
        seed: [Event] = [],
        notifications: FailingNotificationRepository? = nil
    ) -> EventPersistenceService {
        if let notifications {
            return EventPersistenceService(
                repository: InMemoryEventRepository(seed: seed),
                notificationService: NotificationService(
                    repository: notifications,
                    now: { [fixedNow] in fixedNow }
                )
            )
        }
        return EventPersistenceService(repository: InMemoryEventRepository(seed: seed))
    }

    private func sampleEvent(
        status: EventStatus = .completed,
        reminderOffset: TimeInterval? = -900,
        endOffset: TimeInterval = 3_600,
        isAllDay: Bool = false,
        repeatRule: RepeatRule = .none
    ) -> Event {
        Event(
            title: "Workshop",
            description: "Agenda notes",
            date: sourceStart,
            endDate: sourceStart.addingTimeInterval(endOffset),
            isAllDay: isAllDay,
            timeZoneIdentifier: "UTC",
            reminder: reminderOffset.map { sourceStart.addingTimeInterval($0) },
            repeatRule: repeatRule,
            tags: [.preset(.work)],
            priority: .high,
            status: status,
            color: .orange
        )
    }

    // MARK: - Domain duplicate

    func testDuplicatedResetsStatusAndIdentity() {
        let source = sampleEvent(status: .completed)
        let copy = source.duplicated()

        XCTAssertNotEqual(copy.id, source.id)
        XCTAssertEqual(copy.status, .pending)
        XCTAssertEqual(copy.title, source.title)
        XCTAssertEqual(copy.description, source.description)
        XCTAssertEqual(copy.color, source.color)
        XCTAssertEqual(copy.tags, source.tags)
        XCTAssertEqual(copy.priority, source.priority)
        XCTAssertEqual(copy.repeatRule, source.repeatRule)
        XCTAssertEqual(copy.isAllDay, source.isAllDay)
    }

    func testDuplicatedOntoDatePreservesDurationAndReminderOffset() {
        let source = sampleEvent(reminderOffset: -900, endOffset: 7_200)
        let target = Date(timeIntervalSince1970: 2_000_000_000)
        let copy = source.duplicated(on: target)

        XCTAssertEqual(copy.date, target)
        XCTAssertEqual(copy.endDate, target.addingTimeInterval(7_200))
        XCTAssertEqual(copy.reminder, target.addingTimeInterval(-900))
        XCTAssertEqual(copy.status, .pending)
    }

    func testRescheduledKeepsIdentityAndStatus() {
        let source = sampleEvent(status: .inProgress, reminderOffset: -600)
        let target = Date(timeIntervalSince1970: 2_100_000_000)
        let moved = source.rescheduled(to: target)

        XCTAssertEqual(moved.id, source.id)
        XCTAssertEqual(moved.status, .inProgress)
        XCTAssertEqual(moved.date, target)
        XCTAssertEqual(moved.endDate, target.addingTimeInterval(3_600))
        XCTAssertEqual(moved.reminder, target.addingTimeInterval(-600))
        XCTAssertEqual(moved.title, source.title)
        XCTAssertEqual(moved.repeatRule, source.repeatRule)
    }

    // MARK: - Persistence

    func testDuplicatePersistsNewEventOnFocusedDay() async throws {
        let source = sampleEvent()
        let service = makeService(seed: [source])
        try await service.refresh()

        let day = Date(timeIntervalSince1970: 2_000_000_000)
        let copy = try await service.duplicate(source, onto: day)

        XCTAssertEqual(service.events.count, 2)
        XCTAssertNotEqual(copy.id, source.id)
        XCTAssertEqual(copy.status, .pending)
        XCTAssertEqual(Calendar.current.startOfDay(for: copy.date), Calendar.current.startOfDay(for: day))
    }

    func testMoveUpdatesSameIdentity() async throws {
        let source = sampleEvent(status: .pending)
        let service = makeService(seed: [source])
        try await service.refresh()

        let target = Date(timeIntervalSince1970: 2_050_000_000)
        let moved = try await service.move(source, to: target)

        XCTAssertEqual(service.events.count, 1)
        XCTAssertEqual(moved.id, source.id)
        XCTAssertEqual(moved.date, target)
        XCTAssertEqual(service.event(id: source.id)?.date, target)
    }

    func testCopyCreatesIndependentEventOnTargetDate() async throws {
        let source = sampleEvent(status: .completed)
        let service = makeService(seed: [source])
        try await service.refresh()

        let target = Date(timeIntervalSince1970: 2_060_000_000)
        let copy = try await service.copy(source, to: target)

        XCTAssertEqual(service.events.count, 2)
        XCTAssertNotEqual(copy.id, source.id)
        XCTAssertEqual(copy.date, target)
        XCTAssertEqual(copy.status, .pending)
        XCTAssertEqual(service.event(id: source.id)?.date, sourceStart)
    }

    func testMovePreservesMultiDayDuration() async throws {
        let source = sampleEvent(endOffset: 86_400 * 2 + 3_600)
        let service = makeService(seed: [source])
        try await service.refresh()

        let target = Date(timeIntervalSince1970: 2_070_000_000)
        let moved = try await service.move(source, to: target)

        let expectedDuration = (86_400 * 2 + 3_600)
        XCTAssertEqual(
            moved.endDate?.timeIntervalSince(moved.date) ?? 0,
            TimeInterval(expectedDuration),
            accuracy: 0.5
        )
    }

    // MARK: - Notifications

    func testDuplicateSchedulesReminderForNewIdentity() async throws {
        let notifications = FailingNotificationRepository()
        notifications.status = .authorized
        let source = sampleEvent(reminderOffset: -900)
        let service = makeService(seed: [source], notifications: notifications)
        try await service.refresh()

        let copy = try await service.duplicate(source, onto: Date(timeIntervalSince1970: 2_080_000_000))

        XCTAssertGreaterThanOrEqual(notifications.scheduledCount, 1)
        XCTAssertNotNil(service.event(id: copy.id)?.reminder)
        XCTAssertNotEqual(copy.id, source.id)
    }

    func testMoveReschedulesReminderForSameIdentity() async throws {
        let notifications = FailingNotificationRepository()
        notifications.status = .authorized
        let source = sampleEvent(reminderOffset: -900)
        let service = makeService(seed: [source], notifications: notifications)
        try await service.refresh()
        let scheduledBefore = notifications.scheduledCount

        let target = Date(timeIntervalSince1970: 2_090_000_000)
        let moved = try await service.move(source, to: target)

        XCTAssertEqual(moved.id, source.id)
        XCTAssertEqual(moved.reminder, target.addingTimeInterval(-900))
        XCTAssertGreaterThan(notifications.scheduledCount, scheduledBefore)
    }

    func testCopySchedulesReminderIndependently() async throws {
        let notifications = FailingNotificationRepository()
        notifications.status = .authorized
        let source = sampleEvent(reminderOffset: -1_800)
        let service = makeService(seed: [source], notifications: notifications)
        try await service.refresh()

        let target = Date(timeIntervalSince1970: 2_100_000_000)
        let copy = try await service.copy(source, to: target)

        XCTAssertEqual(copy.reminder, target.addingTimeInterval(-1_800))
        XCTAssertNotNil(service.event(id: source.id))
        XCTAssertNotNil(service.event(id: copy.id))
        XCTAssertGreaterThanOrEqual(notifications.scheduledCount, 1)
    }
}

// MARK: - Test Double

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
