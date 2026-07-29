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

    /// Number of day cells used by the sample monthly grid architecture.
    static let sampleCellCount = columnCount * maxRowCount

    /// Maximum event indicator dots rendered under a day number.
    static let maxEventIndicators = 4
}
