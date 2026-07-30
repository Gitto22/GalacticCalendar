//
//  UnavailableEventTemplateRepository.swift
//  GalacticCalendar
//

import Foundation

/// Template repository used when the on-disk store cannot be opened.
@MainActor
final class UnavailableEventTemplateRepository: EventTemplateRepositoryProtocol {

    func create(_ template: EventTemplate) async throws {
        throw EventTemplateRepositoryError.saveFailed
    }

    func fetchAll() async throws -> [EventTemplate] { [] }

    func fetch(by id: UUID) async throws -> EventTemplate? { nil }

    func update(_ template: EventTemplate) async throws {
        throw EventTemplateRepositoryError.saveFailed
    }

    func delete(_ template: EventTemplate) async throws {
        try await delete(id: template.id)
    }

    func delete(id: UUID) async throws {
        throw EventTemplateRepositoryError.saveFailed
    }

    func duplicate(_ template: EventTemplate) async throws -> EventTemplate {
        throw EventTemplateRepositoryError.saveFailed
    }
}
