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

    // MARK: - Identifiable

    var id: String { rawValue }
}

/// Single day cell for the approved monthly calendar grid.
///
/// Shows the day number with:
/// current-month, previous-month, next-month, today, selected,
/// and event-indicator states.
///
/// Event indicators are purely presentational: the parent ``CalendarGridView``
/// supplies an annotated ``CalendarDay`` after each ``EventPersistenceService``
/// revision bump. This cell does not fetch or observe persistence itself.
struct CalendarDayCell: View {

    // MARK: - Environment

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Properties

    let dayNumber: Int
    let isWeekend: Bool
    let states: Set<CalendarDayCellState>
    let eventColors: [EventColor]
    let eventCount: Int

    /// VoiceOver summary for the cell (empty when outside the displayed month).
    private let accessibilitySummary: String

    /// Stable UI-test / VoiceOver identifier (`nil` when outside the month).
    private let dayAccessibilityIdentifier: String?

    // MARK: - Lifecycle

    /// Creates a day cell from a domain ``CalendarDay``.
    init(day: CalendarDay) {
        self.dayNumber = day.dayNumber
        self.isWeekend = day.isWeekend()
        self.states = CalendarDayPresentationMapper.states(for: day)
        self.eventColors = day.eventColors
        self.eventCount = day.eventCount
        self.accessibilitySummary = Self.makeAccessibilitySummary(for: day)
        self.dayAccessibilityIdentifier = day.isCurrentMonth
            ? "calendar_day_\(day.id)"
            : nil
    }

    /// Creates a day cell from explicit presentation values.
    init(
        dayNumber: Int,
        isWeekend: Bool = false,
        states: Set<CalendarDayCellState> = [.normal],
        eventColors: [EventColor] = [],
        eventCount: Int = 0,
        accessibilitySummary: String? = nil
    ) {
        self.dayNumber = dayNumber
        self.isWeekend = isWeekend
        self.states = states.isEmpty ? [.normal] : states
        self.eventColors = eventColors
        self.eventCount = eventCount
        self.accessibilitySummary = accessibilitySummary ?? String(dayNumber)
        self.dayAccessibilityIdentifier = nil
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilitySummary))
        .accessibilityHint(Text(String(localized: "calendar_day_a11y_hint")))
        .accessibilityValue(Text(accessibilityValueText))
        .accessibilityAddTraits(accessibilityTraits)
        .accessibilityIdentifier(dayAccessibilityIdentifier ?? "")
        .accessibilityHidden(isOutsideDisplayedMonth)
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
        guard isOutsideDisplayedMonth == false else {
            return []
        }
        var traits: AccessibilityTraits = .isButton
        if isSelected {
            traits.insert(.isSelected)
        }
        return traits
    }

    /// Selected state for VoiceOver value (event count already lives in the label).
    private var accessibilityValueText: String {
        if isSelected {
            return String(localized: "calendar_day_selected_a11y")
        }
        return String(localized: "calendar_day_not_selected_a11y")
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

    // MARK: - Accessibility

    /// Builds a VoiceOver label with date context, today/selected, and event count.
    private static func makeAccessibilitySummary(for day: CalendarDay) -> String {
        guard day.isCurrentMonth else {
            return String(day.dayNumber)
        }

        var parts: [String] = [
            day.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
        ]
        if day.isToday {
            parts.append(String(localized: "calendar_day_today_a11y"))
        }
        if day.isSelected {
            parts.append(String(localized: "calendar_day_selected_a11y"))
        }
        if day.eventCount > 0 {
            parts.append(
                String(
                    format: String(localized: "calendar_day_events_a11y"),
                    locale: .current,
                    day.eventCount
                )
            )
        }
        return parts.joined(separator: ", ")
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
    .environment(CalendarAppearanceManager())
}
#endif
