//
//  CalendarGridView.swift
//  GalacticCalendar
//

import SwiftUI

/// Custom monthly calendar grid matching the approved Galactic Calendar design.
///
/// Draws the current month exclusively from ``CalendarEngine``
/// as a fixed 7×6 (42-cell) grid. No simulated data.
struct CalendarGridView: View {

    // MARK: - Environment

    /// Size class used for responsive spacing.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Properties

    /// Exactly 42 domain days for the visible month grid.
    private let days: [CalendarDay]

    /// Month number requested from the engine.
    private let displayedMonth: Int

    /// Year requested from the engine.
    private let displayedYear: Int

    /// Identifier of the locally selected day, if any.
    @State private var selectedDayID: String?

    // MARK: - Lifecycle

    /// Creates a calendar grid for the engine's current month and year.
    /// - Parameter engine: Calendar structure generator.
    init(engine: CalendarEngine = CalendarEngine()) {
        let month = engine.currentMonth()
        let year = engine.currentYear()
        let generated = engine.generateDays(month: month, year: year)

        self.displayedMonth = month
        self.displayedYear = year
        self.days = Array(generated.prefix(CalendarConstants.monthlyGridCellCount))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: gridSpacing) {
            WeekHeaderView()

            LazyVGrid(columns: Self.columns, spacing: gridSpacing) {
                ForEach(days) { day in
                    dayCell(for: day)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            Text("\(displayedMonth)/\(displayedYear)")
        )
    }

    // MARK: - Cells

    /// Builds a tappable day cell with selection support prepared.
    /// - Parameter day: Domain day from ``CalendarEngine``.
    /// - Returns: Day cell view.
    @ViewBuilder
    private func dayCell(for day: CalendarDay) -> some View {
        let presentedDay = applyingSelection(to: day)

        CalendarDayCell(day: presentedDay)
            .contentShape(Rectangle())
            .onTapGesture {
                selectDay(day)
            }
    }

    // MARK: - Selection

    /// Marks a day as selected when it belongs to the current month.
    /// - Parameter day: Tapped domain day.
    private func selectDay(_ day: CalendarDay) {
        guard day.isCurrentMonth else {
            return
        }

        selectedDayID = day.id
    }

    /// Returns a copy of the day with the local selection flag applied.
    /// - Parameter day: Source domain day.
    /// - Returns: Day ready for presentation.
    private func applyingSelection(to day: CalendarDay) -> CalendarDay {
        var presented = day
        presented.isSelected = (day.id == selectedDayID)
        return presented
    }

    // MARK: - Grid

    /// Seven equal-width columns → 42 cells produce six rows.
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
#Preview("Calendar Grid — Current Month") {
    ZStack {
        MonthBackgroundView()
        CalendarGridView()
            .padding(.horizontal, Spacing.pageHorizontal)
    }
    .environment(ThemeManager())
}
#endif
