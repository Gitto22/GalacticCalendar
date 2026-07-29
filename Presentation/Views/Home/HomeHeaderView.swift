//
//  HomeHeaderView.swift
//  GalacticCalendar
//

import SwiftUI

/// Approved Home header for Galactic Calendar.
///
/// Contains menu control, localized month/year, month-change affordance,
/// and calendar control. Actions remain deferred.
struct HomeHeaderView: View {

    // MARK: - Environment

    /// Theme authority providing month/year presentation data.
    @Environment(ThemeManager.self) private var themeManager

    /// Size class used for responsive typography across iPhone, iPad, and macOS.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Body

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            menuButton
            Spacer(minLength: Spacing.xs)
            monthCenterContent
            Spacer(minLength: Spacing.xs)
            calendarButton
        }
        .padding(.horizontal, Spacing.pageHorizontal)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Leading

    /// Menu button on the leading edge.
    private var menuButton: some View {
        GlassCircleButton(systemImage: Icons.Navigation.menu, font: iconFont) {
            // TODO: Implement menu action.
        }
    }

    // MARK: - Center

    /// Month name, year, and month-change arrow.
    private var monthCenterContent: some View {
        Button {
            // TODO: Implement month navigation using ThemeManager.prepareDisplayedMonth(_:year:).
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text(monthTitle)
                    .font(monthTitleFont)
                    .foregroundStyle(ColorPalette.onImagePrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(LayoutConstants.singleLineMinimumScale)

                Text(themeManager.displayedYearText())
                    .font(yearTitleFont)
                    .foregroundStyle(ColorPalette.onImageAccent)
                    .lineLimit(1)

                Image(systemName: Icons.Calendar.changeMonth)
                    .font(chevronFont)
                    .foregroundStyle(ColorPalette.onImageAccent)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Trailing

    /// Calendar button on the trailing edge.
    private var calendarButton: some View {
        GlassCircleButton(font: iconFont) {
            // TODO: Implement calendar button action.
        } label: {
            calendarGlyph
        }
    }

    /// Calendar glyph with decorative star from the approved design.
    private var calendarGlyph: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: Icons.Calendar.calendar)
                .font(iconFont)

            Image(systemName: Icons.Calendar.star)
                .font(Typography.caption2)
                .offset(x: Spacing.xxs, y: -Spacing.xxxs)
        }
        .foregroundStyle(ColorPalette.onImagePrimary)
    }

    // MARK: - Content Helpers

    /// Localized month name in uppercase.
    private var monthTitle: String {
        themeManager.displayedMonthName().uppercased(with: .autoupdatingCurrent)
    }

    // MARK: - Responsive Tokens

    /// Month title font adapted to the current size class.
    private var monthTitleFont: Font {
        horizontalSizeClass == .regular ? Typography.largeTitle : Typography.title
    }

    /// Year title font adapted to the current size class.
    private var yearTitleFont: Font {
        horizontalSizeClass == .regular ? Typography.title2 : Typography.title3
    }

    /// Icon font adapted to the current size class.
    private var iconFont: Font {
        horizontalSizeClass == .regular ? Typography.title2 : Typography.title3
    }

    /// Chevron font adapted to the current size class.
    private var chevronFont: Font {
        horizontalSizeClass == .regular ? Typography.callout : Typography.footnote
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Home Header") {
    ZStack {
        MonthBackgroundView()
        VStack(spacing: Spacing.sm) {
            HomeHeaderView()
            Spacer()
        }
    }
    .environment(ThemeManager())
}
#endif
