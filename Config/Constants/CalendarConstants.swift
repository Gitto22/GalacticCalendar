//
//  CalendarConstants.swift
//  GalacticCalendar
//

import Foundation

/// Calendar-related immutable constants.
enum CalendarConstants {

    // MARK: - Structure

    /// Number of months represented by the approved space backgrounds.
    static let monthBackgroundCount = 12

    /// Number of columns in the monthly grid.
    static let columnCount = 7

    /// Maximum number of rows in the monthly grid.
    static let maxRowCount = 6

    /// Number of day cells in the approved monthly grid (6 rows × 7 columns).
    static let sampleCellCount = columnCount * maxRowCount

    /// Alias for the fixed monthly grid capacity used by ``CalendarEngine``.
    static let monthlyGridCellCount = sampleCellCount

    /// Maximum event indicator dots rendered under a day number.
    static let maxEventIndicators = 4
}
