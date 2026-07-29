//
//  DayEventsViewModel.swift
//  GalacticCalendar
//

import Foundation

/// ViewModel for the day events list screen.
///
/// Loads, duplicates, and deletes events for a single calendar day.
/// Create and edit flows are delegated to ``EventEditorViewModel``.
@MainActor
@Observable
final class DayEventsViewModel {

    // MARK: - Dependencies

    /// Persistence façade for event reads and mutations.
    private let persistenceService: EventPersistenceService

    // MARK: - State

    /// Calendar day whose events are listed.
    private(set) var date: Date

    /// Events for ``date``, sorted ascending by time.
    private(set) var events: [Event] = []

    /// `true` while a fetch or mutation is running.
    private(set) var isLoading: Bool = false

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
    ///   - persistenceService: Event persistence entry point.
    init(date: Date, persistenceService: EventPersistenceService) {
        self.date = date
        self.persistenceService = persistenceService
    }

    // MARK: - Loading

    /// Reloads events for ``date`` ordered by hour.
    func loadEvents() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            let fetched = try await persistenceService.fetch(on: date)
            events = fetched.sorted { $0.date < $1.date }
        } catch let error as EventPersistenceError {
            lastError = error
            events = []
        } catch {
            lastError = .unknown
            events = []
        }
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
            initialDate: event.date
        )
        editor.prepareForEditing(event)
        eventEditorViewModel = editor
        isPresentingEventEditor = true
    }

    /// Dismisses the nested event editor and reloads the list when needed.
    func dismissEventEditor() {
        let shouldReload = eventEditorViewModel?.didCompleteMutation == true
        isPresentingEventEditor = false
        eventEditorViewModel = nil

        if shouldReload {
            Task { await loadEvents() }
        }
    }

    // MARK: - Mutations

    /// Duplicates an event as a new persisted copy on the same day.
    /// - Parameter event: Source event.
    func duplicate(_ event: Event) async {
        let copy = Event(
            id: UUID(),
            title: event.title,
            description: event.description,
            date: event.date,
            reminder: event.reminder,
            repeatRule: event.repeatRule,
            category: event.category,
            priority: event.priority,
            status: event.status,
            color: event.color,
            createdAt: Date(),
            updatedAt: Date()
        )

        do {
            try await persistenceService.create(copy)
            await loadEvents()
        } catch let error as EventPersistenceError {
            lastError = error
        } catch {
            lastError = .unknown
        }
    }

    /// Deletes an event from persistence and refreshes the list.
    /// - Parameter event: Event to delete.
    func delete(_ event: Event) async {
        do {
            try await persistenceService.delete(event)
            await loadEvents()
        } catch let error as EventPersistenceError {
            lastError = error
        } catch {
            lastError = .unknown
        }
    }
}
