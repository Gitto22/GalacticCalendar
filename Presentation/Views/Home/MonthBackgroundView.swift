//
//  MonthBackgroundView.swift
//  GalacticCalendar
//

import SwiftUI

/// Draws the monthly space background behind the Home interface.
///
/// Backgrounds are loaded exclusively from `Assets/Months`.
/// Do not redesign or generate replacement artwork.
struct MonthBackgroundView: View {

    // MARK: - Body

    var body: some View {
        // TODO: Resolve the asset name for the currently displayed month.
        // TODO: Load the corresponding imageset from Assets/Months.
        // TODO: Draw the background full-bleed beneath the Home interface.
        Color.clear
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Month Background") {
    MonthBackgroundView()
}
#endif
