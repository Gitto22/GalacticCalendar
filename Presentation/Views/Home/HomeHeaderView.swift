//
//  HomeHeaderView.swift
//  GalacticCalendar
//

import SwiftUI

/// Approved Home header for Galactic Calendar.
///
/// Contains menu control, localized month/year, previous/next month controls,
/// calendar (“Today”) control, and discreet header text transitions.
struct HomeHeaderView: View {

    // MARK: - Environment

    /// Calendar appearance providing month/year presentation data.
    @Environment(CalendarAppearanceManager.self) private var calendarAppearance

    /// Size class used for responsive typography across iPhone, iPad, and macOS.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Honors system Reduce Motion for month/year text changes.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Properties

    /// Optional menu action (Universe History). Visual design unchanged.
    private let onMenuTap: (() -> Void)?

    /// Optional event-search action (Sprint 6.7). When set with ``onMenuTap``, the
    /// leading control becomes a menu.
    private let onSearchTap: (() -> Void)?

    /// Optional Smart Daily Agenda action (Sprint 6.8).
    private let onAgendaTap: (() -> Void)?

    /// Moves to the previous calendar month.
    private let onPreviousMonth: (() -> Void)?

    /// Moves to the next calendar month.
    private let onNextMonth: (() -> Void)?

    /// Opens the quick month picker when the month title is tapped.
    private let onMonthTitleTap: (() -> Void)?

    /// Opens the year picker when the year label is tapped.
    private let onYearTap: (() -> Void)?

    /// Jumps to today when the trailing calendar control is tapped.
    private let onTodayTap: (() -> Void)?

    // MARK: - Lifecycle

    /// Creates the approved Home header.
    /// - Parameters:
    ///   - onMenuTap: Called when the menu control is tapped (or History is chosen).
    ///   - onSearchTap: Called when Search events is chosen from the menu.
    ///   - onAgendaTap: Called when Daily Agenda is chosen from the menu.
    ///   - onPreviousMonth: Called for previous-month navigation.
    ///   - onNextMonth: Called for next-month navigation.
    ///   - onMonthTitleTap: Called when the month name is tapped (month picker).
    ///   - onYearTap: Called when the year is tapped (year picker).
    ///   - onTodayTap: Called when the calendar (“Today”) control is tapped.
    init(
        onMenuTap: (() -> Void)? = nil,
        onSearchTap: (() -> Void)? = nil,
        onAgendaTap: (() -> Void)? = nil,
        onPreviousMonth: (() -> Void)? = nil,
        onNextMonth: (() -> Void)? = nil,
        onMonthTitleTap: (() -> Void)? = nil,
        onYearTap: (() -> Void)? = nil,
        onTodayTap: (() -> Void)? = nil
    ) {
        self.onMenuTap = onMenuTap
        self.onSearchTap = onSearchTap
        self.onAgendaTap = onAgendaTap
        self.onPreviousMonth = onPreviousMonth
        self.onNextMonth = onNextMonth
        self.onMonthTitleTap = onMonthTitleTap
        self.onYearTap = onYearTap
        self.onTodayTap = onTodayTap
    }

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
    @ViewBuilder
    private var menuButton: some View {
        if onMenuTap != nil, (onSearchTap != nil || onAgendaTap != nil) {
            Menu {
                Button {
                    onMenuTap?()
                } label: {
                    Label(
                        String(localized: "universe_history_title"),
                        systemImage: Icons.Home.universeMessage
                    )
                }
                if onSearchTap != nil {
                    Button {
                        onSearchTap?()
                    } label: {
                        Label(
                            String(localized: "event_search_title"),
                            systemImage: Icons.Universe.search
                        )
                    }
                }
                if onAgendaTap != nil {
                    Button {
                        onAgendaTap?()
                    } label: {
                        Label(
                            String(localized: "agenda_title"),
                            systemImage: Icons.Home.agenda
                        )
                    }
                }
            } label: {
                Image(systemName: Icons.Navigation.menu)
                    .font(iconFont)
                    .foregroundStyle(ColorPalette.onImagePrimary)
                    .frame(width: Spacing.headerControlSize, height: Spacing.headerControlSize)
                    .modifier(
                        GlassEffectModifier(
                            intensity: .subtle,
                            shapeStyle: .circle,
                            cornerRadius: 0,
                            showsGlow: false
                        )
                    )
            }
            .accessibilityLabel(String(localized: "navigation_menu_a11y"))
            .accessibilityHint(String(localized: "navigation_menu_a11y_hint"))
            .accessibilityIdentifier("home_menu")
        } else {
            GlassCircleButton(systemImage: Icons.Navigation.menu, font: iconFont) {
                onMenuTap?()
            }
            .accessibilityLabel(String(localized: "navigation_menu_a11y"))
            .accessibilityHint(String(localized: "navigation_menu_a11y_hint"))
            .accessibilityIdentifier("home_menu")
        }
    }

    // MARK: - Center

    /// Previous control, month name, year, and next control.
    ///
    /// Uses the same colors and typography as the approved header.
    /// Previous / next use reserved calendar chevrons (no new palette).
    private var monthCenterContent: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            monthStepButton(
                systemImage: Icons.Calendar.previous,
                accessibilityLabel: String(localized: "calendar_month_previous_a11y"),
                accessibilityHint: String(localized: "calendar_month_previous_a11y_hint"),
                accessibilityIdentifier: "home_month_previous",
                action: onPreviousMonth
            )

            Button {
                onMonthTitleTap?()
            } label: {
                Text(monthTitle)
                    .font(monthTitleFont)
                    .foregroundStyle(ColorPalette.onImagePrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(LayoutConstants.singleLineMinimumScale)
                    .contentTransition(.opacity)
            }
            .buttonStyle(.plain)
            .disabled(onMonthTitleTap == nil)
            .accessibilityLabel(monthTitle)
            .accessibilityHint(String(localized: "calendar_month_picker_a11y_hint"))
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("home_month_title")
            .animation(
                Motion.resolved(Motion.calendarHeader, reduceMotion: reduceMotion),
                value: monthTitle
            )

            Button {
                onYearTap?()
            } label: {
                Text(calendarAppearance.displayedYearText())
                    .font(yearTitleFont)
                    .foregroundStyle(ColorPalette.onImageAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(LayoutConstants.singleLineMinimumScale)
                    .contentTransition(.opacity)
            }
            .buttonStyle(.plain)
            .disabled(onYearTap == nil)
            .accessibilityLabel(calendarAppearance.displayedYearText())
            .accessibilityHint(String(localized: "calendar_year_picker_a11y_hint"))
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("home_year_title")
            .animation(
                Motion.resolved(Motion.calendarHeader, reduceMotion: reduceMotion),
                value: calendarAppearance.activeYear
            )

            monthStepButton(
                systemImage: Icons.Calendar.next,
                accessibilityLabel: String(localized: "calendar_month_next_a11y"),
                accessibilityHint: String(localized: "calendar_month_next_a11y_hint"),
                accessibilityIdentifier: "home_month_next",
                action: onNextMonth
            )
        }
        .accessibilityElement(children: .contain)
    }

    /// Compact month-step chevron matching approved accent styling.
    private func monthStepButton(
        systemImage: String,
        accessibilityLabel: String,
        accessibilityHint: String,
        accessibilityIdentifier: String,
        action: (() -> Void)?
    ) -> some View {
        Button {
            action?()
        } label: {
            Image(systemName: systemImage)
                .font(chevronFont)
                .foregroundStyle(ColorPalette.onImageAccent)
                .frame(minWidth: Spacing.md, minHeight: Spacing.md)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    // MARK: - Trailing

    /// Calendar (“Today”) button on the trailing edge.
    private var calendarButton: some View {
        GlassCircleButton(font: iconFont) {
            onTodayTap?()
        } label: {
            calendarGlyph
        }
        .disabled(onTodayTap == nil)
        .accessibilityLabel(String(localized: "calendar_today_a11y"))
        .accessibilityHint(String(localized: "calendar_today_a11y_hint"))
        .accessibilityIdentifier("home_today")
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
        calendarAppearance.displayedMonthName().uppercased(with: .autoupdatingCurrent)
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
    .environment(CalendarAppearanceManager())
}
#endif
