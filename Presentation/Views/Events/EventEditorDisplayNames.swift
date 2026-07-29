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
        case .fiveMinutes:
            String(localized: "event_reminder_5_min")
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
    static func title(for rule: RepeatRule) -> String {
        title(for: rule.frequency)
    }

    /// Localized title for a predefined repeat frequency.
    static func title(for frequency: RepeatFrequency) -> String {
        switch frequency {
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

    // MARK: - Validation

    /// Localized message for a single validation issue.
    static func message(for issue: EventValidationIssue) -> String {
        switch issue {
        case .titleRequired:
            String(localized: "event_validation_title_required")
        case .titleTooLong(let maximum):
            String(format: String(localized: "event_validation_title_too_long"), maximum)
        case .descriptionTooLong(let maximum):
            String(format: String(localized: "event_validation_description_too_long"), maximum)
        case .invalidDate:
            String(localized: "event_validation_invalid_date")
        case .invalidEndDate:
            String(localized: "event_validation_invalid_end_date")
        case .invalidTimeZone:
            String(localized: "event_validation_invalid_timezone")
        case .invalidReminder:
            String(localized: "event_validation_invalid_reminder")
        case .invalidRepeatInterval:
            String(localized: "event_validation_invalid_repeat_interval")
        case .invalidRepeatEndDate:
            String(localized: "event_validation_invalid_repeat_end_date")
        }
    }

    /// Joined localized summary for one or more validation issues.
    static func validationSummary(for issues: [EventValidationIssue]) -> String {
        issues.map(message(for:)).joined(separator: "\n")
    }

    // MARK: - Persistence Errors

    /// Localized message for a persistence / reminder failure.
    static func message(for error: EventPersistenceError) -> String {
        switch error {
        case .validationFailed(let issues):
            validationSummary(for: issues)
        case .notFound:
            String(localized: "event_error_not_found")
        case .saveFailed:
            String(localized: "event_error_save_failed")
        case .reminderUnauthorized:
            String(localized: "event_error_reminder_unauthorized")
        case .reminderSchedulingFailed:
            String(localized: "event_error_reminder_scheduling_failed")
        case .reminderFireDateInPast:
            String(localized: "event_error_reminder_fire_date_in_past")
        case .catalogLoadFailed:
            String(localized: "event_error_catalog_load_failed")
        case .storeUnavailable:
            String(localized: "event_error_store_unavailable")
        case .unknown:
            String(localized: "event_error_unknown")
        }
    }
}
