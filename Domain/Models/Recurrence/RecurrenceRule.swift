//
//  RecurrenceRule.swift
//  GalacticCalendar
//

import Foundation

/// Canonical recurrence description used by ``RecurrenceEngine``.
///
/// ## Persistence bridge
/// ``Event`` stores ``RepeatRule`` (SwiftData string column). Expand via
/// ``RepeatRule/asRecurrenceRule``. Editor presets live on ``RepeatRule`` only.
///
/// ## Reserved extension points
/// - ``byWeekdays`` — specific weekdays (not applied yet)
/// - ``excludedDates`` — skip individual days (not applied yet)
/// - ``customPayload`` — opaque RRULE-like data (not expanded yet)
struct RecurrenceRule: Sendable, Hashable, Codable, Equatable, Identifiable {

    // MARK: - Properties

    /// Base frequency.
    var frequency: RecurrenceFrequency

    /// Every *n* frequency periods. Always ≥ 1.
    var interval: Int

    /// Series end condition.
    var end: RecurrenceEndRule

    /// Reserved: specific weekdays (e.g. Mon/Wed). Empty = unused.
    var byWeekdays: [Int]

    /// Reserved: excluded calendar days (start-of-day anchors). Empty = unused.
    var excludedDates: [Date]

    /// Reserved: opaque custom recurrence payload.
    var customPayload: Data?

    // MARK: - Identifiable

    var id: String {
        "\(frequency.rawValue)-\(interval)-\(end.idToken)"
    }

    // MARK: - Lifecycle

    /// Creates a recurrence rule.
    init(
        frequency: RecurrenceFrequency,
        interval: Int = 1,
        end: RecurrenceEndRule = .never,
        byWeekdays: [Int] = [],
        excludedDates: [Date] = [],
        customPayload: Data? = nil
    ) {
        self.frequency = frequency
        self.interval = max(1, interval)
        self.end = end
        self.byWeekdays = byWeekdays
        self.excludedDates = excludedDates
        self.customPayload = customPayload
    }

    // MARK: - Derived

    var isRecurring: Bool {
        frequency.isRecurring || customPayload != nil
    }
}

// MARK: - End Rule Tokens

private extension RecurrenceEndRule {

    var idToken: String {
        switch self {
        case .never:
            return "never"
        case .after(let count):
            return "after-\(count)"
        case .onDate(let date):
            return "on-\(Int(date.timeIntervalSince1970))"
        }
    }
}
