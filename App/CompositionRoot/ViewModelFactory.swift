//
//  ViewModelFactory.swift
//  GalacticCalendar
//

import Foundation

/// Factory for constructing Presentation ViewModels from the Composition Root.
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

    /// Builds a ``HomeViewModel`` wired to the reactive event catalog.
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(eventPersistenceService: container.eventPersistenceService)
    }

    // MARK: - Calendar

    /// Builds a ``CalendarGridViewModel`` bound to the reactive event catalog.
    /// - Parameter engine: Optional calendar engine override.
    /// - Returns: Configured grid ViewModel.
    func makeCalendarGridViewModel(
        engine: CalendarEngine = CalendarEngine()
    ) -> CalendarGridViewModel {
        CalendarGridViewModel(
            persistenceService: container.eventPersistenceService,
            engine: engine
        )
    }

    // MARK: - Events

    /// Builds an ``EventEditorViewModel`` for creating an event on the given date.
    /// - Parameter date: Initial event date.
    /// - Returns: Configured editor ViewModel in create mode.
    func makeEventEditorViewModel(date: Date = Date()) -> EventEditorViewModel {
        let viewModel = EventEditorViewModel(
            persistenceService: container.eventPersistenceService,
            initialDate: date
        )
        viewModel.prepareForCreation(on: date)
        return viewModel
    }

    /// Builds a ``DayEventsViewModel`` for the given calendar day.
    /// - Parameter date: Day to list.
    /// - Returns: Configured day-events ViewModel.
    func makeDayEventsViewModel(date: Date) -> DayEventsViewModel {
        DayEventsViewModel(
            date: date,
            persistenceService: container.eventPersistenceService
        )
    }
}
