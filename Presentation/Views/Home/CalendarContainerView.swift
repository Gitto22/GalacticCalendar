//
//  CalendarContainerView.swift
//  GalacticCalendar
//

import SwiftUI

/// Thin host for ``CalendarGridView`` when a container wrapper is needed.
///
/// ``HomeView`` embeds ``CalendarGridView`` directly.
struct CalendarContainerView: View {

    // MARK: - Properties

    private let engine: CalendarEngine

    // MARK: - Lifecycle

    init(engine: CalendarEngine = CalendarEngine()) {
        self.engine = engine
    }

    // MARK: - Body

    var body: some View {
        CalendarGridView(engine: engine)
            .padding(.horizontal, Spacing.pageHorizontal)
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
