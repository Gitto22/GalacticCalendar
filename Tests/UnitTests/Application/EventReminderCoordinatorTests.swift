//
//  EventReminderCoordinatorTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// PB-05.2 — reminder side effects live outside ``EventPersistenceService`` body.
@MainActor
final class EventReminderCoordinatorTests: XCTestCase {

    func testNilServiceAuthorizationReturnsFalse() async throws {
        let coordinator = EventReminderCoordinator(notificationService: nil)
        let allowed = try await coordinator.requestAuthorizationIfNeeded()
        XCTAssertFalse(allowed)
    }

    func testNilServiceSynchronizeAndCancelAreNoOps() async throws {
        let coordinator = EventReminderCoordinator(notificationService: nil)
        let event = Event(title: "No reminder", date: Date())
        try await coordinator.synchronize(for: event)
        try await coordinator.cancel(for: event.id)
    }

    func testAuthorizedServiceRequestsPermission() async throws {
        let repository = StubNotificationRepository()
        repository.status = .notDetermined
        repository.grantOnRequest = true
        let service = NotificationService(repository: repository, now: { Date() })
        let coordinator = EventReminderCoordinator(notificationService: service)

        let allowed = try await coordinator.requestAuthorizationIfNeeded()
        XCTAssertTrue(allowed)
        XCTAssertEqual(repository.requestCount, 1)
    }
}

// MARK: - Stub

@MainActor
private final class StubNotificationRepository: NotificationRepositoryProtocol {

    var status: NotificationAuthorizationStatus = .notDetermined
    var grantOnRequest = true
    private(set) var requestCount = 0

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        status
    }

    func requestAuthorization() async throws -> Bool {
        requestCount += 1
        status = grantOnRequest ? .authorized : .denied
        return grantOnRequest
    }

    func schedule(_ request: NotificationScheduleRequest) async throws {}

    func cancel(identifiers: [String]) async throws {}
}
