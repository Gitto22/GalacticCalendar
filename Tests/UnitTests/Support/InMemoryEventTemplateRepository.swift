//
//  InMemoryEventTemplateRepository.swift
//  GalacticCalendar
//

import Foundation
@testable import GalacticCalendar

/// Shared in-memory ``EventTemplateRepositoryProtocol`` for unit tests.
@MainActor
final class InMemoryEventTemplateRepository: EventTemplateRepositoryProtocol {

    private var storage: [UUID: EventTemplate]

    init(seed: [EventTemplate] = []) {
        storage = Dictionary(uniqueKeysWithValues: seed.map { ($0.id, $0) })
    }

    func create(_ template: EventTemplate) async throws {
        storage[template.id] = template
    }

    func fetchAll() async throws -> [EventTemplate] {
        Array(storage.values)
    }

    func fetch(by id: UUID) async throws -> EventTemplate? {
        storage[id]
    }

    func update(_ template: EventTemplate) async throws {
        guard storage[template.id] != nil else {
            throw EventTemplateRepositoryError.notFound(template.id)
        }
        storage[template.id] = template
    }

    func delete(_ template: EventTemplate) async throws {
        try await delete(id: template.id)
    }

    func delete(id: UUID) async throws {
        guard storage.removeValue(forKey: id) != nil else {
            throw EventTemplateRepositoryError.notFound(id)
        }
    }

    func duplicate(_ template: EventTemplate) async throws -> EventTemplate {
        let copy = template.duplicated(name: String(localized: "event_template_copy_suffix"))
        try await create(copy)
        return copy
    }
}
