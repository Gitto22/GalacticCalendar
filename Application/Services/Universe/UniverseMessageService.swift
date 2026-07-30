//
//  UniverseMessageService.swift
//  GalacticCalendar
//

import Foundation

/// Application façade for Universe Message catalog mutations and category metadata.
///
/// ## Responsibilities
/// - Favorite toggles and queries via ``UniverseMessageRepositoryProtocol``.
/// - Expose selectable ``UniverseCategory`` values for History filtering.
/// - Keep ``UniverseMessageEngine`` catalog cache aligned after favorite changes.
///
/// ## Non-responsibilities
/// - **No day selection** — owned exclusively by ``UniverseMessageEngine``.
/// - Categories never alter the daily message algorithm.
/// - No SwiftUI.
@MainActor
final class UniverseMessageService {

    // MARK: - Dependencies

    /// Sole data-access boundary.
    private let repository: any UniverseMessageRepositoryProtocol

    /// Day-selection engine whose in-memory catalog mirrors favorite flags.
    private let engine: UniverseMessageEngine

    /// Reads current store availability from the Composition Root.
    private let storageAvailabilityProvider: () -> StorageAvailability

    // MARK: - Lifecycle

    /// Creates a Universe Message application service.
    /// - Parameters:
    ///   - repository: Catalog / history repository.
    ///   - engine: Selection engine to keep in sync after mutations.
    ///   - storageAvailabilityProvider: Gate for write operations.
    init(
        repository: any UniverseMessageRepositoryProtocol,
        engine: UniverseMessageEngine,
        storageAvailabilityProvider: @escaping () -> StorageAvailability = { .available }
    ) {
        self.repository = repository
        self.engine = engine
        self.storageAvailabilityProvider = storageAvailabilityProvider
    }

    // MARK: - Categories

    /// Ordered categories for the History horizontal selector.
    ///
    /// Does not affect ``UniverseMessageEngine`` day selection.
    var selectableCategories: [UniverseCategory] {
        UniverseCategory.selectableCases
    }

    // MARK: - Favorites

    /// Toggles favorite for ``message`` and returns the persisted result.
    /// - Parameter message: Message to toggle.
    /// - Returns: Updated catalog message.
    @discardableResult
    func toggleFavorite(_ message: UniverseMessage) async throws -> UniverseMessage {
        guard storageAvailabilityProvider().allowsWrites else {
            PersistenceLog.writeBlocked(operation: "UniverseMessageService.toggleFavorite")
            throw UniverseMessageRepositoryError.saveFailed
        }
        let updated = try await repository.toggleFavorite(message)
        engine.applyFavorite(messageId: updated.id, isFavorite: updated.isFavorite)
        return updated
    }

    /// Returns all favorited catalog messages.
    func favoriteMessages() async throws -> [UniverseMessage] {
        try await repository.favoriteMessages()
    }

    /// Returns whether ``message`` is favorited in persistence.
    func isFavorite(_ message: UniverseMessage) async throws -> Bool {
        try await repository.isFavorite(message)
    }
}
