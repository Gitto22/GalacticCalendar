//
//  EventTemplateService.swift
//  GalacticCalendar
//

import Foundation

/// Application façade for event-template CRUD (no reminders / no event catalog).
@MainActor
@Observable
final class EventTemplateService {

    // MARK: - State

    /// In-memory list sorted by name (Observation SSOT for template UIs).
    private(set) var templates: [EventTemplate] = []

    /// Monotonic revision for Observation consumers.
    private(set) var templatesRevision: Int = 0

    private(set) var lastError: EventTemplateRepositoryError?

    // MARK: - Dependencies

    private let repository: EventTemplateRepositoryProtocol

    /// Reads current store availability from the Composition Root.
    private let storageAvailabilityProvider: () -> StorageAvailability

    // MARK: - Lifecycle

    init(
        repository: EventTemplateRepositoryProtocol,
        storageAvailabilityProvider: @escaping () -> StorageAvailability = { .available }
    ) {
        self.repository = repository
        self.storageAvailabilityProvider = storageAvailabilityProvider
    }

    // MARK: - Catalog Reload

    /// Reloads templates from the repository and publishes to observers.
    ///
    /// Used for first load and after mutations. (Former public `bootstrap()` removed in PB-05.3.)
    func refresh() async throws {
        do {
            templates = try await repository.fetchAll().sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            templatesRevision += 1
            lastError = nil
        } catch let error as EventTemplateRepositoryError {
            lastError = error
            throw error
        } catch {
            lastError = .saveFailed
            throw EventTemplateRepositoryError.saveFailed
        }
    }

    // MARK: - CRUD

    func create(_ template: EventTemplate) async throws {
        try ensureWritable()
        try await repository.create(template)
        try await refresh()
    }

    func update(_ template: EventTemplate) async throws {
        try ensureWritable()
        try await repository.update(template)
        try await refresh()
    }

    func delete(id: UUID) async throws {
        try ensureWritable()
        try await repository.delete(id: id)
        try await refresh()
    }

    func duplicate(_ template: EventTemplate) async throws -> EventTemplate {
        try ensureWritable()
        let copy = try await repository.duplicate(template)
        try await refresh()
        return copy
    }

    /// Saves a snapshot of an existing event as a new template.
    func saveEventAsTemplate(_ event: Event, name: String? = nil) async throws -> EventTemplate {
        try ensureWritable()
        let template = EventTemplate.from(event: event, name: name)
        try await create(template)
        return template
    }

    // MARK: - Private

    private func ensureWritable() throws {
        guard storageAvailabilityProvider().allowsWrites else {
            PersistenceLog.writeBlocked(operation: "EventTemplateService")
            lastError = .saveFailed
            throw EventTemplateRepositoryError.saveFailed
        }
    }
}
