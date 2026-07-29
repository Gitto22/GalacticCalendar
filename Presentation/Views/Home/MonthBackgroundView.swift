//
//  MonthBackgroundView.swift
//  GalacticCalendar
//

import SwiftUI

/// Full-screen monthly background loaded from `Assets/Months`.
///
/// Uses ``ThemeManager`` to resolve the asset for the current month.
/// Does not generate artwork.
struct MonthBackgroundView: View {

    // MARK: - Environment

    /// Theme authority that maps months to asset names.
    @Environment(ThemeManager.self) private var themeManager

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            Image(currentMonthAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    // MARK: - Asset Resolution

    /// Asset name for the device's current month via ``ThemeManager``.
    private var currentMonthAssetName: String {
        themeManager.currentBackgroundAsset()
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Month Background") {
    MonthBackgroundView()
        .environment(ThemeManager())
}
#endif
