//
//  UniverseHistoryViewModelTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for ``UniverseHistoryViewModel`` sorting, search, and empty state.
@MainActor
final class UniverseHistoryViewModelTests: XCTestCase {

    // MARK: - Fixtures

    private var calendar: Calendar!

    override func setUp() async throws {
        try await super.setUp()
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = gregorian
    }

    // MARK: - Sorting

    func testLoadSortsEntriesByDateDescending() async {
        let older = entry(day: date(2026, 7, 1), id: "old", textKey: "universe_message_body", category: .motivation)
        let newer = entry(day: date(2026, 7, 29), id: "new", textKey: "universe_message_body_02", category: .reflection)
        let middle = entry(day: date(2026, 7, 15), id: "mid", textKey: "universe_message_body_03", category: .motivation)

        let viewModel = makeViewModel(history: [older, newer, middle])
        await viewModel.load()

        XCTAssertEqual(
            viewModel.displayedRows.map(\.id),
            [newer.dayStart, middle.dayStart, older.dayStart]
        )
    }

    // MARK: - Search by Text

    func testSearchFiltersByMessageText() async {
        let first = entry(
            day: date(2026, 7, 29),
            id: "a",
            textKey: "UniqueGalaxyPhraseAlpha",
            category: .motivation
        )
        let second = entry(
            day: date(2026, 7, 28),
            id: "b",
            textKey: "UniqueGalaxyPhraseBeta",
            category: .reflection
        )

        let viewModel = makeViewModel(history: [first, second])
        await viewModel.load()
        viewModel.searchText = "phrasealpha"

        XCTAssertEqual(viewModel.displayedRows.count, 1)
        XCTAssertEqual(viewModel.displayedRows.first?.id, first.dayStart)
    }

    // MARK: - Search by Category

    func testSearchFiltersByCategory() async {
        let inspiration = entry(
            day: date(2026, 7, 29),
            id: "a",
            textKey: "universe_message_body",
            category: .motivation
        )
        let calm = entry(
            day: date(2026, 7, 28),
            id: "b",
            textKey: "universe_message_body_05",
            category: .calm
        )

        let viewModel = makeViewModel(history: [inspiration, calm])
        await viewModel.load()
        viewModel.searchText = "calm"

        XCTAssertEqual(viewModel.displayedRows.count, 1)
        XCTAssertEqual(viewModel.displayedRows.first?.id, calm.dayStart)
    }

    // MARK: - Empty State

    func testEmptyHistoryState() async {
        let viewModel = makeViewModel(history: [])

        XCTAssertFalse(viewModel.isHistoryEmpty)
        await viewModel.load()

        XCTAssertTrue(viewModel.isHistoryEmpty)
        XCTAssertTrue(viewModel.displayedRows.isEmpty)
        XCTAssertFalse(viewModel.isFilterEmpty)
    }

    func testSearchEmptyWhenNoMatches() async {
        let entry = entry(
            day: date(2026, 7, 29),
            id: "a",
            textKey: "universe_message_body",
            category: .motivation
        )
        let viewModel = makeViewModel(history: [entry])
        await viewModel.load()
        viewModel.searchText = "zzzz-no-match"

        XCTAssertFalse(viewModel.isHistoryEmpty)
        XCTAssertTrue(viewModel.isFilterEmpty)
        XCTAssertTrue(viewModel.displayedRows.isEmpty)
    }

    // MARK: - Helpers

    private func makeViewModel(
        history: [UniverseMessageHistoryEntry],
        favorites: Set<String> = []
    ) -> UniverseHistoryViewModel {
        let repository = InMemoryFavoriteRepository(history: history, favoriteIDs: favorites)
        let engine = UniverseMessageEngine(repository: repository, calendar: calendar)
        let service = UniverseMessageService(repository: repository, engine: engine)
        return UniverseHistoryViewModel(
            repository: repository,
            favoriteService: service,
            calendar: calendar
        )
    }

    private func entry(
        day: Date,
        id: String,
        textKey: String,
        category: UniverseCategory?,
        isFavorite: Bool = false
    ) -> UniverseMessageHistoryEntry {
        UniverseMessageHistoryEntry(
            dayStart: calendar.startOfDay(for: day),
            messageId: id,
            textKey: textKey,
            category: category,
            isFavorite: isFavorite
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)!
    }
}

// MARK: - Shared In-Memory Repository (file-private for favorite tests reuse pattern)

@MainActor
final class InMemoryFavoriteRepository: UniverseMessageRepositoryProtocol {

    private var catalog: [String: UniverseMessage]
    private var history: [UniverseMessageHistoryEntry]
    private var favoriteIDs: Set<String>

    init(
        history: [UniverseMessageHistoryEntry] = [],
        favoriteIDs: Set<String> = [],
        catalog: [UniverseMessage] = []
    ) {
        self.history = history
        self.favoriteIDs = favoriteIDs
        if catalog.isEmpty {
            var built: [String: UniverseMessage] = [:]
            for entry in history {
                built[entry.messageId] = UniverseMessage(
                    id: entry.messageId,
                    textKey: entry.textKey,
                    category: entry.category ?? .motivation,
                    isFavorite: favoriteIDs.contains(entry.messageId) || entry.isFavorite
                )
            }
            self.catalog = built
        } else {
            var built = Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0) })
            for id in favoriteIDs {
                if var message = built[id] {
                    message.isFavorite = true
                    built[id] = message
                }
            }
            self.catalog = built
            if favoriteIDs.isEmpty {
                self.favoriteIDs = Set(catalog.filter(\.isFavorite).map(\.id))
            }
        }
    }

    func fetchAll() async throws -> [UniverseMessage] {
        Array(catalog.values).sorted { $0.id < $1.id }
    }

    func fetch(by id: String) async throws -> UniverseMessage? {
        catalog[id]
    }

    func ensureSeeded() async throws {}

    func fetchHistory() async throws -> [UniverseMessageHistoryEntry] {
        history.sorted { $0.dayStart > $1.dayStart }
    }

    func recordDisplay(_ message: UniverseMessage, on day: Date) async throws {
        let dayStart = Calendar.current.startOfDay(for: day)
        history.removeAll { $0.dayStart == dayStart }
        history.append(
            UniverseMessageHistoryEntry(
                dayStart: dayStart,
                messageId: message.id,
                textKey: message.textKey,
                category: message.category,
                isFavorite: favoriteIDs.contains(message.id)
            )
        )
        catalog[message.id] = message
    }

    func toggleFavorite(_ message: UniverseMessage) async throws -> UniverseMessage {
        if favoriteIDs.contains(message.id) {
            favoriteIDs.remove(message.id)
        } else {
            favoriteIDs.insert(message.id)
        }
        let isFavorite = favoriteIDs.contains(message.id)
        if var existing = catalog[message.id] {
            existing.isFavorite = isFavorite
            catalog[message.id] = existing
        } else {
            catalog[message.id] = UniverseMessage(
                id: message.id,
                textKey: message.textKey.isEmpty ? "universe_message_body" : message.textKey,
                category: message.category,
                isFavorite: isFavorite
            )
        }
        history = history.map { entry in
            guard entry.messageId == message.id else {
                return entry
            }
            return UniverseMessageHistoryEntry(
                dayStart: entry.dayStart,
                messageId: entry.messageId,
                textKey: entry.textKey,
                category: entry.category,
                isFavorite: isFavorite,
                recordedAt: entry.recordedAt
            )
        }
        return catalog[message.id]!
    }

    func favoriteMessages() async throws -> [UniverseMessage] {
        try await fetchAll().filter(\.isFavorite)
    }

    func isFavorite(_ message: UniverseMessage) async throws -> Bool {
        favoriteIDs.contains(message.id)
    }
}
