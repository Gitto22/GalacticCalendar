//
//  EventTemplatesViewModel.swift
//  GalacticCalendar
//

import Foundation

/// Presentation model for the event-templates management list.
///
/// ## Responsibilities
/// - Mirror ``EventTemplateService`` for Observation-driven UI.
/// - Create / edit / delete / duplicate templates.
/// - Present ``EventTemplateEditorViewModel`` for from-scratch edits.
@MainActor
@Observable
final class EventTemplatesViewModel {

    // MARK: - Dependencies

    private let templateService: EventTemplateService

    // MARK: - State

    /// `true` while the nested template editor is presented.
    var isPresentingEditor: Bool = false

    /// Nested editor ViewModel, if any.
    private(set) var editorViewModel: EventTemplateEditorViewModel?

    /// Last mutation failure for alerts.
    private(set) var lastError: EventTemplateRepositoryError?

    // MARK: - Lifecycle

    init(templateService: EventTemplateService) {
        self.templateService = templateService
    }

    // MARK: - Derived

    /// Templates sorted by name (tracks service revision).
    var templates: [EventTemplate] {
        _ = templateService.templatesRevision
        return templateService.templates
    }

    // MARK: - Bootstrap

    func bootstrap() async {
        do {
            try await templateService.refresh()
            lastError = nil
        } catch let error as EventTemplateRepositoryError {
            lastError = error
        } catch {
            lastError = .saveFailed
        }
    }

    // MARK: - Editor

    func presentCreate() {
        let editor = EventTemplateEditorViewModel(templateService: templateService)
        editor.prepareForCreation()
        editorViewModel = editor
        isPresentingEditor = true
    }

    func presentEdit(_ template: EventTemplate) {
        let editor = EventTemplateEditorViewModel(templateService: templateService)
        editor.prepareForEditing(template)
        editorViewModel = editor
        isPresentingEditor = true
    }

    func dismissEditor() {
        isPresentingEditor = false
        editorViewModel = nil
    }

    // MARK: - Mutations

    func duplicate(_ template: EventTemplate) async {
        do {
            _ = try await templateService.duplicate(template)
            lastError = nil
        } catch let error as EventTemplateRepositoryError {
            lastError = error
        } catch {
            lastError = .saveFailed
        }
    }

    func delete(_ template: EventTemplate) async {
        do {
            try await templateService.delete(id: template.id)
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
}
