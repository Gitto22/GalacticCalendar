//
//  UniverseMessageEngine.swift
//  GalacticCalendar
//

import Foundation

/// Errors produced by ``UniverseMessageEngine`` (recorded silently; never shown in Home UI).
enum UniverseMessageEngineError: Error, Equatable, Sendable {

    // MARK: - Cases

    /// Underlying catalog could not be loaded.
    case catalogUnavailable

    /// Catalog is empty after a successful load attempt.
    case emptyCatalog
}

/// Application engine that decides which Universe Message belongs to a calendar day.
///
/// ## Responsibilities
/// - Load and cache the catalog via ``UniverseMessageRepositoryProtocol``.
/// - Map a calendar date to exactly one catalog message.
/// - Guarantee determinism: the same date always yields the same message.
/// - Avoid repeating a message within a catalog cycle while unused messages remain.
/// - Provide ``defaultMessage`` when the catalog is unavailable or empty.
///
/// ## Algorithm
/// 1. Sort the catalog by stable ``UniverseMessage/id``.
/// 2. Map the date to a day ordinal (midnights since Unix epoch start-of-day).
/// 3. Split into `cycle = ordinal / count` and `position = ordinal % count`.
/// 4. Build a deterministic permutation of the catalog seeded by `cycle`.
/// 5. Return `permutation[position]`.
///
/// ## Non-responsibilities
/// - No SwiftUI.
/// - No favorite mutations, history, sharing, online download, or AI.
@MainActor
final class UniverseMessageEngine {

    // MARK: - Defaults

    /// Fallback message when the catalog cannot be loaded or is empty.
    ///
    /// Uses the original Home sample localization key so the approved card never goes blank.
    static let defaultMessage = UniverseMessage(
        id: "um_default",
        textKey: "universe_message_body",
        category: .motivation
    )

    // MARK: - Dependencies

    /// Sole data-access boundary for the catalog.
    private let repository: any UniverseMessageRepositoryProtocol

    /// Calendar used for day-boundary identity.
    private let calendar: Calendar

    /// Clock used by ``messageForToday()``.
    private let now: () -> Date

    // MARK: - State

    /// Cached catalog used for selection. Empty until ``refreshIfNeeded()`` succeeds.
    private(set) var catalog: [UniverseMessage] = []

    /// Last refresh failure, if any (not surfaced to Home UI).
    private(set) var lastError: UniverseMessageEngineError?

    // MARK: - Lifecycle

    /// Creates a Universe Message selection engine.
    /// - Parameters:
    ///   - repository: Catalog repository.
    ///   - calendar: Calendar for day ordinals.
    ///   - now: Clock provider for “today” queries.
    init(
        repository: any UniverseMessageRepositoryProtocol,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.repository = repository
        self.calendar = calendar
        self.now = now
    }

    // MARK: - Refresh

    /// Reloads the catalog when it is empty.
    ///
    /// Failures are recorded on ``lastError`` and never thrown — callers always
    /// obtain ``defaultMessage`` from ``message(for:)`` when the catalog is empty.
    func refreshIfNeeded() async {
        guard catalog.isEmpty else {
            return
        }

        do {
            let messages = try await repository.fetchAll()
            guard messages.isEmpty == false else {
                catalog = []
                lastError = .emptyCatalog
                return
            }
            catalog = messages
            lastError = nil
        } catch let error as UniverseMessageRepositoryError {
            catalog = []
            switch error {
            case .emptyCatalog:
                lastError = .emptyCatalog
            case .catalogUnavailable, .notFound, .saveFailed, .historyUnavailable:
                lastError = .catalogUnavailable
            }
        } catch {
            catalog = []
            lastError = .catalogUnavailable
        }
    }

    /// Forces a catalog reload from the repository (e.g. after favorite changes).
    func reloadCatalog() async {
        catalog = []
        lastError = nil
        await refreshIfNeeded()
    }

    /// Updates ``isFavorite`` on a cached catalog message without a full reload.
    /// - Parameters:
    ///   - messageId: Catalog message id.
    ///   - isFavorite: New favorite flag.
    func applyFavorite(messageId: String, isFavorite: Bool) {
        guard let index = catalog.firstIndex(where: { $0.id == messageId }) else {
            return
        }
        catalog[index].isFavorite = isFavorite
    }

    // MARK: - Selection

    /// Returns the Universe Message assigned to the given calendar day.
    ///
    /// Always returns a value: ``defaultMessage`` when the catalog is empty.
    /// - Parameter date: Any instant; only the calendar day matters.
    /// - Returns: Selected catalog message or ``defaultMessage``.
    func message(for date: Date) -> UniverseMessage {
        guard catalog.isEmpty == false else {
            return Self.defaultMessage
        }

        let dayStart = calendar.startOfDay(for: date)
        let sorted = catalog.sorted { $0.id < $1.id }
        let count = sorted.count
        let ordinal = dayOrdinal(for: dayStart)
        let cycle = floorDiv(ordinal, count)
        let position = positiveModulo(ordinal, count)
        let order = Self.deterministicPermutation(of: sorted, cycle: cycle)
        return order[position]
    }

    /// Returns the Universe Message for “today” in the engine calendar / clock.
    ///
    /// Sprint API name: `message(forToday)`.
    /// - Returns: Selected catalog message or ``defaultMessage``.
    func messageForToday() -> UniverseMessage {
        message(for: now())
    }

    // MARK: - Private — Day Math

    /// Midnights from Unix epoch start-of-day to ``dayStart``.
    private func dayOrdinal(for dayStart: Date) -> Int {
        let reference = Date(timeIntervalSince1970: 0)
        let referenceStart = calendar.startOfDay(for: reference)
        return calendar.dateComponents([.day], from: referenceStart, to: dayStart).day ?? 0
    }

    /// Integer floor division that truncates toward −∞.
    private func floorDiv(_ value: Int, _ divisor: Int) -> Int {
        precondition(divisor > 0)
        let quotient = value / divisor
        let remainder = value % divisor
        if remainder == 0 || value >= 0 {
            return quotient
        }
        return quotient - 1
    }

    /// Non-negative modulo in `0..<modulus`.
    private func positiveModulo(_ value: Int, _ modulus: Int) -> Int {
        precondition(modulus > 0)
        let remainder = value % modulus
        return remainder >= 0 ? remainder : remainder + modulus
    }

    // MARK: - Private — Deterministic Permutation

    /// Fisher–Yates permutation of ``messages`` seeded solely by ``cycle``.
    static func deterministicPermutation(
        of messages: [UniverseMessage],
        cycle: Int
    ) -> [UniverseMessage] {
        guard messages.count > 1 else {
            return messages
        }

        var items = messages
        var state = Self.mixSeed(cycle)

        for index in stride(from: items.count - 1, through: 1, by: -1) {
            state = state &* 6_364_136_223_846_793_005 &+ 1
            let j = Int(state % UInt64(index + 1))
            items.swapAt(index, j)
        }
        return items
    }

    /// Mixes a cycle index into a non-zero 64-bit seed.
    private static func mixSeed(_ cycle: Int) -> UInt64 {
        var seed = UInt64(bitPattern: Int64(cycle))
        seed &+= 0x9E37_79B9_7F4A_7C15
        seed = (seed ^ (seed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        seed = (seed ^ (seed >> 27)) &* 0x94D0_49BB_1331_11EB
        seed ^= seed >> 31
        return seed == 0 ? 0xA5A5_A5A5_A5A5_A5A5 : seed
    }
}
