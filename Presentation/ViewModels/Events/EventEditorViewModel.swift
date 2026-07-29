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
/// - Validate drafts via ``EventValidationService``.
/// - Persist create/update/delete operations via ``EventPersistenceService``.
///
/// ## Non-responsibilities
/// - No SwiftUI views.
/// - No direct SwiftData access.
/// - No direct ``EventEntity`` access.
///
/// ## Architecture
/// Lives in the Presentation layer (MVVM) and depends only on Application services,
/// preserving Clean Architecture boundaries.
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

    /// Date and time of the event.
    ///
    /// Required by the Domain ``Event`` model when creating or updating.
    var date: Date = Date()

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
    var repeatRule: EventRepeatRule = .none

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
    ///   - initialDate: Default date for a new event draft.
    init(
        persistenceService: EventPersistenceService,
        validationService: EventValidationService = EventValidationService(),
        initialDate: Date = Date()
    ) {
        self.persistenceService = persistenceService
        self.validationService = validationService
        self.date = initialDate
        self.reminder = EventReminderOption.fifteenMinutes.reminderDate(relativeTo: initialDate)
    }

    // MARK: - Mode Configuration

    /// Prepares the ViewModel to create a new event.
    /// - Parameter date: Initial date assigned to the new event.
    func prepareForCreation(on date: Date = Date()) {
        reset()
        mode = .create
        self.date = date
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
        date = event.date
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

    // MARK: - Validation

    /// Validates the current form through ``EventValidationService``.
    ///
    /// Updates ``validationIssues`` with every detected problem.
    /// - Returns: `true` when the draft is valid; otherwise `false`.
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
    ///
    /// Runs local validation first, then calls ``EventPersistenceService/create(_:)``.
    /// No-ops when the editor is not in ``EventEditorMode/create``.
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
    ///
    /// Runs local validation first, then calls ``EventPersistenceService/update(_:)``.
    /// No-ops when the editor is not in ``EventEditorMode/edit``.
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
    ///
    /// Calls ``EventPersistenceService/delete(id:)``.
    /// No-ops when no editable event is loaded.
    func deleteEvent() async {
        guard mode == .edit, let editingEventID else {
            return
        }

        await performMutation {
            try await persistenceService.delete(id: editingEventID)
        }
    }

    // MARK: - Reset

    /// Resets all form fields and editor metadata to defaults for creation.
    func reset() {
        mode = .create
        editingEventID = nil
        editingCreatedAt = nil
        title = ""
        description = ""
        date = Date()
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

    /// `true` when the editor is updating an existing event.
    var isEditing: Bool {
        mode == .edit
    }

    // MARK: - Private Helpers

    /// Builds a Domain ``Event`` snapshot from the current form state.
    /// - Returns: Draft event ready for validation or persistence.
    private func makeDraftEvent() -> Event {
        let now = Date()
        let resolvedReminder = reminderOption.reminderDate(relativeTo: date)
        return Event(
            id: editingEventID ?? UUID(),
            title: title,
            description: description,
            date: date,
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
    /// - Parameter operation: Async throwing persistence work.
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
