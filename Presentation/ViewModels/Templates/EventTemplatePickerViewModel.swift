//
//  EventTemplatePickerViewModel.swift
//  GalacticCalendar
//

import Foundation

/// Presentation model for choosing a template when creating an event.
@MainActor
@Observable
final class EventTemplatePickerViewModel {

    // MARK: - Dependencies

    private let templateService: EventTemplateService

    // MARK: - State

    /// `true` while the templates management screen is presented.
    var isPresentingManager: Bool = false

    /// Nested management ViewModel, if any.
    private(set) var templatesViewModel: EventTemplatesViewModel?

    private(set) var lastError: EventTemplateRepositoryError?

    // MARK: - Lifecycle

    init(templateService: EventTemplateService) {
        self.templateService = templateService
    }

    // MARK: - Derived

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

    // MARK: - Manager

    func presentManager() {
        let manager = EventTemplatesViewModel(templateService: templateService)
        templatesViewModel = manager
        isPresentingManager = true
    }

    func dismissManager() {
        isPresentingManager = false
        templatesViewModel = nil
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
