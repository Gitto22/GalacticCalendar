//
//  EventReminderOption.swift
//  GalacticCalendar
//

import Foundation

/// Reminder offset options exposed by the event editor.
enum EventReminderOption: Int, Sendable, CaseIterable, Identifiable {

    // MARK: - Cases

    /// No reminder.
    case none = -1

    /// Reminder at the event time.
    case atEventTime = 0

    /// Reminder 15 minutes before.
    case fifteenMinutes = 15

    /// Reminder 30 minutes before.
    case thirtyMinutes = 30

    /// Reminder 1 hour before.
    case oneHour = 60

    /// Reminder 1 day before.
    case oneDay = 1_440

    // MARK: - Identifiable

    var id: Int { rawValue }

    // MARK: - Mapping

    /// Builds an absolute reminder date from an event date.
    func reminderDate(relativeTo eventDate: Date) -> Date? {
        switch self {
        case .none:
            return nil
        case .atEventTime:
            return eventDate
        case .fifteenMinutes, .thirtyMinutes, .oneHour, .oneDay:
            return eventDate.addingTimeInterval(TimeInterval(-rawValue * 60))
        }
    }

    /// Resolves the closest option for a stored reminder date.
    static func option(for reminder: Date?, eventDate: Date) -> EventReminderOption {
        guard let reminder else {
            return .none
        }

        let deltaMinutes = Int((eventDate.timeIntervalSince(reminder) / 60.0).rounded())
        return EventReminderOption(rawValue: deltaMinutes) ?? .fifteenMinutes
    }
}
