//
//  RecurrenceEndRule.swift
//  GalacticCalendar
//

import Foundation

/// When a recurrence series stops generating occurrences.
///
/// ## Reserved (not expanded yet)
/// Future sprints may add per-occurrence exclusions without changing this enum.
enum RecurrenceEndRule: Sendable, Hashable, Codable, Equatable {

    // MARK: - Cases

    /// Series continues without a stored end (callers still apply a query window).
    case never

    /// Stop after ``count`` occurrences (the master start counts as #1).
    case after(count: Int)

    /// Last occurrence must start on or before ``date`` (inclusive day in the series TZ).
    case onDate(Date)
}
