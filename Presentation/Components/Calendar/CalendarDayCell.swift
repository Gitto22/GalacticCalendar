//
//  CalendarDayCell.swift
//  GalacticCalendar
//

import SwiftUI

/// Visual states supported by a calendar day cell.
enum CalendarDayCellState: String, Sendable, CaseIterable, Equatable, Identifiable {

    // MARK: - Cases

    /// Standard in-month day.
    case normal

    /// Day matching today.
    case current

    /// Explicitly selected day.
    case selected

    /// Day belonging to the previous or next month.
    case outsideMonth

    /// Day prepared to show event indicators (future).
    case withEvent

    /// Day prepared for a future gift decoration.
    case withGift

    // MARK: - Identifiable

    /// Stable identifier matching the state name.
    var id: String { rawValue }
}

/// Single day cell for the approved monthly calendar grid.
///
/// Renders day number with normal / outside-month / today / selected states.
/// Real events are intentionally not shown yet.
struct CalendarDayCell: View {

    // MARK: - Environment

    /// Size class used for responsive cell sizing.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Properties

    /// Day number displayed inside the cell.
    let dayNumber: Int

    /// Whether the day falls on Saturday or Sunday.
    let isWeekend: Bool

    /// Visual states derived from ``CalendarDay``.
    let states: Set<CalendarDayCellState>

    // MARK: - Lifecycle

    /// Creates a day cell from a domain ``CalendarDay``.
    /// - Parameter day: Domain day produced by ``CalendarEngine``.
    init(day: CalendarDay) {
        self.dayNumber = day.dayNumber
        self.isWeekend = day.isWeekend()
        self.states = CalendarDayPresentationMapper.states(for: day)
    }

    /// Creates a day cell from explicit presentation values.
    /// - Parameters:
    ///   - dayNumber: Day of month to display.
    ///   - isWeekend: Weekend styling flag.
    ///   - states: Visual states.
    init(
        dayNumber: Int,
        isWeekend: Bool = false,
        states: Set<CalendarDayCellState> = [.normal]
    ) {
        self.dayNumber = dayNumber
        self.isWeekend = isWeekend
        self.states = states.isEmpty ? [.normal] : states
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.xxxs) {
            Text(dayNumberText)
                .font(dayNumberFont)
                .fontWeight(.medium)
                .foregroundStyle(dayNumberColor)

            // Layout slot reserved for future events. Empty for now.
            EventIndicatorsView(colors: [])
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: dayCellMinHeight)
        .padding(.vertical, Spacing.xxs)
        .background(ColorPalette.dayCellFill, in: cellShape)
        .overlay(cellBorder)
        .currentDayHighlight(isHighlighted)
        .opacity(isOutsideMonth ? ColorPalette.dayOutsideOpacity : 1)
        .accessibilityLabel(Text(dayNumberText))
        .accessibilityAddTraits(accessibilityTraits)
    }

    // MARK: - State Helpers

    /// Whether the cell belongs to another month.
    private var isOutsideMonth: Bool {
        states.contains(.outsideMonth)
    }

    /// Whether the cell represents today.
    private var isCurrent: Bool {
        states.contains(.current)
    }

    /// Whether the cell is selected.
    private var isSelected: Bool {
        states.contains(.selected)
    }

    /// Whether the cell uses the approved blue highlight.
    private var isHighlighted: Bool {
        isCurrent || isSelected
    }

    /// Accessibility traits reflecting current/selected states.
    private var accessibilityTraits: AccessibilityTraits {
        var traits: AccessibilityTraits = []
        if isSelected {
            traits.insert(.isSelected)
        }
        return traits
    }

    // MARK: - Visual Helpers

    /// Rounded shape used by the approved day cell.
    private var cellShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Spacing.Radius.sm, style: .continuous)
    }

    /// Subtle border for non-highlighted cells.
    @ViewBuilder
    private var cellBorder: some View {
        if isHighlighted == false {
            cellShape.stroke(ColorPalette.dayCellBorder, lineWidth: LayoutConstants.dayCellBorderStroke)
        }
    }

    /// Day number string derived from the cell value.
    private var dayNumberText: String {
        String(dayNumber)
    }

    /// Responsive day number font.
    private var dayNumberFont: Font {
        horizontalSizeClass == .regular ? Typography.body : Typography.callout
    }

    /// Responsive minimum cell height.
    private var dayCellMinHeight: CGFloat {
        horizontalSizeClass == .regular
            ? LayoutConstants.dayCellMinHeightRegular
            : LayoutConstants.dayCellMinHeightCompact
    }

    /// Text color respecting weekend presentation.
    private var dayNumberColor: Color {
        isWeekend ? ColorPalette.weekend : ColorPalette.onImagePrimary
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Calendar Day Cells") {
    let engine = CalendarEngine()
    let days = Array(engine.generateCurrentMonth().prefix(7))

    HStack(spacing: Spacing.xs) {
        ForEach(days) { day in
            CalendarDayCell(day: day)
        }
    }
    .padding()
    .background(MonthBackgroundView())
    .environment(ThemeManager())
}
#endif
