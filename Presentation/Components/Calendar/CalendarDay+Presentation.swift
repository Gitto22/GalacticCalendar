//
//  CalendarDay+Presentation.swift
//  GalacticCalendar
//

import SwiftUI

/// Presentation mapping from domain ``CalendarDay`` values to UI tokens.
enum CalendarDayPresentationMapper {

    // MARK: - Mapping

    /// Maps domain event color tokens to Design System colors.
    static func colors(for tokens: [CalendarEventColorToken]) -> [Color] {
        tokens.prefix(CalendarConstants.maxEventIndicators).map(color(for:))
    }

    /// Maps a single domain token to a Design System color.
    static func color(for token: CalendarEventColorToken) -> Color {
        switch token {
        case .purple:
            ColorPalette.eventIndicatorPurple
        case .green:
            ColorPalette.eventIndicatorGreen
        case .blue:
            ColorPalette.eventIndicatorBlue
        case .orange:
            ColorPalette.eventIndicatorOrange
        }
    }

    /// Builds cell states from a domain day.
    ///
    /// Event indicators are not mapped yet.
    static func states(for day: CalendarDay) -> Set<CalendarDayCellState> {
        var states: Set<CalendarDayCellState> = []

        switch day.membership {
        case .previousMonth:
            states.insert(.previousMonth)
        case .nextMonth:
            states.insert(.nextMonth)
        case .currentMonth:
            break
        }

        if day.isToday {
            states.insert(.current)
        }

        if day.isSelected {
            states.insert(.selected)
        }

        if states.isEmpty {
            states.insert(.normal)
        }

        return states
    }
}
