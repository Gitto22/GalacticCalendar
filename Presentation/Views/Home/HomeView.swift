//
//  HomeView.swift
//  GalacticCalendar
//

import SwiftUI

/// Approved Home screen for Galactic Calendar.
///
/// Composes:
/// 1. ``MonthBackgroundView``
/// 2. ``HomeHeaderView``
/// 3. ``UniverseMessageCard``
/// 4. ``CalendarGridView``
struct HomeView: View {

    // MARK: - Properties

    /// ViewModel for future Home interactions.
    @State private var viewModel: HomeViewModel

    /// Engine providing real days for the current month.
    private let calendarEngine: CalendarEngine

    // MARK: - Lifecycle

    /// Creates the Home screen.
    /// - Parameters:
    ///   - viewModel: Home presentation model.
    ///   - calendarEngine: Calendar structure generator.
    init(
        viewModel: HomeViewModel = HomeViewModel(),
        calendarEngine: CalendarEngine = CalendarEngine()
    ) {
        _viewModel = State(initialValue: viewModel)
        self.calendarEngine = calendarEngine
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            MonthBackgroundView()

            VStack(spacing: Spacing.sm) {
                HomeHeaderView()

                UniverseMessageCard()
                    .padding(.horizontal, Spacing.pageHorizontal)

                CalendarGridView(engine: calendarEngine)
                    .padding(.horizontal, Spacing.pageHorizontal)

                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Home") {
    HomeView()
        .environment(ThemeManager())
}
#endif
