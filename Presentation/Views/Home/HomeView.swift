//
//  HomeView.swift
//  GalacticCalendar
//

import SwiftUI

/// Main Home screen container for Galactic Calendar.
///
/// Composes the approved Home layout using child views.
/// Business logic, calendar behavior, and events remain deferred.
struct HomeView: View {

    // MARK: - Properties

    /// ViewModel driving Home presentation state.
    @State private var viewModel: HomeViewModel

    // MARK: - Lifecycle

    /// Creates the Home screen.
    /// - Parameter viewModel: Home presentation model.
    init(viewModel: HomeViewModel = HomeViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // TODO: Bind month background to the visible calendar month.
            MonthBackgroundView()

            VStack(spacing: 0) {
                // TODO: Connect header actions when Home interactions are defined.
                HomeHeaderView()

                // TODO: Connect Universe Messages when the feature module is enabled.
                UniverseMessageCard()

                // TODO: Embed the real calendar surface without altering the approved design.
                CalendarContainerView()
            }
        }
        // TODO: Apply navigation chrome consistent with the approved Home design.
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Home") {
    HomeView()
        .environment(ThemeManager())
}
#endif
