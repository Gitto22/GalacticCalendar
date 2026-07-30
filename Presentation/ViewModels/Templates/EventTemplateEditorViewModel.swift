//
//  EventTemplateEditorViewModel.swift
//  GalacticCalendar
//

import Foundation

/// Create / edit form for an offline ``EventTemplate``.
@MainActor
@Observable
final class EventTemplateEditorViewModel {

    // MARK: - Mode

    enum Mode: Equatable, Sendable {
        case create
        case edit
    }

    // MARK: - Dependencies

    private let templateService: EventTemplateService

    // MARK: - Form

    var name: String = ""
    var title: String = ""
    var description: String = ""
    var isAllDay: Bool = false
    var durationSeconds: TimeInterval = 3_600
    var repeatRule: RepeatRule = .none
    var category: EventCategory = .work
    var tags: [EventTag] = [.preset(.work)]
    var priority: EventPriority = .normal
    var status: EventStatus = .pending
    var color: EventColor = .green

    private(set) var mode: Mode = .create
    private var editingID: UUID?
    private var editingCreatedAt: Date?

    private(set) var isSaving: Bool = false
    private(set) var didCompleteMutation: Bool = false
    private(set) var lastError: EventTemplateRepositoryError?
    private(set) var validationMessage: String?

    // MARK: - Lifecycle

    init(templateService: EventTemplateService) {
        self.templateService = templateService
    }

    var isEditing: Bool { mode == .edit }

    // MARK: - Configuration

    func prepareForCreation() {
        mode = .create
        editingID = nil
        editingCreatedAt = nil
        name = ""
        title = ""
        description = ""
        isAllDay = false
        durationSeconds = 3_600
        repeatRule = .none
        category = .work
        tags = [.preset(.work)]
        priority = .normal
        status = .pending
        color = .green
        validationMessage = nil
        lastError = nil
        didCompleteMutation = false
    }

    func prepareForEditing(_ template: EventTemplate) {
        mode = .edit
        editingID = template.id
        editingCreatedAt = template.createdAt
        name = template.name
        title = template.title
        description = template.description
        isAllDay = template.isAllDay
        durationSeconds = template.durationSeconds
        repeatRule = template.repeatRule
        category = template.category
        tags = template.tags.isEmpty
            ? (EventTagPreset.from(category: template.category).map { [.preset($0)] } ?? [])
            : template.tags
        priority = template.priority
        status = template.status
        color = template.color
        validationMessage = nil
        lastError = nil
        didCompleteMutation = false
    }

    // MARK: - Tags

    func toggleTag(_ tag: EventTag) {
        if let index = tags.firstIndex(of: tag) {
            tags.remove(at: index)
        } else {
            tags.append(tag)
        }
        if let first = tags.compactMap(\.preset).first {
            category = first.asCategory
        } else {
            category = .other
        }
    }

    // MARK: - Save

    func save() async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTitle.isEmpty == false else {
            validationMessage = String(localized: "event_validation_title_required")
            return
        }
        validationMessage = nil

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()
        let template = EventTemplate(
            id: editingID ?? UUID(),
            name: trimmedName.isEmpty ? trimmedTitle : trimmedName,
            title: trimmedTitle,
            description: description,
            isAllDay: isAllDay,
            durationSeconds: max(60, durationSeconds),
            repeatRule: repeatRule,
            category: category,
            tags: tags,
            priority: priority,
            status: status,
            color: color,
            timeZoneIdentifier: nil,
            createdAt: editingCreatedAt ?? now,
            updatedAt: now
        )

        isSaving = true
        defer { isSaving = false }

        do {
            switch mode {
            case .create:
                try await templateService.create(template)
            case .edit:
                try await templateService.update(template)
            }
            didCompleteMutation = true
            lastError = nil
        } catch let error as EventTemplateRepositoryError {
            lastError = error
        } catch {
            lastError = .saveFailed
        }
    }

    func clearLastError() {
        lastError = nil
    }

    var errorAlertMessage: String? {
        guard let lastError else {
            return nil
        }
        switch lastError {
        case .corruptData:
            return String(localized: "event_template_error_corrupt_data")
        case .notFound, .saveFailed:
            return String(localized: "event_template_error_save_failed")
        }
    }

    /// Duration presets offered by the editor (minutes → seconds).
    static let durationPresets: [(labelKey: String, seconds: TimeInterval)] = [
        ("event_template_duration_30m", 1_800),
        ("event_template_duration_1h", 3_600),
        ("event_template_duration_2h", 7_200),
        ("event_template_duration_all_day", 86_400)
    ]
}
