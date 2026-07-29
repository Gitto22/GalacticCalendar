//
//  EventEditorViewModel.swift
//  GalacticCalendar
//

import Foundation

/// Describes whether the editor is creating or updating an event.
enum EventEditorMode: Equatable, Sendable {

    // MARK: - Cases

    /// The editor creates a brand-new event.
    case create

    /// The editor updates an event that already exists in persistence.
    case edit
}

/// ViewModel that owns all business logic for the event create/edit popup.
///
/// ## Responsibilities
/// - Expose editable event fields to SwiftUI through Observation (`@Observable`).
/// - Own schedule composition (day, start time, end time, time zone).
/// - Validate drafts via ``EventValidationService``.
/// - Persist create/update/delete operations via ``EventPersistenceService``.
///
/// ## Non-responsibilities
/// - No SwiftUI views.
/// - No direct SwiftData access.
/// - No direct ``EventEntity`` access.
@MainActor
@Observable
final class EventEditorViewModel {

    // MARK: - Dependencies

    /// Service used to create, update, delete, and fetch events.
    private let persistenceService: EventPersistenceService

    /// Service used to validate event drafts before persistence.
    private let validationService: EventValidationService

    // MARK: - Form Fields

    /// User-facing event title.
    var title: String = ""

    /// User-facing event description / notes.
    var description: String = ""

    /// Start date and time of the event.
    ///
    /// When the start changes, ``reminder`` is recomputed and ``endDate`` keeps
    /// the previous duration relative to the start.
    var date: Date = Date() {
        didSet {
            let previousDuration = endDate.timeIntervalSince(oldValue)
            let duration = previousDuration > 0 ? previousDuration : Self.defaultDuration
            endDate = date.addingTimeInterval(duration)
            reminder = reminderOption.reminderDate(relativeTo: date)
        }
    }

    /// End date and time of the event.
    var endDate: Date = Date()

    /// IANA time zone identifier used while editing the schedule.
    var timeZoneIdentifier: String = TimeZone.current.identifier

    /// Reminder offset selected in the editor UI.
    ///
    /// Keeps ``reminder`` synchronized as an absolute fire date.
    var reminderOption: EventReminderOption = .fifteenMinutes {
        didSet {
            reminder = reminderOption.reminderDate(relativeTo: date)
        }
    }

    /// Optional reminder fire date derived from ``reminderOption``.
    private(set) var reminder: Date?

    /// Recurrence rule applied to the event.
    var repeatRule: RepeatRule = .none

    /// Selected event category.
    var category: EventCategory = .work

    /// Selected event priority.
    var priority: EventPriority = .high

    /// Selected event status.
    var status: EventStatus = .pending

    /// Selected event color token.
    var color: EventColor = .green

    // MARK: - Editor Metadata

    /// Whether the editor is in create or edit mode.
    private(set) var mode: EventEditorMode = .create

    /// Identifier of the event loaded for editing, if any.
    private(set) var editingEventID: UUID?

    /// Original `createdAt` value preserved while editing.
    private var editingCreatedAt: Date?

    /// Validation issues produced by the latest ``validate()`` call.
    private(set) var validationIssues: [EventValidationIssue] = []

    /// `true` while a persistence operation is running.
    private(set) var isSaving: Bool = false

    /// Last persistence failure mapped for presentation.
    private(set) var lastError: EventPersistenceError?

    /// `true` after a successful create, update, or delete.
    private(set) var didCompleteMutation: Bool = false

    // MARK: - Lifecycle

    /// Creates an event editor view model.
    /// - Parameters:
    ///   - persistenceService: Persistence façade for event CRUD.
    ///   - validationService: Validator for draft events.
    ///   - initialDate: Default start date for a new event draft.
    ///   - event: Optional existing event that puts the editor in edit mode.
    init(
        persistenceService: EventPersistenceService,
        validationService: EventValidationService = EventValidationService(),
        initialDate: Date = Date(),
        event: Event? = nil
    ) {
        self.persistenceService = persistenceService
        self.validationService = validationService
        self.date = initialDate
        self.endDate = initialDate.addingTimeInterval(Self.defaultDuration)
        self.reminder = EventReminderOption.fifteenMinutes.reminderDate(relativeTo: initialDate)

        if let event {
            prepareForEditing(event)
        }
    }

    // MARK: - Schedule Presentation

    /// Localized display name for the selected time zone.
    var timeZoneDisplayName: String {
        EventTimeZone.displayName(for: timeZoneIdentifier)
    }

    /// Identifiers available in the timezone selector.
    var selectableTimeZoneIdentifiers: [String] {
        var identifiers = EventTimeZone.editorSelectableIdentifiers
        if identifiers.contains(timeZoneIdentifier) == false {
            identifiers.insert(timeZoneIdentifier, at: 0)
        }
        return identifiers
    }

    // MARK: - Mode Configuration

    /// Prepares the ViewModel to create a new event.
    /// - Parameter date: Initial start date assigned to the new event.
    func prepareForCreation(on date: Date = Date()) {
        reset()
        mode = .create
        self.date = date
        endDate = date.addingTimeInterval(Self.defaultDuration)
        timeZoneIdentifier = TimeZone.current.identifier
        reminderOption = .fifteenMinutes
    }

    /// Prepares the ViewModel to edit an existing event.
    /// - Parameter event: Domain event loaded from persistence.
    func prepareForEditing(_ event: Event) {
        mode = .edit
        editingEventID = event.id
        editingCreatedAt = event.createdAt
        title = event.title
        description = event.description
        timeZoneIdentifier = event.timeZoneIdentifier
        date = event.date
        endDate = event.endDate ?? event.date.addingTimeInterval(Self.defaultDuration)
        reminderOption = EventReminderOption.option(for: event.reminder, eventDate: event.date)
        repeatRule = event.repeatRule
        category = event.category
        priority = event.priority
        status = event.status
        color = event.color
        validationIssues = []
        lastError = nil
        didCompleteMutation = false
    }

    // MARK: - Notifications

    /// Requests local-notification permission when still undetermined.
    ///
    /// Authorization request failures are stored on ``lastError``.
    /// - Returns: `true` when notifications may be delivered.
    @discardableResult
    func requestNotificationAuthorizationIfNeeded() async -> Bool {
        do {
            return try await persistenceService.requestNotificationAuthorizationIfNeeded()
        } catch let error as EventPersistenceError {
            lastError = error
            return false
        } catch {
            lastError = .unknown
            return false
        }
    }

    // MARK: - Validation

    /// Validates the current form through ``EventValidationService``.
    @discardableResult
    func validate() -> Bool {
        let draft = makeDraftEvent()
        validationIssues = validationService.validate(draft)
        return validationIssues.isEmpty
    }

    // MARK: - Save

    /// Persists the current draft using create or update based on ``mode``.
    func saveEvent() async {
        switch mode {
        case .create:
            await createEvent()
        case .edit:
            await updateEvent()
        }
    }

    // MARK: - Create

    /// Creates a new event from the current form values.
    func createEvent() async {
        guard mode == .create else {
            return
        }

        guard validate() else {
            return
        }

        await performMutation {
            try await persistenceService.create(makeDraftEvent())
        }
    }

    // MARK: - Update

    /// Updates the event currently loaded for editing.
    func updateEvent() async {
        guard mode == .edit, editingEventID != nil else {
            return
        }

        guard validate() else {
            return
        }

        await performMutation {
            try await persistenceService.update(makeDraftEvent())
        }
    }

    // MARK: - Delete

    /// Deletes the event currently loaded for editing.
    func deleteEvent() async {
        guard mode == .edit, let editingEventID else {
            return
        }

        await performMutation {
            try await persistenceService.delete(id: editingEventID)
        }
    }

    // MARK: - Duplicate

    /// Creates a persisted duplicate of the event currently loaded for editing.
    @discardableResult
    func duplicateEvent() async -> Event? {
        guard mode == .edit else {
            return nil
        }

        let source = makeDraftEvent()
        var created: Event?

        await performMutation {
            created = try await persistenceService.duplicate(source)
        }

        return created
    }

    // MARK: - Reset

    /// Resets all form fields and editor metadata to defaults for creation.
    func reset() {
        mode = .create
        editingEventID = nil
        editingCreatedAt = nil
        title = ""
        description = ""
        timeZoneIdentifier = TimeZone.current.identifier
        date = Date()
        endDate = date.addingTimeInterval(Self.defaultDuration)
        reminderOption = .fifteenMinutes
        reminder = reminderOption.reminderDate(relativeTo: date)
        repeatRule = .none
        category = .work
        priority = .high
        status = .pending
        color = .green
        validationIssues = []
        lastError = nil
        isSaving = false
        didCompleteMutation = false
    }

    // MARK: - Derived State

    /// `true` when the latest validation produced one or more issues.
    var hasValidationIssues: Bool {
        validationIssues.isEmpty == false
    }

    /// Localized summary of ``validationIssues`` for inline UI.
    var validationMessage: String {
        EventEditorDisplayNames.validationSummary(for: validationIssues)
    }

    /// Localized message for ``lastError``, when present.
    var errorAlertMessage: String? {
        guard let lastError else {
            return nil
        }
        return EventEditorDisplayNames.message(for: lastError)
    }

    /// `true` when ``lastError`` should be presented as an alert (not inline validation).
    var shouldPresentErrorAlert: Bool {
        guard let lastError else {
            return false
        }
        if case .validationFailed = lastError {
            return false
        }
        return true
    }

    /// `true` when the editor is updating an existing event.
    var isEditing: Bool {
        mode == .edit
    }

    /// Clears ``lastError`` after the user dismisses an alert.
    func clearLastError() {
        lastError = nil
    }

    // MARK: - Private Helpers

    /// Default event duration when no end date is stored (1 hour).
    private static let defaultDuration: TimeInterval = 3_600

    /// Builds a Domain ``Event`` snapshot from the current form state.
    private func makeDraftEvent() -> Event {
        let now = Date()
        let resolvedReminder = reminderOption.reminderDate(relativeTo: date)
        return Event(
            id: editingEventID ?? UUID(),
            title: title,
            description: description,
            date: date,
            endDate: endDate,
            timeZoneIdentifier: timeZoneIdentifier,
            reminder: resolvedReminder,
            repeatRule: repeatRule,
            category: category,
            priority: priority,
            status: status,
            color: color,
            createdAt: editingCreatedAt ?? now,
            updatedAt: now
        )
    }

    /// Executes a persistence mutation with shared loading and error handling.
    private func performMutation(_ operation: () async throws -> Void) async {
        isSaving = true
        lastError = nil
        didCompleteMutation = false
        defer { isSaving = false }

        do {
            try await operation()
            didCompleteMutation = true
        } catch let error as EventPersistenceError {
            lastError = error
            if case .validationFailed(let issues) = error {
                validationIssues = issues
            }
        } catch {
            lastError = .unknown
        }
    }
}
