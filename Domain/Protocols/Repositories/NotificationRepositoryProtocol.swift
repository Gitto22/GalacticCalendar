//
//  NotificationRepositoryProtocol.swift
//  GalacticCalendar
//

import Foundation

/// Payload describing a one-shot local notification to schedule.
struct NotificationScheduleRequest: Equatable, Sendable {

    // MARK: - Properties

    /// Stable identifier used for schedule and cancel.
    let identifier: String

    /// Notification title.
    let title: String

    /// Notification body.
    let body: String

    /// Absolute fire date in the user's local calendar.
    let fireDate: Date

    // MARK: - Lifecycle

    /// Creates a schedule request.
    /// - Parameters:
    ///   - identifier: Unique notification id.
    ///   - title: Title text.
    ///   - body: Body text.
    ///   - fireDate: When the notification should fire.
    init(identifier: String, title: String, body: String, fireDate: Date) {
        self.identifier = identifier
        self.title = title
        self.body = body
        self.fireDate = fireDate
    }
}

/// Authorization state for local notifications.
enum NotificationAuthorizationStatus: String, Sendable, Equatable {

    // MARK: - Cases

    /// Permission has not been requested yet.
    case notDetermined

    /// Notifications are allowed.
    case authorized

    /// Notifications are denied.
    case denied

    /// Provisional / ephemeral platform states treated as limited delivery.
    case limited
}

/// Errors produced while scheduling local notifications.
enum NotificationRepositoryError: Error, Equatable, Sendable {

    // MARK: - Cases

    /// The fire date is not in the future.
    case fireDateInPast

    /// The system rejected scheduling.
    case schedulingFailed

    /// Authorization was denied by the user or system.
    case unauthorized
}

/// Imperative contract for local notification persistence (UserNotifications).
///
/// Implementations live in Data. Application services must not import UserNotifications.
protocol NotificationRepositoryProtocol: AnyObject {

    // MARK: - Authorization

    /// Returns the current notification authorization status.
    func authorizationStatus() async -> NotificationAuthorizationStatus

    /// Requests notification permission from the user.
    /// - Returns: `true` when delivery is allowed.
    func requestAuthorization() async throws -> Bool

    // MARK: - Scheduling

    /// Schedules a local notification.
    /// - Parameter request: Schedule payload.
    func schedule(_ request: NotificationScheduleRequest) async throws

    /// Cancels pending notifications for the given identifiers.
    /// - Parameter identifiers: Notification ids to cancel.
    func cancel(identifiers: [String]) async throws
}
