//
//  NotificationRepository.swift
//  GalacticCalendar
//

import Foundation
import UserNotifications

/// UserNotifications-backed repository for local event reminders.
///
/// Maps Domain ``NotificationScheduleRequest`` values to `UNNotificationRequest`
/// without exposing UserNotifications types to Application or Presentation.
@MainActor
final class NotificationRepository: NotificationRepositoryProtocol {

    // MARK: - Properties

    /// System notification center.
    private let center: UNUserNotificationCenter

    // MARK: - Lifecycle

    /// Creates a repository bound to a notification center.
    /// - Parameter center: Notification center. Defaults to the shared center.
    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    // MARK: - Authorization

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .authorized, .ephemeral:
            return .authorized
        case .provisional:
            return .limited
        case .denied:
            return .denied
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Scheduling

    func schedule(_ request: NotificationScheduleRequest) async throws {
        let status = await authorizationStatus()
        guard status == .authorized || status == .limited else {
            throw NotificationRepositoryError.unauthorized
        }

        guard request.fireDate > Date() else {
            throw NotificationRepositoryError.fireDateInPast
        }

        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: request.fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let notificationRequest = UNNotificationRequest(
            identifier: request.identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(notificationRequest)
        } catch {
            throw NotificationRepositoryError.schedulingFailed
        }
    }

    func cancel(identifiers: [String]) async throws {
        guard identifiers.isEmpty == false else {
            return
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}
