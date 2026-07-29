//
//  RootView.swift
//  GalacticCalendar
//

import SwiftUI

/// Root presentation container hosted by the application scene.
///
/// Renders the approved Home composition available so far:
/// background, header, Universe Message card, and monthly calendar architecture.
struct RootView: View {

    // MARK: - Environment

    /// Navigation stack owner injected by the Composition Root.
    @Environment(NavigationManager.self) private var navigationManager

    /// Appearance preferences injected by the Composition Root.
    @Environment(ThemeManager.self) private var themeManager

    // MARK: - Body

    var body: some View {
        NavigationStack(path: Bindable(navigationManager).path) {
            homeContent
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
                #if os(iOS)
                .toolbar(.hidden, for: .navigationBar)
                #endif
        }
        .preferredColorScheme(themeManager.preferredColorScheme)
    }

    // MARK: - Home

    /// Approved Home layout with calendar architecture.
    private var homeContent: some View {
        ZStack(alignment: .top) {
            MonthBackgroundView()

            VStack(spacing: Spacing.sm) {
                HomeHeaderView()

                UniverseMessageCard()
                    .padding(.horizontal, Spacing.pageHorizontal)

                CalendarContainerView()

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Destinations

    /// Resolves a view for the provided route.
    /// - Parameter route: Navigation destination.
    /// - Returns: Destination view.
    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .root:
            homeContent
        }
    }
}
