//
//  ViewModelFactory.swift
//  GalacticCalendar
//

import Foundation

/// Constructs Presentation ViewModels from the Composition Root.
///
/// # Scope (certified QA-07)
/// Factory builds **screen entry** ViewModels owned by `RootView`:
/// - ``HomeViewModel`` (+ nested Universe card + search)
/// - ``CalendarGridViewModel``
/// - ``UniverseMessageViewModel`` (also nested under Home)
///
/// **Child / modal** ViewModels (`DayEvents`, `EventEditor`, Templates,
/// `SmartAgenda`, pickers) are created by their parent screen coordinator,
/// reusing the same Application façades already injected — not a second
/// Composition Root. Universe History/Detail receive Domain **protocols**
/// via closures defined here so Infrastructure concretes never appear in Views.
///
/// # Lifecycle
/// Stateless wrapper; safe to instantiate per bootstrap. Dependencies come
/// exclusively from the bound ``DependencyContainer``.
@MainActor
final class ViewModelFactory {

    // MARK: - Properties

    /// Shared dependency container used by ViewModel construction.
    private let container: DependencyContainer

    // MARK: - Lifecycle

    /// Creates a factory bound to the Composition Root.
    /// - Parameter container: Application dependency container.
    init(container: DependencyContainer) {
        self.container = container
    }

    // MARK: - Home

    /// Builds a ``HomeViewModel`` wired to events and Universe Messages.
    func makeHomeViewModel() -> HomeViewModel {
        let search = EventSearchViewModel(
            persistenceService: container.eventPersistenceService
        )
        return HomeViewModel(
            eventPersistenceService: container.eventPersistenceService,
            eventTemplateService: container.eventTemplateService,
            universeMessageViewModel: makeUniverseMessageViewModel(),
            universeMessageEngine: container.universeMessageEngine,
            eventSearchViewModel: search,
            makeUniverseHistoryViewModel: { [container] in
                UniverseHistoryViewModel(
                    repository: container.universeMessageRepository,
                    favoriteService: container.universeMessageService
                )
            },
            makeUniverseMessageDetailViewModel: { [container] context in
                UniverseMessageDetailViewModel(
                    context: context,
                    repository: container.universeMessageRepository,
                    favoriteService: container.universeMessageService
                )
            }
        )
    }

    /// Builds a ``UniverseMessageViewModel`` bound to the Universe engine and history recording.
    func makeUniverseMessageViewModel() -> UniverseMessageViewModel {
        UniverseMessageViewModel(
            engine: container.universeMessageEngine,
            repository: container.universeMessageRepository
        )
    }

    // MARK: - Calendar

    /// Builds a ``CalendarGridViewModel`` bound to the reactive event catalog.
    /// - Parameter engine: Optional calendar engine override (stateless; default new instance).
    /// - Returns: Configured grid ViewModel.
    func makeCalendarGridViewModel(
        engine: CalendarEngine = CalendarEngine()
    ) -> CalendarGridViewModel {
        CalendarGridViewModel(
            persistenceService: container.eventPersistenceService,
            engine: engine
        )
    }
}
