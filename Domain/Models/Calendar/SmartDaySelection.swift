//
//  SmartDaySelection.swift
//  GalacticCalendar
//

import Foundation

/// Result of resolving a preferred day into a valid day for a target month/year.
///
/// ## Algorithm
/// 1. If there is no preferred day → no selection.
/// 2. If `preferredDay` exists in the target month → keep it.
/// 3. Otherwise clamp to the last valid day of that month
///    (handles 31→28/29/30 and leap-day collapse).
struct SmartDaySelection: Equatable, Sendable {

    // MARK: - Properties

    /// Valid day-of-month in the target period (`1...31`).
    let dayNumber: Int

    /// `true` when the preferred day was shortened to fit the month.
    let wasClamped: Bool
}
