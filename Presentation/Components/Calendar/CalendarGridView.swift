//
//  CalendarGridView.swift
//  GalacticCalendar
//

import SwiftUI

/// Approved monthly calendar grid driven exclusively by ``CalendarEngine``.
///
/// Always renders the current month as a fixed 7×6 (42-cell) grid.
struct CalendarGridView: View {

    // MARK: - Environment

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Properties

    /// Exactly 42 domain days from ``CalendarEngine``.
    private let days: [CalendarDay]

    /// Current month obtained from the engine.
    private let displayedMonth: Int

    /// Current year obtained from the engine.
    private let displayedYear: Int

    /// Locally selected day identifier.
    @State private var selectedDayID: String?

    /// Called after an in-month day is selected.
    private let onDaySelected: ((CalendarDay) -> Void)?

    // MARK: - Lifecycle

    /// Creates a grid for the engine's current month and year.
    /// - Parameters:
    ///   - engine: Calendar structure generator.
    ///   - onDaySelected: Optional handler invoked with the tapped in-month day.
    init(
        engine: CalendarEngine = CalendarEngine(),
        onDaySelected: ((CalendarDay) -> Void)? = nil
    ) {
        let month = engine.currentMonth()
        let year = engine.currentYear()
        let generated = engine.generateDays(month: month, year: year)

        self.displayedMonth = month
        self.displayedYear = year
        self.days = Array(generated.prefix(CalendarConstants.monthlyGridCellCount))
        self.onDaySelected = onDaySelected
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
        .accessibilityLabel(Text("\(displayedMonth)/\(displayedYear)"))
    }

    // MARK: - Cells

    @ViewBuilder
    private func dayCell(for day: CalendarDay) -> some View {
        CalendarDayCell(day: applyingSelection(to: day))
            .contentShape(Rectangle())
            .onTapGesture {
                selectDay(day)
            }
    }

    // MARK: - Selection

    private func selectDay(_ day: CalendarDay) {
        guard day.isCurrentMonth else { return }
        selectedDayID = day.id
        onDaySelected?(day)
    }

    private func applyingSelection(to day: CalendarDay) -> CalendarDay {
        var presented = day
        presented.isSelected = (day.id == selectedDayID)
        return presented
    }

    // MARK: - Grid

    private static let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: Spacing.xxs),
        count: CalendarConstants.columnCount
    )

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
