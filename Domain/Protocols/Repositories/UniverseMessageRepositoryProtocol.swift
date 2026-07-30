//
//  UniverseMessageRepositoryProtocol.swift
//  GalacticCalendar
//

import Foundation

/// Errors produced by Universe Message repository implementations.
enum UniverseMessageRepositoryError: Error, Equatable, Sendable {

    // MARK: - Cases

    /// The local catalog could not be loaded or saved.
    case catalogUnavailable

    /// The catalog is empty after seeding / fetch.
    case emptyCatalog

    /// A requested message id was not found.
    case notFound(String)

    /// SwiftData save failed.
    case saveFailed

    /// History could not be loaded.
    case historyUnavailable
}

/// Imperative contract for Universe Message persistence.
///
/// Implementations live in Data. This is the **only** data-access boundary
/// for the Universe catalog and display history.
/// Day selection belongs to ``UniverseMessageEngine``.
protocol UniverseMessageRepositoryProtocol: AnyObject {

    // MARK: - Catalog

    /// Ensures the local catalog is seeded, then returns all messages.
    /// - Returns: Ordered catalog used by the day-selection engine.
    /// - Throws: ``UniverseMessageRepositoryError`` when persistence fails.
    func fetchAll() async throws -> [UniverseMessage]

    /// Returns a single catalog message by stable id.
    /// - Parameter id: Message identifier.
    /// - Returns: Matching message, or `nil` when absent.
    func fetch(by id: String) async throws -> UniverseMessage?

    /// Inserts bundled defaults when the store has no Universe Messages.
    /// - Throws: ``UniverseMessageRepositoryError`` when seeding fails.
    func ensureSeeded() async throws

    // MARK: - History

    /// Returns all recorded Home display days, newest first.
    /// - Returns: History entries sorted by ``UniverseMessageHistoryEntry/dayStart`` descending.
    /// - Throws: ``UniverseMessageRepositoryError/historyUnavailable`` when fetch fails.
    func fetchHistory() async throws -> [UniverseMessageHistoryEntry]

    /// Upserts the message shown for a calendar day (one entry per day).
    /// - Parameters:
    ///   - message: Message that was displayed.
    ///   - day: Any instant on the display day.
    /// - Throws: ``UniverseMessageRepositoryError`` when persistence fails.
    func recordDisplay(_ message: UniverseMessage, on day: Date) async throws

    // MARK: - Favorites

    /// Toggles favorite for the given catalog message and mirrors the flag onto history rows.
    /// - Parameter message: Message whose favorite state should flip.
    /// - Returns: Updated catalog message.
    /// - Throws: ``UniverseMessageRepositoryError`` when persistence fails.
    @discardableResult
    func toggleFavorite(_ message: UniverseMessage) async throws -> UniverseMessage

    /// Returns every catalog message currently marked as favorite.
    /// - Throws: ``UniverseMessageRepositoryError`` when the catalog cannot be loaded.
    func favoriteMessages() async throws -> [UniverseMessage]

    /// Returns whether the given message is currently favorited in the catalog.
    /// - Parameter message: Message to inspect.
    /// - Throws: ``UniverseMessageRepositoryError`` when lookup fails.
    func isFavorite(_ message: UniverseMessage) async throws -> Bool
}
