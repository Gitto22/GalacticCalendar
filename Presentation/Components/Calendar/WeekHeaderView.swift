//
//  WeekHeaderView.swift
//  GalacticCalendar
//

import SwiftUI

/// Weekday header row for the approved monthly calendar.
///
/// Displays the approved Monday-first abbreviations.
/// Saturday and Sunday use ``ColorPalette/weekend``.
struct WeekHeaderView: View {

    // MARK: - Environment

    /// Size class used for responsive typography.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            ForEach(Self.weekdays) { weekday in
                Text(weekday.title)
                    .font(weekdayFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(weekday.isWeekend ? ColorPalette.weekend : ColorPalette.onImagePrimary)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .minimumScaleFactor(LayoutConstants.singleLineMinimumScale)
                    .accessibilityLabel(weekday.title)
                    .accessibilityIdentifier("calendar_weekday_\(weekday.id)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("calendar_week_header")
    }

    // MARK: - Responsive Tokens

    /// Weekday label font adapted to the current size class.
    private var weekdayFont: Font {
        horizontalSizeClass == .regular ? Typography.footnote : Typography.caption
    }
}

// MARK: - Weekday Model

private extension WeekHeaderView {

    /// Presentation model for a weekday header label.
    struct WeekdayItem: Identifiable {

        /// Stable identifier.
        let id: Int

        /// Localized short weekday title.
        let title: String

        /// Whether the weekday is Saturday or Sunday.
        let isWeekend: Bool
    }

    /// Approved Monday-first weekday labels.
    static let weekdays: [WeekdayItem] = [
        WeekdayItem(id: 1, title: String(localized: "weekday_mon_short"), isWeekend: false),
        WeekdayItem(id: 2, title: String(localized: "weekday_tue_short"), isWeekend: false),
        WeekdayItem(id: 3, title: String(localized: "weekday_wed_short"), isWeekend: false),
        WeekdayItem(id: 4, title: String(localized: "weekday_thu_short"), isWeekend: false),
        WeekdayItem(id: 5, title: String(localized: "weekday_fri_short"), isWeekend: false),
        WeekdayItem(id: 6, title: String(localized: "weekday_sat_short"), isWeekend: true),
        WeekdayItem(id: 7, title: String(localized: "weekday_sun_short"), isWeekend: true)
    ]
}

// MARK: - Previews

#if DEBUG
#Preview("Week Header") {
    ZStack {
        MonthBackgroundView()
        WeekHeaderView()
            .padding(.horizontal, Spacing.pageHorizontal)
    }
    .environment(ThemeManager())
    .environment(CalendarAppearanceManager())
}
#endif
