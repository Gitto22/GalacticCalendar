//
//  HomeViewModel.swift
//  GalacticCalendar
//

import Foundation

/// Presentation model for the Home screen.
///
/// Owns Home interaction state for day selection and event-editor presentation.
/// Persistence is delegated to ``EventPersistenceService`` through ``EventEditorViewModel``.
@MainActor
@Observable
final class HomeViewModel {

    // MARK: - Dependencies

    /// Persistence façade used to construct the event editor ViewModel.
    private let eventPersistenceService: EventPersistenceService

    // MARK: - State

    /// Absolute date of the currently selected calendar day, if any.
    private(set) var selectedDate: Date?

    /// `true` while the event editor modal is presented.
    var isPresentingEventEditor: Bool = false

    /// ViewModel driving the presented event editor, if any.
    private(set) var eventEditorViewModel: EventEditorViewModel?

    // MARK: - Lifecycle

    /// Creates the Home presentation model.
    /// - Parameter eventPersistenceService: Service injected from the Composition Root.
    init(eventPersistenceService: EventPersistenceService) {
        self.eventPersistenceService = eventPersistenceService
    }

    // MARK: - Intents

    /// Selects an in-month day and presents the event editor for creation.
    /// - Parameter day: Calendar day tapped by the user.
    func selectDay(_ day: CalendarDay) {
        guard day.isCurrentMonth else {
            return
        }

        selectedDate = day.date

        let editor = EventEditorViewModel(
            persistenceService: eventPersistenceService,
            initialDate: day.date
        )
        editor.prepareForCreation(on: day.date)
        eventEditorViewModel = editor
        isPresentingEventEditor = true
    }

    /// Dismisses the event editor without additional persistence side effects.
    func dismissEventEditor() {
        isPresentingEventEditor = false
        eventEditorViewModel = nil
    }
}
