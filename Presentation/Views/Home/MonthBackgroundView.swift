//
//  MonthBackgroundView.swift
//  GalacticCalendar
//

import SwiftUI

/// Full-screen monthly background loaded from `Assets/Months`.
///
/// Uses ``CalendarAppearanceManager`` to resolve the asset for the **active** displayed month
/// (including navigation overrides). Crossfades discreetly when the month changes.
///
/// Applies a dynamic readability scrim + vertical gradient from
/// ``MonthContrastProfile`` so Header, Calendar, cards, and Universe chrome
/// remain legible without changing approved layout or surface styling.
struct MonthBackgroundView: View {

    // MARK: - Environment

    /// Calendar appearance authority that maps months to asset names.
    @Environment(CalendarAppearanceManager.self) private var calendarAppearance

    /// Honors system Reduce Motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(activeMonthAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                ColorPalette.overlay(for: contrastProfile)
                    .allowsHitTesting(false)

                ColorPalette.readabilityGradient(for: contrastProfile)
                    .allowsHitTesting(false)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .id(activeMonthAssetName)
            .transition(.opacity)
        }
        .ignoresSafeArea()
        .animation(
            Motion.resolved(Motion.calendarBackground, reduceMotion: reduceMotion),
            value: activeMonthAssetName
        )
        .accessibilityHidden(true)
    }

    // MARK: - Asset Resolution

    /// Asset name for the active (displayed) month via ``CalendarAppearanceManager``.
    private var activeMonthAssetName: String {
        calendarAppearance.activeMonthBackgroundName
    }

    /// Active month contrast treatment via ``CalendarAppearanceManager``.
    private var contrastProfile: MonthContrastProfile {
        calendarAppearance.activeMonthContrastProfile
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Month Background") {
    MonthBackgroundView()
        .environment(CalendarAppearanceManager())
}

#Preview("Month Background — Strong (March)") {
    let appearance = CalendarAppearanceManager()
    appearance.prepareDisplayedMonth(3, year: 2026)
    return MonthBackgroundView()
        .environment(appearance)
}
#endif
