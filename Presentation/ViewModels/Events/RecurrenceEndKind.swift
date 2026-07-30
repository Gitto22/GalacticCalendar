//
//  RecurrenceEndKind.swift
//  GalacticCalendar
//

import Foundation

/// Editor-facing recurrence end mode (maps to ``RecurrenceEndRule``).
enum RecurrenceEndKind: String, Sendable, CaseIterable, Identifiable, Equatable {

    // MARK: - Cases

    /// No end.
    case never

    /// Stop after a fixed number of occurrences.
    case afterCount

    /// Stop on a calendar date.
    case onDate

    // MARK: - Identifiable

    var id: String { rawValue }
}
