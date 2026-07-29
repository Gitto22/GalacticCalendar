//
//  CalendarContainerView.swift
//  GalacticCalendar
//

import SwiftUI

/// Container that hosts the approved Home calendar surface.
struct CalendarContainerView: View {

    // MARK: - Properties

    /// Engine that generates the monthly day structure.
    private let engine: CalendarEngine

    // MARK: - Lifecycle

    /// Creates the calendar container.
    /// - Parameter engine: Calendar structure generator.
    init(engine: CalendarEngine = CalendarEngine()) {
        self.engine = engine
    }

    // MARK: - Body

    var body: some View {
        CalendarGridView(engine: engine)
            .padding(.horizontal, Spacing.pageHorizontal)
            // TODO: Forward calendar interactions to HomeViewModel later.
            // TODO: Connect eventColors / hasEvents through SwiftData later.
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
