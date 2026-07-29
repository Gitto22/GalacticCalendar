//
//  CalendarGridView.swift
//  GalacticCalendar
//

import SwiftUI

/// Sample day model used while calendar logic is deferred.
///
/// Will be replaced by Domain / SwiftData-backed models later.
struct CalendarDaySample: Identifiable, Equatable {

    // MARK: - Properties

    /// Stable identity for grid rendering.
    let id: Int

    /// Day number shown in the cell.
    let dayNumber: Int

    /// Whether the sample day is a weekend.
    let isWeekend: Bool

    /// Prepared visual states.
    let states: Set<CalendarDayCellState>

    /// Sample event indicator colors.
    let indicatorColors: [Color]
}

/// Custom monthly calendar grid matching the approved Galactic Calendar design.
///
/// Fixed 7-column / max 6-row architecture with simulated data.
/// No `DatePicker` or system calendar components are used.
struct CalendarGridView: View {

    // MARK: - Environment

    /// Size class used for responsive spacing.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Properties

    /// Sample days feeding the architectural grid.
    private let days: [CalendarDaySample]

    // MARK: - Lifecycle

    /// Creates a calendar grid.
    /// - Parameter days: Sample days to render. Defaults to architectural placeholders.
    init(days: [CalendarDaySample] = CalendarGridView.sampleDays) {
        let limited = Array(days.prefix(CalendarConstants.sampleCellCount))
        self.days = limited
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: gridSpacing) {
            WeekHeaderView()

            LazyVGrid(columns: Self.columns, spacing: gridSpacing) {
                ForEach(days) { day in
                    CalendarDayCell(
                        dayNumber: day.dayNumber,
                        isWeekend: day.isWeekend,
                        states: day.states,
                        indicatorColors: day.indicatorColors
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Grid

    /// Seven equal-width columns for the monthly layout.
    private static let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: Spacing.xxs),
        count: CalendarConstants.columnCount
    )

    /// Responsive spacing between header and rows.
    private var gridSpacing: CGFloat {
        horizontalSizeClass == .regular ? Spacing.xs : Spacing.xxs
    }
}

// MARK: - Sample Data

extension CalendarGridView {

    /// Architectural sample month used until real calendar generation is connected.
    ///
    /// Always provides enough cells for 7 columns × 6 rows.
    static let sampleDays: [CalendarDaySample] = {
        let leadingOutside = [30, 31]
        let inMonth = Array(1...31)
        let trailingOutside = Array(1...9)
        let numbers = Array((leadingOutside + inMonth + trailingOutside).prefix(CalendarConstants.sampleCellCount))

        return numbers.enumerated().map { index, number in
            let column = index % CalendarConstants.columnCount
            let isWeekend = column >= 5
            let isOutside = index < leadingOutside.count || index >= leadingOutside.count + inMonth.count

            var states: Set<CalendarDayCellState> = isOutside ? [.outsideMonth] : [.normal]

            if isOutside == false {
                if number == 15 {
                    states = [.current]
                }

                if number == 11 {
                    states = [.selected, .withEvent]
                }

                if number == 14 {
                    states = [.withEvent, .withGift]
                }

                if number == 8 || number == 22 {
                    states.insert(.withEvent)
                }
            }

            let indicators: [Color]
            if number == 11 {
                indicators = Array(ColorPalette.eventIndicatorColors.prefix(3))
            } else if number == 14 {
                indicators = [ColorPalette.eventIndicatorGreen]
            } else if number == 8 || number == 22 {
                indicators = [ColorPalette.eventIndicatorPurple, ColorPalette.eventIndicatorBlue]
            } else {
                indicators = []
            }

            return CalendarDaySample(
                id: index,
                dayNumber: number,
                isWeekend: isWeekend,
                states: states,
                indicatorColors: indicators
            )
        }
    }()
}

// MARK: - Previews

#if DEBUG
#Preview("Calendar Grid") {
    ZStack {
        MonthBackgroundView()
        CalendarGridView()
            .padding(.horizontal, Spacing.pageHorizontal)
    }
    .environment(ThemeManager())
}
#endif
