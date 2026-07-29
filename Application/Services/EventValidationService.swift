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

    /// Reminder date is invalid relative to the event date.
    case invalidReminder
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
        issues.append(contentsOf: validateDates(eventDate: event.date, reminder: event.reminder))

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

    /// Validates the event date and optional reminder.
    private func validateDates(eventDate: Date, reminder: Date?) -> [EventValidationIssue] {
        var issues: [EventValidationIssue] = []

        if eventDate.timeIntervalSinceReferenceDate.isFinite == false {
            issues.append(.invalidDate)
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
}
