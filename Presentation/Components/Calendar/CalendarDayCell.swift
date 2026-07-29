//
//  CalendarDayCell.swift
//  GalacticCalendar
//

import SwiftUI

/// Visual states supported by a calendar day cell.
enum CalendarDayCellState: String, Sendable, CaseIterable, Equatable, Identifiable {

    // MARK: - Cases

    /// Standard day inside the displayed month.
    case normal

    /// Day matching today.
    case current

    /// Explicitly selected day.
    case selected

    /// Day belonging to the previous month.
    case previousMonth

    /// Day belonging to the next month.
    case nextMonth

    /// Legacy alias kept for outside-month presentation helpers.
    case outsideMonth

    /// Reserved for event indicators when the day has events.
    case withEvent

    /// Reserved for future gift decoration.
    case withGift

    // MARK: - Identifiable

    var id: String { rawValue }
}

/// Single day cell for the approved monthly calendar grid.
///
/// Shows the day number with:
/// current-month, previous-month, next-month, today, selected,
/// and event-indicator states.
struct CalendarDayCell: View {

    // MARK: - Environment

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Properties

    let dayNumber: Int
    let isWeekend: Bool
    let states: Set<CalendarDayCellState>
    let eventColors: [EventColor]
    let eventCount: Int

    // MARK: - Lifecycle

    /// Creates a day cell from a domain ``CalendarDay``.
    init(day: CalendarDay) {
        self.dayNumber = day.dayNumber
        self.isWeekend = day.isWeekend()
        self.states = CalendarDayPresentationMapper.states(for: day)
        self.eventColors = day.eventColors
        self.eventCount = day.eventCount
    }

    /// Creates a day cell from explicit presentation values.
    init(
        dayNumber: Int,
        isWeekend: Bool = false,
        states: Set<CalendarDayCellState> = [.normal],
        eventColors: [EventColor] = [],
        eventCount: Int = 0
    ) {
        self.dayNumber = dayNumber
        self.isWeekend = isWeekend
        self.states = states.isEmpty ? [.normal] : states
        self.eventColors = eventColors
        self.eventCount = eventCount
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.xxxs) {
            Text(dayNumberText)
                .font(dayNumberFont)
                .fontWeight(.medium)
                .foregroundStyle(dayNumberColor)

            EventIndicatorsView(eventColors: eventColors, totalCount: eventCount)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: dayCellMinHeight)
        .padding(.vertical, Spacing.xxs)
        .background(ColorPalette.dayCellFill, in: cellShape)
        .overlay(cellBorder)
        .currentDayHighlight(isHighlighted)
        .opacity(isOutsideDisplayedMonth ? ColorPalette.dayOutsideOpacity : 1)
        .accessibilityLabel(Text(dayNumberText))
        .accessibilityAddTraits(accessibilityTraits)
    }

    // MARK: - State Helpers

    /// Previous or next month relative to the displayed month.
    private var isOutsideDisplayedMonth: Bool {
        states.contains(.previousMonth)
            || states.contains(.nextMonth)
            || states.contains(.outsideMonth)
    }

    private var isCurrent: Bool {
        states.contains(.current)
    }

    private var isSelected: Bool {
        states.contains(.selected)
    }

    /// Today and selected days share the approved blue highlight.
    private var isHighlighted: Bool {
        isCurrent || isSelected
    }

    private var accessibilityTraits: AccessibilityTraits {
        var traits: AccessibilityTraits = []
        if isSelected {
            traits.insert(.isSelected)
        }
        return traits
    }

    // MARK: - Visual Helpers

    private var cellShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Spacing.Radius.sm, style: .continuous)
    }

    @ViewBuilder
    private var cellBorder: some View {
        if isHighlighted == false {
            cellShape.stroke(ColorPalette.dayCellBorder, lineWidth: LayoutConstants.dayCellBorderStroke)
        }
    }

    private var dayNumberText: String {
        String(dayNumber)
    }

    private var dayNumberFont: Font {
        horizontalSizeClass == .regular ? Typography.body : Typography.callout
    }

    private var dayCellMinHeight: CGFloat {
        horizontalSizeClass == .regular
            ? LayoutConstants.dayCellMinHeightRegular
            : LayoutConstants.dayCellMinHeightCompact
    }

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
