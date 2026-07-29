//
//  DayEventsViewModel.swift
//  GalacticCalendar
//

import Foundation

/// ViewModel for the day events list screen.
///
/// ## Responsibilities
/// - Expose the day's events from ``EventPersistenceService`` (SSOT).
/// - Open create/edit flows via ``EventEditorViewModel``.
/// - Duplicate / delete through the persistence façade.
///
/// ## Sync
/// ``events`` is derived from the reactive catalog; no manual reload token is required.
@MainActor
@Observable
final class DayEventsViewModel {

    // MARK: - Dependencies

    /// Reactive event catalog (single source of truth).
    private let persistenceService: EventPersistenceService

    // MARK: - State

    /// Calendar day whose events are listed.
    private(set) var date: Date

    /// Last persistence failure mapped for presentation.
    private(set) var lastError: EventPersistenceError?

    /// `true` while the event editor modal is presented from this screen.
    var isPresentingEventEditor: Bool = false

    /// ViewModel driving the nested event editor, if any.
    private(set) var eventEditorViewModel: EventEditorViewModel?

    // MARK: - Lifecycle

    /// Creates a day-events ViewModel.
    /// - Parameters:
    ///   - date: Day to list.
    ///   - persistenceService: Reactive event catalog.
    init(date: Date, persistenceService: EventPersistenceService) {
        self.date = date
        self.persistenceService = persistenceService
    }

    // MARK: - Derived Events

    /// Events for ``date`` from the reactive catalog, sorted by time.
    ///
    /// Access tracks ``EventPersistenceService/events`` so the list updates automatically.
    var events: [Event] {
        _ = persistenceService.eventsRevision
        return persistenceService.events(on: date)
    }

    // MARK: - Editor

    /// Presents the editor to create a new event on this day.
    func presentNewEvent() {
        let editor = EventEditorViewModel(
            persistenceService: persistenceService,
            initialDate: date
        )
        editor.prepareForCreation(on: date)
        eventEditorViewModel = editor
        isPresentingEventEditor = true
    }

    /// Presents the editor to edit an existing event.
    /// - Parameter event: Event to edit.
    func presentEdit(for event: Event) {
        let editor = EventEditorViewModel(
            persistenceService: persistenceService,
            initialDate: event.date,
            event: event
        )
        eventEditorViewModel = editor
        isPresentingEventEditor = true
    }

    /// Dismisses the nested event editor.
    func dismissEventEditor() {
        isPresentingEventEditor = false
        eventEditorViewModel = nil
    }

    // MARK: - Mutations

    /// Duplicates an event via the reactive persistence façade.
    /// - Parameter event: Source event.
    func duplicate(_ event: Event) async {
        do {
            try await persistenceService.duplicate(event)
        } catch let error as EventPersistenceError {
            lastError = error
        } catch {
            lastError = .unknown
        }
    }

    /// Deletes an event via the reactive persistence façade.
    /// - Parameter event: Event to delete.
    func delete(_ event: Event) async {
        do {
            try await persistenceService.delete(event)
        } catch let error as EventPersistenceError {
            lastError = error
        } catch {
            lastError = .unknown
        }
    }
}
