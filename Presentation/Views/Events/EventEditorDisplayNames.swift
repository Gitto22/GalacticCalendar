//
//  EventEditorDisplayNames.swift
//  GalacticCalendar
//

import Foundation

/// Localized display titles for event editor selectors.
enum EventEditorDisplayNames {

    // MARK: - Reminder

    /// Localized title for a reminder option.
    static func title(for option: EventReminderOption) -> String {
        switch option {
        case .none:
            String(localized: "event_reminder_none")
        case .atEventTime:
            String(localized: "event_reminder_at_time")
        case .fifteenMinutes:
            String(localized: "event_reminder_15_min")
        case .thirtyMinutes:
            String(localized: "event_reminder_30_min")
        case .oneHour:
            String(localized: "event_reminder_1_hour")
        case .oneDay:
            String(localized: "event_reminder_1_day")
        }
    }

    // MARK: - Repeat

    /// Localized title for a repeat rule.
    static func title(for rule: EventRepeatRule) -> String {
        switch rule {
        case .none:
            String(localized: "event_repeat_none")
        case .daily:
            String(localized: "event_repeat_daily")
        case .weekly:
            String(localized: "event_repeat_weekly")
        case .monthly:
            String(localized: "event_repeat_monthly")
        case .yearly:
            String(localized: "event_repeat_yearly")
        }
    }

    // MARK: - Category

    /// Localized title for a category.
    static func title(for category: EventCategory) -> String {
        switch category {
        case .work:
            String(localized: "event_category_work")
        case .personal:
            String(localized: "event_category_personal")
        case .health:
            String(localized: "event_category_health")
        case .finances:
            String(localized: "event_category_finances")
        case .family:
            String(localized: "event_category_family")
        case .studies:
            String(localized: "event_category_studies")
        case .travel:
            String(localized: "event_category_travel")
        case .other:
            String(localized: "event_category_other")
        }
    }

    // MARK: - Priority

    /// Localized title for a priority.
    static func title(for priority: EventPriority) -> String {
        switch priority {
        case .low:
            String(localized: "event_priority_low")
        case .medium:
            String(localized: "event_priority_medium")
        case .high:
            String(localized: "event_priority_high")
        case .critical:
            String(localized: "event_priority_critical")
        }
    }

    // MARK: - Status

    /// Localized title for a status.
    static func title(for status: EventStatus) -> String {
        switch status {
        case .pending:
            String(localized: "event_status_pending")
        case .inProgress:
            String(localized: "event_status_in_progress")
        case .completed:
            String(localized: "event_status_completed")
        case .cancelled:
            String(localized: "event_status_cancelled")
        }
    }
}
