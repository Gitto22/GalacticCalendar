//
//  MonthBackgroundView.swift
//  GalacticCalendar
//

import SwiftUI

/// Full-screen monthly background loaded from `Assets/Months`.
///
/// Resolves the current month through ``ThemeManager`` and displays
/// the matching approved asset. Does not generate artwork, gradients,
/// or drawn backgrounds.
struct MonthBackgroundView: View {

    // MARK: - Environment

    /// Theme authority that maps months to asset names.
    @Environment(ThemeManager.self) private var themeManager

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            Image(resolvedAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    // MARK: - Asset Resolution

    /// Asset name for the device's current month.
    private var resolvedAssetName: String {
        let month = themeManager.currentMonth()
        return themeManager.backgroundAssetName(for: month)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Month Background") {
    MonthBackgroundView()
        .environment(ThemeManager())
}
#endif
