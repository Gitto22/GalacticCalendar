//
//  RootView.swift
//  GalacticCalendar
//

import SwiftUI

/// Root presentation container hosted by the application scene.
///
/// Hosts the approved ``HomeView`` as the main screen.
///
/// ## Navigation (QA-06)
/// Product flows use **modal presentation** owned by feature ViewModels
/// (`fullScreenCover` / `sheet` + `isPresenting*` flags). The root
/// ``NavigationStack`` is a shell host only — not a product push stack.
struct RootView: View {

    // MARK: - Environment

    /// Composition Root providing ViewModel factories and infrastructure.
    @Environment(DependencyContainer.self) private var container

    /// Appearance preferences injected by the Composition Root.
    @Environment(ThemeManager.self) private var themeManager

    // MARK: - State

    /// Stable Home ViewModel created once from the Composition Root.
    @State private var homeViewModel: HomeViewModel?

    /// Stable calendar grid ViewModel bound to the reactive event catalog.
    @State private var calendarGridViewModel: CalendarGridViewModel?

    // MARK: - Body

    var body: some View {
        NavigationStack {
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
                            let home = factory.makeHomeViewModel()
                            if let launchError = container.persistenceLaunchError {
                                home.consumeLaunchError(launchError)
                            }
                            homeViewModel = home
                            calendarGridViewModel = factory.makeCalendarGridViewModel()
                            await home.bootstrap()
                        }
                }
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        }
        .preferredColorScheme(themeManager.preferredColorScheme)
    }
}
