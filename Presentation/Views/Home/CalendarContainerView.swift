//
//  CalendarContainerView.swift
//  GalacticCalendar
//

import SwiftUI

/// Container that hosts the approved Home calendar surface.
struct CalendarContainerView: View {

    // MARK: - Body

    var body: some View {
        CalendarGridView()
            .padding(.horizontal, Spacing.pageHorizontal)
            // TODO: Forward calendar interactions to HomeViewModel later.
            // TODO: Replace sample days with SwiftData-backed domain models.
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Calendar Container") {
    ZStack {
        MonthBackgroundView()
        CalendarContainerView()
    }
    .environment(ThemeManager())
}
#endif
