//
//  RootView.swift
//  GalacticCalendar
//

import SwiftUI

/// Root presentation container hosted by the application scene.
///
/// Hosts the approved ``HomeView`` as the main screen.
struct RootView: View {

    // MARK: - Environment

    /// Composition Root providing ViewModel factories and infrastructure.
    @Environment(DependencyContainer.self) private var container

    /// Navigation stack owner injected by the Composition Root.
    @Environment(NavigationManager.self) private var navigationManager

    /// Appearance preferences injected by the Composition Root.
    @Environment(ThemeManager.self) private var themeManager

    // MARK: - State

    /// Stable Home ViewModel created once from the Composition Root.
    @State private var homeViewModel: HomeViewModel?

    /// Stable calendar grid ViewModel bound to the reactive event catalog.
    @State private var calendarGridViewModel: CalendarGridViewModel?

    // MARK: - Body

    var body: some View {
        NavigationStack(path: Bindable(navigationManager).path) {
            Group {
                if let homeViewModel, let calendarGridViewModel {
                    HomeView(
                        viewModel: homeViewModel,
                        calendarGridViewModel: calendarGridViewModel
                    )
                } else {
                    Color.clear
                        .task {
                            let factory = ViewModelFactory(container: container)
                            homeViewModel = factory.makeHomeViewModel()
                            calendarGridViewModel = factory.makeCalendarGridViewModel()
                            await container.eventPersistenceService.bootstrap()
                        }
                }
            }
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        }
        .preferredColorScheme(themeManager.preferredColorScheme)
    }

    // MARK: - Destinations

    /// Resolves a view for the provided route.
    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .root:
            if let homeViewModel, let calendarGridViewModel {
                HomeView(
                    viewModel: homeViewModel,
                    calendarGridViewModel: calendarGridViewModel
                )
            }
        }
    }
}
