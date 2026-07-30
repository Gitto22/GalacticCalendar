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
/// - Open create-from-template and template management.
/// - Quick ops: duplicate / move / copy / delete via ``EventPersistenceService``.
///
/// ## Sync
/// ``events`` is derived from the reactive catalog; no manual reload token is required.
@MainActor
@Observable
final class DayEventsViewModel {

    // MARK: - Dependencies

    /// Reactive event catalog (single source of truth).
    private let persistenceService: EventPersistenceService

    /// Offline event templates façade.
    private let templateService: EventTemplateService?

    /// Optional shared search state (Sprint 6.7).
    private var searchViewModel: EventSearchViewModel?

    // MARK: - State

    /// Calendar day whose events are listed.
    private(set) var date: Date

    /// Last persistence failure mapped for presentation.
    private(set) var lastError: EventPersistenceError?

    /// `true` while the event editor modal is presented from this screen.
    var isPresentingEventEditor: Bool = false

    /// ViewModel driving the nested event editor, if any.
    private(set) var eventEditorViewModel: EventEditorViewModel?

    /// `true` while the template picker is presented.
    var isPresentingTemplatePicker: Bool = false

    /// ViewModel driving the template picker, if any.
    private(set) var templatePickerViewModel: EventTemplatePickerViewModel?

    /// `true` while the templates manager is presented.
    var isPresentingTemplates: Bool = false

    /// ViewModel driving template management, if any.
    private(set) var templatesViewModel: EventTemplatesViewModel?

    /// `true` while the shared move/copy schedule sheet is presented.
    var isPresentingQuickSchedule: Bool = false

    /// Active quick schedule operation, if any.
    private(set) var quickScheduleOperation: EventQuickDateOperation?

    /// Event targeted by the quick schedule sheet (presentation snapshot).
    private(set) var quickScheduleEvent: Event?

    /// Date/time selected in the quick schedule sheet.
    var quickScheduleDate: Date = Date()

    // MARK: - Lifecycle

    /// Creates a day-events ViewModel.
    /// - Parameters:
    ///   - date: Day to list.
    ///   - persistenceService: Reactive event catalog.
    ///   - templateService: Optional offline templates façade.
    ///   - searchViewModel: Optional shared search criteria.
    init(
        date: Date,
        persistenceService: EventPersistenceService,
        templateService: EventTemplateService? = nil,
        searchViewModel: EventSearchViewModel? = nil
    ) {
        self.date = date
        self.persistenceService = persistenceService
        self.templateService = templateService
        self.searchViewModel = searchViewModel
    }

    /// Updates the bound search ViewModel (e.g. after Home presents search).
    func bindSearch(_ searchViewModel: EventSearchViewModel?) {
        self.searchViewModel = searchViewModel
    }

    // MARK: - Derived Events

    /// Events for ``date`` from the reactive catalog (all-day first, then timed).
    ///
    /// Includes multi-day spans and **dynamically expanded** recurrence
    /// occurrences (no physical copies in SwiftData).
    /// Access tracks ``EventPersistenceService/events`` so the list updates automatically.
    var events: [Event] {
        _ = persistenceService.eventsRevision
        if let searchViewModel {
            _ = searchViewModel.criteria
            _ = searchViewModel.appliesToCalendar
        }
        let criteria = searchViewModel?.calendarCriteria ?? EventSearchCriteria()
        if criteria.isEmpty {
            return persistenceService.events(on: date)
        }
        return persistenceService.events(on: date, matching: criteria)
    }

    /// All-day events for the focused day (leading section in the list).
    var allDayEvents: [Event] {
        events.filter(\.isAllDay)
    }

    /// Timed events for the focused day (trailing section in the list).
    var timedEvents: [Event] {
        events.filter { $0.isAllDay == false }
    }

    /// `true` when template actions can be offered.
    var canUseTemplates: Bool {
        templateService != nil
    }

    // MARK: - Day Focus

    /// Retargets the list to another calendar day (smart selection / navigation).
    /// - Parameter date: New day to list.
    func updateDate(_ date: Date) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let currentStart = calendar.startOfDay(for: self.date)
        guard dayStart != currentStart else {
            return
        }
        self.date = dayStart
    }

    // MARK: - Editor

    /// Presents the editor to create a new event on this day.
    func presentNewEvent() {
        guard persistenceService.isWritable else {
            lastError = .storeUnavailable
            return
        }
        let editor = EventEditorViewModel(
            persistenceService: persistenceService,
            templateService: templateService,
            initialDate: date
        )
        editor.prepareForCreation(on: date)
        eventEditorViewModel = editor
        isPresentingEventEditor = true
    }

    /// Presents the template picker for create-from-template.
    func presentCreateFromTemplate() {
        guard persistenceService.isWritable else {
            lastError = .storeUnavailable
            return
        }
        guard let templateService else {
            return
        }
        templatePickerViewModel = EventTemplatePickerViewModel(templateService: templateService)
        isPresentingTemplatePicker = true
    }

    /// Applies a selected template and opens the event editor in create mode.
    /// - Parameter template: Blueprint to materialize on ``date``.
    func applyTemplate(_ template: EventTemplate) {
        guard persistenceService.isWritable else {
            lastError = .storeUnavailable
            return
        }
        dismissTemplatePicker()
        let editor = EventEditorViewModel(
            persistenceService: persistenceService,
            templateService: templateService,
            initialDate: date
        )
        editor.prepareForCreation(from: template, on: date)
        eventEditorViewModel = editor
        isPresentingEventEditor = true
    }

    /// Presents the templates management screen.
    func presentTemplatesManager() {
        guard persistenceService.isWritable else {
            lastError = .storeUnavailable
            return
        }
        guard let templateService else {
            return
        }
        templatesViewModel = EventTemplatesViewModel(templateService: templateService)
        isPresentingTemplates = true
    }

    /// Presents the editor to edit an existing event.
    /// - Parameter event: Event to edit.
    func presentEdit(for event: Event) {
        guard persistenceService.isWritable else {
            lastError = .storeUnavailable
            return
        }
        let editor = EventEditorViewModel(
            persistenceService: persistenceService,
            templateService: templateService,
            initialDate: event.date,
            event: resolveMasterSnapshot(for: event)
        )
        eventEditorViewModel = editor
        isPresentingEventEditor = true
    }

    /// Duplicates onto the focused day (new identity; status reset; relative reminder).
    func duplicate(_ event: Event) async {
        guard persistenceService.isWritable else {
            lastError = .storeUnavailable
            return
        }
        do {
            try await persistenceService.duplicate(event, onto: date)
            lastError = nil
        } catch let error as EventPersistenceError {
            lastError = error
        } catch {
            lastError = .unknown
        }
    }

    /// Opens the move / reprogram sheet for ``event``.
    func presentMove(_ event: Event) {
        guard persistenceService.isWritable else {
            lastError = .storeUnavailable
            return
        }
        quickScheduleOperation = .move
        quickScheduleEvent = event
        quickScheduleDate = event.date
        isPresentingQuickSchedule = true
    }

    /// Opens the copy-to-date sheet for ``event``.
    func presentCopy(_ event: Event) {
        guard persistenceService.isWritable else {
            lastError = .storeUnavailable
            return
        }
        quickScheduleOperation = .copy
        quickScheduleEvent = event
        quickScheduleDate = event.date
        isPresentingQuickSchedule = true
    }

    /// Confirms the active move or copy operation.
    func confirmQuickSchedule() async {
        guard persistenceService.isWritable else {
            lastError = .storeUnavailable
            return
        }
        guard let operation = quickScheduleOperation,
              let event = quickScheduleEvent else {
            dismissQuickSchedule()
            return
        }

        do {
            switch operation {
            case .move:
                try await persistenceService.move(event, to: normalizedQuickScheduleDate(for: event))
            case .copy:
                try await persistenceService.copy(event, to: normalizedQuickScheduleDate(for: event))
            }
            lastError = nil
            dismissQuickSchedule()
        } catch let error as EventPersistenceError {
            lastError = error
        } catch {
            lastError = .unknown
        }
    }

    /// Dismisses the quick schedule sheet.
    func dismissQuickSchedule() {
        isPresentingQuickSchedule = false
        quickScheduleOperation = nil
        quickScheduleEvent = nil
    }

    /// Dismisses the nested event editor.
    func dismissEventEditor() {
        isPresentingEventEditor = false
        eventEditorViewModel = nil
    }

    /// Dismisses the template picker.
    func dismissTemplatePicker() {
        isPresentingTemplatePicker = false
        templatePickerViewModel = nil
    }

    /// Dismisses the templates manager.
    func dismissTemplatesManager() {
        isPresentingTemplates = false
        templatesViewModel = nil
    }

    /// Clears ``lastError`` after the user dismisses an alert.
    func clearLastError() {
        lastError = nil
    }

    /// Localized message for ``lastError``, when present.
    var errorAlertMessage: String? {
        guard let lastError else {
            return nil
        }
        return EventEditorDisplayNames.message(for: lastError)
    }

    // MARK: - Mutations

    /// Deletes an event via the reactive persistence façade.
    /// - Parameter event: Event to delete.
    func delete(_ event: Event) async {
        guard persistenceService.isWritable else {
            lastError = .storeUnavailable
            return
        }
        do {
            try await persistenceService.delete(event)
        } catch let error as EventPersistenceError {
            lastError = error
        } catch {
            lastError = .unknown
        }
    }

    // MARK: - Private

    /// Prefers the persisted master when editing so occurrence dates are not saved.
    private func resolveMasterSnapshot(for event: Event) -> Event {
        persistenceService.event(id: event.id) ?? event
    }

    /// All-day picks use start-of-day; timed picks keep the sheet date/time.
    private func normalizedQuickScheduleDate(for event: Event) -> Date {
        guard event.isAllDay else {
            return quickScheduleDate
        }
        return EventSchedule.start(
            onDay: quickScheduleDate,
            timeFrom: event.date,
            isAllDay: true,
            timeZoneIdentifier: event.timeZoneIdentifier
        )
    }
}
