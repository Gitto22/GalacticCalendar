//
//  NotificationService.swift
//  GalacticCalendar
//

import Foundation

/// Application service that schedules and cancels local reminders for ``Event`` values.
///
/// ## Responsibilities
/// - Request notification authorization.
/// - Map ``Event`` reminder fields into ``NotificationScheduleRequest``.
/// - Cancel reminders when events are deleted or reminders are cleared.
///
/// ## Error policy
/// Scheduling and cancellation failures propagate to callers (no silent `try?`).
/// Authorization denial while a future reminder is required throws ``NotificationRepositoryError/unauthorized``.
///
/// ## Non-responsibilities
/// - No SwiftUI.
/// - No SwiftData.
/// - No direct `UserNotifications` usage (delegates to ``NotificationRepositoryProtocol``).
@MainActor
final class NotificationService {

    // MARK: - Dependencies

    /// Imperative notification repository.
    private let repository: any NotificationRepositoryProtocol

    /// Clock used to decide whether a fire date is still in the future (testable).
    private let now: () -> Date

    // MARK: - Lifecycle

    /// Creates a notification service.
    /// - Parameters:
    ///   - repository: Notification repository implementation.
    ///   - now: Clock provider. Defaults to `Date.init`.
    init(
        repository: any NotificationRepositoryProtocol,
        now: @escaping () -> Date = { Date() }
    ) {
        self.repository = repository
        self.now = now
    }

    // MARK: - Authorization

    /// Returns the current authorization status.
    func authorizationStatus() async -> NotificationAuthorizationStatus {
        await repository.authorizationStatus()
    }

    /// Requests notification permission when status is still undetermined.
    /// - Returns: `true` when notifications may be delivered.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let status = await repository.authorizationStatus()
        switch status {
        case .authorized, .limited:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await repository.requestAuthorization()
            } catch {
                return false
            }
        }
    }

    // MARK: - Event Reminders

    /// Schedules or cancels the local reminder for an event.
    ///
    /// Always cancels any previous request for the event id first, then schedules
    /// only when ``Event/reminder`` is in the future and authorization allows it.
    /// - Parameter event: Event whose reminder should be synchronized.
    /// - Throws: ``NotificationRepositoryError`` when cancel/schedule fails, or when
    ///   a future reminder is required but authorization is denied.
    func synchronizeReminder(for event: Event) async throws {
        let identifier = event.reminderNotificationIdentifier
        try await repository.cancel(identifiers: [identifier])

        guard event.shouldScheduleReminder(relativeTo: now()),
              let fireDate = event.reminder else {
            return
        }

        let allowed = await requestAuthorizationIfNeeded()
        guard allowed else {
            throw NotificationRepositoryError.unauthorized
        }

        let request = NotificationScheduleRequest(
            identifier: identifier,
            title: event.title,
            body: reminderBody(for: event),
            fireDate: fireDate
        )

        try await repository.schedule(request)
    }

    /// Cancels any pending/delivered reminder for the given event id.
    /// - Parameter eventID: Event identifier.
    /// - Throws: ``NotificationRepositoryError`` when cancellation fails.
    func cancelReminder(for eventID: UUID) async throws {
        let identifier = Event.reminderNotificationIdentifier(for: eventID)
        try await repository.cancel(identifiers: [identifier])
    }

    // MARK: - Private

    /// Localized-ready body describing the upcoming event time.
    private func reminderBody(for event: Event) -> String {
        let time = event.date.formatted(date: .omitted, time: .shortened)
        return String(format: String(localized: "notification_event_reminder_body"), time)
    }
}
