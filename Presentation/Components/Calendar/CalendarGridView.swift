//
//  CalendarGridView.swift
//  GalacticCalendar
//

import SwiftUI

/// Custom monthly calendar grid matching the approved Galactic Calendar design.
///
/// Renders days produced by ``CalendarEngine``.
/// No `DatePicker` or system calendar UI components are used.
struct CalendarGridView: View {

    // MARK: - Environment

    /// Size class used for responsive spacing.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Properties

    /// Domain days produced by the calendar engine.
    private let days: [CalendarDay]

    // MARK: - Lifecycle

    /// Creates a calendar grid.
    /// - Parameter days: Domain days to render.
    init(days: [CalendarDay]) {
        self.days = Array(days.prefix(CalendarConstants.sampleCellCount))
    }

    /// Creates a calendar grid for the engine's current month.
    init(engine: CalendarEngine = CalendarEngine()) {
        self.init(days: engine.generateCurrentMonth())
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: gridSpacing) {
            WeekHeaderView()

            LazyVGrid(columns: Self.columns, spacing: gridSpacing) {
                ForEach(days) { day in
                    CalendarDayCell(
                        dayNumber: day.dayNumber,
                        isWeekend: day.isWeekend(),
                        states: CalendarDayPresentationMapper.states(for: day),
                        indicatorColors: CalendarDayPresentationMapper.colors(for: day.eventColors)
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
