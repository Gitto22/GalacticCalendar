//
//  CalendarDayCell.swift
//  GalacticCalendar
//

import SwiftUI

/// Prepared visual states for a calendar day cell.
///
/// These states describe presentation only. Resolving them from
/// real calendar/event data remains deferred.
enum CalendarDayCellState: String, Sendable, CaseIterable, Equatable, Identifiable {

    // MARK: - Cases

    /// Standard in-month day.
    case normal

    /// Day matching "today".
    case current

    /// Explicitly selected day.
    case selected

    /// Day belonging to the previous or next month.
    case outsideMonth

    /// Day prepared to show event indicators.
    case withEvent

    /// Day prepared for a future gift decoration.
    case withGift

    // MARK: - Identifiable

    /// Stable identifier matching the state name.
    var id: String { rawValue }
}

/// Single day cell for the approved monthly calendar grid.
///
/// Presentation architecture only. No selection or event logic yet.
struct CalendarDayCell: View {

    // MARK: - Environment

    /// Size class used for responsive cell sizing.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Properties

    /// Day number displayed inside the cell.
    let dayNumber: Int

    /// Whether the day falls on Saturday or Sunday.
    let isWeekend: Bool

    /// Prepared visual states for this cell.
    let states: Set<CalendarDayCellState>

    /// Event indicator colors shown under the day number.
    let indicatorColors: [Color]

    // MARK: - Lifecycle

    /// Creates a day cell.
    /// - Parameters:
    ///   - dayNumber: Day of month to display.
    ///   - isWeekend: Weekend styling flag.
    ///   - states: Prepared visual states.
    ///   - indicatorColors: Event indicator colors.
    init(
        dayNumber: Int,
        isWeekend: Bool = false,
        states: Set<CalendarDayCellState> = [.normal],
        indicatorColors: [Color] = []
    ) {
        self.dayNumber = dayNumber
        self.isWeekend = isWeekend
        self.states = states.isEmpty ? [.normal] : states
        self.indicatorColors = indicatorColors
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: Spacing.xxxs) {
                Text(dayNumberText)
                    .font(dayNumberFont)
                    .fontWeight(.medium)
                    .foregroundStyle(dayNumberColor)

                EventIndicatorsView(colors: visibleIndicatorColors)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: dayCellMinHeight)
            .padding(.vertical, Spacing.xxs)

            giftBadge
        }
        .background(ColorPalette.dayCellFill, in: cellShape)
        .overlay(cellBorder)
        .currentDayHighlight(isHighlighted)
        .opacity(states.contains(.outsideMonth) ? ColorPalette.dayOutsideOpacity : 1)
        .accessibilityLabel(Text(dayNumberText))
    }

    // MARK: - Decorations

    /// Gift badge reserved for future features.
    @ViewBuilder
    private var giftBadge: some View {
        if states.contains(.withGift) {
            Image(systemName: Icons.Events.gift)
                .font(Typography.caption2)
                .foregroundStyle(ColorPalette.universeAccent)
                .frame(
                    width: LayoutConstants.dayGiftBadgeSize,
                    height: LayoutConstants.dayGiftBadgeSize
                )
                .padding(Spacing.xxxs)
        }
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

    /// Whether the blue glow highlight should be shown.
    private var isHighlighted: Bool {
        states.contains(.selected) || states.contains(.current)
    }

    /// Indicators shown when the cell is prepared for events.
    private var visibleIndicatorColors: [Color] {
        if states.contains(.withEvent) || indicatorColors.isEmpty == false {
            return indicatorColors
        }

        return []
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Calendar Day Cells") {
    HStack(spacing: Spacing.xs) {
        CalendarDayCell(dayNumber: 10, states: [.normal])
        CalendarDayCell(
            dayNumber: 11,
            states: [.selected, .withEvent],
            indicatorColors: Array(ColorPalette.eventIndicatorColors.prefix(3))
        )
        CalendarDayCell(dayNumber: 14, states: [.withEvent, .withGift], indicatorColors: [ColorPalette.eventIndicatorGreen])
        CalendarDayCell(dayNumber: 15, isWeekend: false, states: [.current])
        CalendarDayCell(dayNumber: 31, states: [.outsideMonth])
    }
    .padding()
    .background(MonthBackgroundView())
    .environment(ThemeManager())
}
#endif
