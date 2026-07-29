//
//  NotificationManager.swift
//  GalacticCalendar
//

import Foundation

/// Legacy Infrastructure façade for notifications.
///
/// Local event reminders are owned by ``NotificationService``
/// (Application) + ``NotificationRepository`` (Data). Prefer those types.
/// This manager remains as a thin forward-looking hook for remote / push work.
enum NotificationManager {

    // MARK: - Guidance

    /// Documents the active local-reminder entry point.
    static let localReminderServiceTypeName = "NotificationService"
}
