//
//  EventValidationService.swift
//  GalacticCalendar
//

import Foundation

/// Validation issues detected for an ``Event``.
enum EventValidationIssue: Equatable, Sendable {

    // MARK: - Cases

    /// Title is missing or blank.
    case titleRequired

    /// Title exceeds the maximum allowed length.
    case titleTooLong(maximum: Int)

    /// Description exceeds the maximum allowed length.
    case descriptionTooLong(maximum: Int)

    /// Event date is not finite / usable.
    case invalidDate

    /// End date is missing required ordering relative to the start date.
    case invalidEndDate

    /// Time zone identifier is not a known IANA zone.
    case invalidTimeZone

    /// Reminder date is invalid relative to the event date.
    case invalidReminder

    /// Recurrence interval is invalid (must be ≥ 1).
    case invalidRepeatInterval

    /// Recurrence end date is invalid relative to the event date.
    case invalidRepeatEndDate

    /// Recurrence occurrence count is invalid (must be ≥ 1).
    case invalidRepeatOccurrenceCount
}

/// Validates Galactic Calendar events before persistence or presentation.
///
/// Pure application service with no SwiftData or CloudKit dependencies.
struct EventValidationService: Sendable {

    // MARK: - Limits

    /// Maximum allowed title length.
    let maximumTitleLength: Int

    /// Maximum allowed description length.
    let maximumDescriptionLength: Int

    // MARK: - Lifecycle

    /// Creates a validation service.
    /// - Parameters:
    ///   - maximumTitleLength: Max characters for ``Event/title``.
    ///   - maximumDescriptionLength: Max characters for ``Event/description``.
    init(
        maximumTitleLength: Int = 120,
        maximumDescriptionLength: Int = 2_000
    ) {
        self.maximumTitleLength = maximumTitleLength
        self.maximumDescriptionLength = maximumDescriptionLength
    }

    // MARK: - Validation

    /// Validates an event and returns every detected issue.
    /// - Parameter event: Event to validate.
    /// - Returns: Ordered validation issues. Empty when valid.
    func validate(_ event: Event) -> [EventValidationIssue] {
        var issues: [EventValidationIssue] = []

        issues.append(contentsOf: validateTitle(event.title))
        issues.append(contentsOf: validateDescription(event.description))
        issues.append(contentsOf: validateDates(
            eventDate: event.date,
            endDate: event.endDate,
            reminder: event.reminder
        ))
        issues.append(contentsOf: validateTimeZone(event.timeZoneIdentifier))
        issues.append(contentsOf: validateRepeatRule(event.repeatRule, eventDate: event.date))

        return issues
    }

    /// Returns whether the event passes all validation rules.
    /// - Parameter event: Event to validate.
    /// - Returns: `true` when no issues are found.
    func isValid(_ event: Event) -> Bool {
        validate(event).isEmpty
    }

    // MARK: - Rules

    /// Validates the event title.
    private func validateTitle(_ title: String) -> [EventValidationIssue] {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        var issues: [EventValidationIssue] = []

        if trimmed.isEmpty {
            issues.append(.titleRequired)
        }

        if title.count > maximumTitleLength {
            issues.append(.titleTooLong(maximum: maximumTitleLength))
        }

        return issues
    }

    /// Validates the event description.
    private func validateDescription(_ description: String) -> [EventValidationIssue] {
        guard description.count > maximumDescriptionLength else {
            return []
        }

        return [.descriptionTooLong(maximum: maximumDescriptionLength)]
    }

    /// Validates the event start, optional end, and optional reminder.
    private func validateDates(
        eventDate: Date,
        endDate: Date?,
        reminder: Date?
    ) -> [EventValidationIssue] {
        var issues: [EventValidationIssue] = []

        if eventDate.timeIntervalSinceReferenceDate.isFinite == false {
            issues.append(.invalidDate)
        }

        if let endDate {
            let endIsFinite = endDate.timeIntervalSinceReferenceDate.isFinite
            if endIsFinite == false || endDate < eventDate {
                issues.append(.invalidEndDate)
            }
        }

        if let reminder {
            let reminderIsFinite = reminder.timeIntervalSinceReferenceDate.isFinite
            let reminderIsAfterEvent = reminder > eventDate

            if reminderIsFinite == false || reminderIsAfterEvent {
                issues.append(.invalidReminder)
            }
        }

        return issues
    }

    /// Validates the stored IANA time zone identifier.
    private func validateTimeZone(_ identifier: String) -> [EventValidationIssue] {
        guard EventTimeZone.isValidIdentifier(identifier) else {
            return [.invalidTimeZone]
        }
        return []
    }

    /// Validates a recurrence rule without expanding occurrences.
    private func validateRepeatRule(_ rule: RepeatRule, eventDate: Date) -> [EventValidationIssue] {
        var issues: [EventValidationIssue] = []

        if rule.interval < 1 {
            issues.append(.invalidRepeatInterval)
        }

        if let endDate = rule.endDate {
            let endIsFinite = endDate.timeIntervalSinceReferenceDate.isFinite
            if endIsFinite == false || endDate < eventDate {
                issues.append(.invalidRepeatEndDate)
            }
        }

        if let occurrenceCount = rule.occurrenceCount, occurrenceCount < 1 {
            issues.append(.invalidRepeatOccurrenceCount)
        }

        return issues
    }
}