//
//  RecurrenceFrequency.swift
//  GalacticCalendar
//

import Foundation

/// How often a recurring event repeats.
///
/// Raw values are CloudKit-friendly. ``never`` maps to the legacy
/// ``RepeatFrequency/none`` persistence token via ``RepeatRule``.
enum RecurrenceFrequency: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {

    // MARK: - Cases

    /// Does not repeat.
    case never

    /// Every day (× ``RecurrenceRule/interval``).
    case daily

    /// Every week (× interval).
    case weekly

    /// Every two weeks (interval applies as a multiplier of the biweekly period).
    case biweekly

    /// Every month (× interval).
    case monthly

    /// Every year (× interval).
    case yearly

    // MARK: - Identifiable

    var id: String { rawValue }

    // MARK: - Derived

    /// `true` when occurrences should be generated.
    var isRecurring: Bool {
        self != .never
    }
}
