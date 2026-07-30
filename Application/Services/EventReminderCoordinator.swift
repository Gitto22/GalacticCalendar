//
//  EventReminderCoordinator.swift
//  GalacticCalendar
//

import Foundation

/// Local-reminder side effects for the event mutation pipeline.
///
/// Extracted from ``EventPersistenceService`` (PB-05.2) so persistence orchestration
/// does not own ``NotificationService`` call sites directly. Authorization, sync,
/// and cancel remain reminder concerns — not storage.
@MainActor
final class EventReminderCoordinator {

    // MARK: - Dependencies

    /// Optional notification service (`nil` = reminders are no-ops).
    private let notificationService: NotificationService?

    // MARK: - Lifecycle

    /// Creates a reminder coordinator.
    /// - Parameter notificationService: Reminder synchronizer, or `nil` to skip side effects.
    init(notificationService: NotificationService? = nil) {
        self.notificationService = notificationService
    }

    // MARK: - Authorization

    /// Requests local-notification permission when still undetermined.
    /// - Returns: `true` when notifications may be delivered; `false` when unavailable.
    @discardableResult
    func requestAuthorizationIfNeeded() async throws -> Bool {
        guard let notificationService else {
            return false
        }
        return try await notificationService.requestAuthorizationIfNeeded()
    }

    // MARK: - Sync

    /// Synchronizes the local reminder for a persisted event.
    func synchronize(for event: Event) async throws {
        guard let notificationService else {
            return
        }
        try await notificationService.synchronizeReminder(for: event)
    }

    /// Cancels the local reminder for a deleted event.
    func cancel(for eventID: UUID) async throws {
        guard let notificationService else {
            return
        }
        try await notificationService.cancelReminder(for: eventID)
    }
}
