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
/// - Own schedule composition (day, start/end time or all-day, time zone).
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

    /// Optional offline templates façade (save-as-template).
    private let templateService: EventTemplateService?

    /// Service used to validate event drafts before persistence.
    private let validationService: EventValidationService

    // MARK: - Form Fields

    /// User-facing event title.
    var title: String = ""

    /// User-facing event description / notes.
    var description: String = ""

    /// Start date and time of the event.
    ///
    /// When the start changes, ``reminder`` is recomputed. For timed events,
    /// ``endDate`` keeps the previous duration (including multi-day spans).
    /// For all-day events, day bounds are re-normalized while preserving the
    /// end calendar day when it remains on or after the start.
    var date: Date = Date() {
        didSet {
            guard isHydratingForm == false else {
                return
            }
            if isAllDay {
                if endDate < date {
                    isHydratingForm = true
                    endDate = date
                    isHydratingForm = false
                }
                applyAllDayBounds(cachingTimedValues: false)
            } else {
                let previousDuration = endDate.timeIntervalSince(oldValue)
                let duration = previousDuration > 0 ? previousDuration : Self.defaultDuration
                isHydratingForm = true
                endDate = date.addingTimeInterval(duration)
                isHydratingForm = false
            }
            reminder = reminderOption.reminderDate(relativeTo: date)
        }
    }

    /// End date and time of the event.
    ///
    /// Never allowed to fall before ``date``; clamped automatically for the editor.
    var endDate: Date = Date() {
        didSet {
            guard isHydratingForm == false else {
                return
            }
            if endDate < date {
                isHydratingForm = true
                endDate = date
                isHydratingForm = false
            }
            if isAllDay {
                applyAllDayBounds(cachingTimedValues: false)
            }
        }
    }

    /// Start date alias used by multi-day editor APIs (same storage as ``date``).
    var startDate: Date {
        get { date }
        set { date = newValue }
    }

    /// `true` when the draft spans more than one calendar day.
    var isMultiDay: Bool {
        EventSchedule.spansMultipleCalendarDays(
            date: date,
            endDate: endDate,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }

    /// `true` when the draft is an all-day event (hides time pickers in the view).
    var isAllDay: Bool = false {
        didSet {
            guard isHydratingForm == false else {
                return
            }
            guard isAllDay != oldValue else {
                return
            }
            if isAllDay {
                applyAllDayBounds(cachingTimedValues: true)
            } else {
                restoreTimedDefaultsIfNeeded()
            }
            reminder = reminderOption.reminderDate(relativeTo: date)
        }
    }

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

    /// Recurrence rule applied to the event (frequency only; end lives in end-kind fields).
    var repeatRule: RepeatRule = .none {
        didSet {
            guard isHydratingForm == false else {
                return
            }
            if repeatRule.isRecurring == false {
                recurrenceEndKind = .never
            }
        }
    }

    /// How the recurrence series ends (editor UI).
    var recurrenceEndKind: RecurrenceEndKind = .never

    /// Occurrence count when ``recurrenceEndKind`` is ``RecurrenceEndKind/afterCount``.
    var recurrenceEndCount: Int = 10

    /// End date when ``recurrenceEndKind`` is ``RecurrenceEndKind/onDate``.
    var recurrenceEndDate: Date = Date()

    /// Selected event category (legacy single-value; synced from tags).
    var category: EventCategory = .work

    /// Selected organization tags (multiple presets allowed).
    var tags: [EventTag] = [.preset(.work)]

    /// Selected event priority.
    var priority: EventPriority = .high

    /// Selected event status.
    var status: EventStatus = .pending

    /// Selected event color token.
    var color: EventColor = .green

    /// Preset tags available in the editor (custom tags reserved for later).
    var selectableTagPresets: [EventTagPreset] {
        EventTagPreset.allCases
    }

    /// `true` when ``preset`` is currently selected.
    func isTagSelected(_ preset: EventTagPreset) -> Bool {
        tags.contains(.preset(preset))
    }

    /// Toggles a preset tag and syncs ``category`` from the first remaining preset.
    func toggleTag(_ preset: EventTagPreset) {
        let tag = EventTag.preset(preset)
        if let index = tags.firstIndex(of: tag) {
            tags.remove(at: index)
        } else {
            tags.append(tag)
        }
        syncCategoryFromTags()
    }

    /// Syncs legacy ``category`` from the first selected preset tag.
    private func syncCategoryFromTags() {
        if let first = tags.compactMap(\.preset).first {
            category = first.asCategory
        } else {
            category = .other
        }
    }

    // MARK: - Editor Metadata

    /// Whether the editor is in create or edit mode.
    private(set) var mode: EventEditorMode = .create

    /// Identifier of the event loaded for editing, if any.
    private(set) var editingEventID: UUID?

    /// Original `createdAt` value preserved while editing.
    private var editingCreatedAt: Date?

    /// Timed start retained when toggling all-day on (restored on toggle off).
    private var cachedTimedDate: Date?

    /// Timed end retained when toggling all-day on (restored on toggle off).
    private var cachedTimedEndDate: Date?

    /// Suppresses schedule side effects while hydrating the form from an ``Event``.
    private var isHydratingForm: Bool = false

    /// Validation issues produced by the latest ``validate()`` call.
    private(set) var validationIssues: [EventValidationIssue] = []

    /// `true` while a persistence operation is running.
    private(set) var isSaving: Bool = false

    /// Last persistence failure mapped for presentation.
    private(set) var lastError: EventPersistenceError?

    /// `true` after a successful create, update, or delete.
    private(set) var didCompleteMutation: Bool = false

    /// `true` after the current draft was saved as a template (non-dismissing feedback).
    private(set) var didSaveAsTemplate: Bool = false

    /// Last template-persistence failure, when present.
    private(set) var lastTemplateError: EventTemplateRepositoryError?

    /// `true` while the create-from-template picker is presented from the editor.
    var isPresentingTemplatePicker: Bool = false

    /// Nested template picker ViewModel, if any.
    private(set) var templatePickerViewModel: EventTemplatePickerViewModel?

    // MARK: - Lifecycle

    /// Creates an event editor view model.
    /// - Parameters:
    ///   - persistenceService: Persistence façade for event CRUD.
    ///   - templateService: Optional templates façade for save-as-template.
    ///   - validationService: Validator for draft events.
    ///   - initialDate: Default start date for a new event draft.
    ///   - event: Optional existing event that puts the editor in edit mode.
    init(
        persistenceService: EventPersistenceService,
        templateService: EventTemplateService? = nil,
        validationService: EventValidationService = EventValidationService(),
        initialDate: Date = Date(),
        event: Event? = nil
    ) {
        self.persistenceService = persistenceService
        self.templateService = templateService
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
        isAllDay = false
        self.date = date
        endDate = date.addingTimeInterval(Self.defaultDuration)
        timeZoneIdentifier = TimeZone.current.identifier
        reminderOption = .fifteenMinutes
    }

    /// Prepares create mode by applying an ``EventTemplate`` (no absolute dates / reminders).
    /// - Parameters:
    ///   - template: Blueprint whose content fields are copied into the form.
    ///   - date: Schedule anchor for the new event (device calendar day / start).
    func prepareForCreation(from template: EventTemplate, on date: Date = Date()) {
        reset()
        mode = .create
        didSaveAsTemplate = false
        lastTemplateError = nil

        isHydratingForm = true
        title = template.title
        description = template.description
        isAllDay = template.isAllDay
        timeZoneIdentifier = template.timeZoneIdentifier ?? TimeZone.current.identifier
        let bounds = template.scheduleBounds(on: date, timeZoneIdentifier: timeZoneIdentifier)
        self.date = bounds.date
        endDate = bounds.endDate ?? bounds.date.addingTimeInterval(template.durationSeconds)
        cachedTimedDate = nil
        cachedTimedEndDate = nil
        reminderOption = .fifteenMinutes
        reminder = reminderOption.reminderDate(relativeTo: self.date)
        repeatRule = RepeatRule(
            frequency: template.repeatRule.frequency,
            interval: template.repeatRule.interval
        )
        applyRecurrenceEnd(from: template.repeatRule)
        tags = template.tags.isEmpty
            ? (EventTagPreset.from(category: template.category).map { [.preset($0)] } ?? [])
            : template.tags
        category = template.category
        priority = template.priority
        status = template.status
        color = template.color
        isHydratingForm = false
        validationIssues = []
        lastError = nil
        didCompleteMutation = false
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
        isHydratingForm = true
        isAllDay = event.isAllDay
        date = event.date
        endDate = event.endDate ?? event.date.addingTimeInterval(Self.defaultDuration)
        if event.isAllDay {
            let bounds = EventSchedule.normalizeAllDay(
                start: event.date,
                end: event.endDate,
                timeZoneIdentifier: event.timeZoneIdentifier
            )
            date = bounds.date
            endDate = bounds.endDate
        }
        cachedTimedDate = nil
        cachedTimedEndDate = nil
        isHydratingForm = false
        reminderOption = EventReminderOption.option(for: event.reminder, eventDate: date)
        isHydratingForm = true
        repeatRule = RepeatRule(
            frequency: event.repeatRule.frequency,
            interval: event.repeatRule.interval
        )
        applyRecurrenceEnd(from: event.repeatRule)
        isHydratingForm = false
        tags = event.tags.isEmpty
            ? (EventTagPreset.from(category: event.category).map { [.preset($0)] } ?? [])
            : event.tags
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

    // MARK: - Templates

    /// Persists the current draft as a new offline ``EventTemplate`` (no reminders).
    /// - Parameter name: Optional template display name; defaults to the event title.
    @discardableResult
    func saveCurrentAsTemplate(name: String? = nil) async -> EventTemplate? {
        guard let templateService else {
            lastTemplateError = .saveFailed
            return nil
        }
        didSaveAsTemplate = false
        lastTemplateError = nil
        let draft = makeDraftEvent()
        do {
            let template = try await templateService.saveEventAsTemplate(draft, name: name)
            didSaveAsTemplate = true
            return template
        } catch let error as EventTemplateRepositoryError {
            lastTemplateError = error
            return nil
        } catch {
            lastTemplateError = .saveFailed
            return nil
        }
    }

    /// Clears template feedback after the user dismisses UI.
    func clearTemplateFeedback() {
        didSaveAsTemplate = false
        lastTemplateError = nil
    }

    /// `true` when create-from-template / save-as-template can be offered.
    var canUseTemplates: Bool {
        templateService != nil
    }

    /// Opens the template picker (create mode only).
    func presentTemplatePicker() {
        guard mode == .create, let templateService else {
            return
        }
        templatePickerViewModel = EventTemplatePickerViewModel(templateService: templateService)
        isPresentingTemplatePicker = true
    }

    /// Dismisses the template picker without applying.
    func dismissTemplatePicker() {
        isPresentingTemplatePicker = false
        templatePickerViewModel = nil
    }

    /// Applies a template into the current create form (keeps the editor's schedule anchor day).
    func applyTemplate(_ template: EventTemplate) {
        let anchor = date
        dismissTemplatePicker()
        prepareForCreation(from: template, on: anchor)
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
        cachedTimedDate = nil
        cachedTimedEndDate = nil
        isAllDay = false
        date = Date()
        endDate = date.addingTimeInterval(Self.defaultDuration)
        reminderOption = .fifteenMinutes
        reminder = reminderOption.reminderDate(relativeTo: date)
        repeatRule = .none
        recurrenceEndKind = .never
        recurrenceEndCount = 10
        recurrenceEndDate = Date()
        tags = [.preset(.work)]
        category = .work
        priority = .high
        status = .pending
        color = .green
        validationIssues = []
        lastError = nil
        lastTemplateError = nil
        didSaveAsTemplate = false
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

    /// Localized message for ``lastTemplateError``.
    var templateErrorAlertMessage: String {
        switch lastTemplateError {
        case .corruptData:
            String(localized: "event_template_error_corrupt_data")
        case .notFound, .saveFailed, .none:
            String(localized: "event_template_error_save_failed")
        }
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

    /// Default wall-clock hour used when leaving all-day mode without a cache.
    private static let defaultTimedStartHour: Int = 9

    /// Builds a Domain ``Event`` snapshot from the current form state.
    private func makeDraftEvent() -> Event {
        let now = Date()
        let bounds = EventSchedule.normalizedBounds(
            isAllDay: isAllDay,
            date: date,
            endDate: endDate,
            timeZoneIdentifier: timeZoneIdentifier
        )
        let resolvedReminder = reminderOption.reminderDate(relativeTo: bounds.date)
        return Event(
            id: editingEventID ?? UUID(),
            title: title,
            description: description,
            date: bounds.date,
            endDate: bounds.endDate,
            isAllDay: isAllDay,
            timeZoneIdentifier: timeZoneIdentifier,
            reminder: resolvedReminder,
            repeatRule: composedRepeatRule(),
            category: category,
            tags: tags,
            priority: priority,
            status: status,
            color: color,
            createdAt: editingCreatedAt ?? now,
            updatedAt: now
        )
    }

    /// Combines frequency presets with the editor end-kind fields.
    private func composedRepeatRule() -> RepeatRule {
        guard repeatRule.isRecurring else {
            return .none
        }
        switch recurrenceEndKind {
        case .never:
            return RepeatRule(frequency: repeatRule.frequency, interval: repeatRule.interval)
        case .afterCount:
            return RepeatRule(
                frequency: repeatRule.frequency,
                interval: repeatRule.interval,
                occurrenceCount: max(1, recurrenceEndCount)
            )
        case .onDate:
            return RepeatRule(
                frequency: repeatRule.frequency,
                interval: repeatRule.interval,
                endDate: max(recurrenceEndDate, date)
            )
        }
    }

    /// Hydrates end-kind fields from a persisted rule.
    private func applyRecurrenceEnd(from rule: RepeatRule) {
        if let count = rule.occurrenceCount {
            recurrenceEndKind = .afterCount
            recurrenceEndCount = count
            recurrenceEndDate = date.addingTimeInterval(86_400 * 30)
        } else if let endDate = rule.endDate {
            recurrenceEndKind = .onDate
            recurrenceEndDate = endDate
            recurrenceEndCount = 10
        } else {
            recurrenceEndKind = .never
            recurrenceEndCount = 10
            recurrenceEndDate = date.addingTimeInterval(86_400 * 30)
        }
    }

    /// Clamps ``date`` / ``endDate`` to all-day day bounds (supports multi-day).
    /// - Parameter cachingTimedValues: When `true`, remembers the prior timed range.
    private func applyAllDayBounds(cachingTimedValues: Bool) {
        if cachingTimedValues, cachedTimedDate == nil {
            cachedTimedDate = date
            cachedTimedEndDate = endDate
        }
        let bounds = EventSchedule.normalizeAllDay(
            start: date,
            end: endDate,
            timeZoneIdentifier: timeZoneIdentifier
        )
        isHydratingForm = true
        date = bounds.date
        endDate = bounds.endDate
        isHydratingForm = false
    }

    /// Restores timed start/end after leaving all-day mode.
    private func restoreTimedDefaultsIfNeeded() {
        isHydratingForm = true
        defer { isHydratingForm = false }

        if let cachedTimedDate, let cachedTimedEndDate {
            date = cachedTimedDate
            endDate = cachedTimedEndDate
            self.cachedTimedDate = nil
            self.cachedTimedEndDate = nil
            return
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current
        let dayStart = calendar.startOfDay(for: date)
        let timedStart =
            calendar.date(
                bySettingHour: Self.defaultTimedStartHour,
                minute: 0,
                second: 0,
                of: dayStart
            )
            ?? dayStart.addingTimeInterval(TimeInterval(Self.defaultTimedStartHour * 3_600))
        date = timedStart
        endDate = timedStart.addingTimeInterval(Self.defaultDuration)
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
