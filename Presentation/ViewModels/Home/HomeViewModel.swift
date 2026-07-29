//
//  HomeViewModel.swift
//  GalacticCalendar
//

import Foundation

/// Presentation model for the Home screen.
///
/// Owns Home interaction state for day selection, day-events list,
/// and event-editor presentation.
@MainActor
@Observable
final class HomeViewModel {

    // MARK: - Dependencies

    /// Persistence façade used to construct feature ViewModels.
    private let eventPersistenceService: EventPersistenceService

    // MARK: - State

    /// Absolute date of the currently selected calendar day, if any.
    private(set) var selectedDate: Date?

    /// `true` while the day-events list is presented.
    var isPresentingDayEvents: Bool = false

    /// ViewModel driving the day-events screen, if any.
    private(set) var dayEventsViewModel: DayEventsViewModel?

    /// `true` while the event editor modal is presented from Home.
    var isPresentingEventEditor: Bool = false

    /// ViewModel driving the Home-presented event editor, if any.
    private(set) var eventEditorViewModel: EventEditorViewModel?

    // MARK: - Lifecycle

    /// Creates the Home presentation model.
    /// - Parameter eventPersistenceService: Service injected from the Composition Root.
    init(eventPersistenceService: EventPersistenceService) {
        self.eventPersistenceService = eventPersistenceService
    }

    // MARK: - Intents

    /// Selects an in-month day and routes by event count.
    ///
    /// - 0 events → ``EventEditorView`` (create)
    /// - 1 event → ``EventEditorView`` (edit that event)
    /// - 2+ events → ``DayEventsView``
    /// - Parameter day: Calendar day tapped by the user.
    func selectDay(_ day: CalendarDay) async {
        guard day.isCurrentMonth else {
            return
        }

        selectedDate = day.date

        let existingEvents = eventPersistenceService.events(on: day.date)

        switch existingEvents.count {
        case 0:
            presentEventEditorForCreation(on: day.date)
        case 1:
            presentEventEditorForEditing(existingEvents[0])
        default:
            presentDayEvents(on: day.date)
        }
    }

    /// Dismisses the day-events screen.
    func dismissDayEvents() {
        isPresentingDayEvents = false
        dayEventsViewModel = nil
    }

    /// Dismisses the Home-presented event editor.
    ///
    /// Calendar indicators refresh via the reactive ``EventPersistenceService`` catalog.
    func dismissEventEditor() {
        isPresentingEventEditor = false
        eventEditorViewModel = nil
    }

    // MARK: - Private

    /// Presents the day-events list for the given date.
    private func presentDayEvents(on date: Date) {
        dayEventsViewModel = DayEventsViewModel(
            date: date,
            persistenceService: eventPersistenceService
        )
        isPresentingDayEvents = true
    }

    /// Presents the event editor in create mode.
    private func presentEventEditorForCreation(on date: Date) {
        let editor = EventEditorViewModel(
            persistenceService: eventPersistenceService,
            initialDate: date
        )
        editor.prepareForCreation(on: date)
        eventEditorViewModel = editor
        isPresentingEventEditor = true
    }

    /// Presents the event editor in edit mode for a single existing event.
    private func presentEventEditorForEditing(_ event: Event) {
        let editor = EventEditorViewModel(
            persistenceService: eventPersistenceService,
            initialDate: event.date,
            event: event
        )
        eventEditorViewModel = editor
        isPresentingEventEditor = true
    }
}
