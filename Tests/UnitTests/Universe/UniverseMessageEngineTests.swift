//
//  UniverseMessageEngineTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for ``UniverseMessageEngine``: determinism, day change, no-repeat, performance.
@MainActor
final class UniverseMessageEngineTests: XCTestCase {

    // MARK: - Fixtures

    private var calendar: Calendar!
    private var repository: StubUniverseMessageRepository!
    private var engine: UniverseMessageEngine!

    private let catalog: [UniverseMessage] = [
        UniverseMessage(id: "a", textKey: "key_a", category: .motivation),
        UniverseMessage(id: "b", textKey: "key_b", category: .reflection),
        UniverseMessage(id: "c", textKey: "key_c", category: .motivation),
        UniverseMessage(id: "d", textKey: "key_d", category: .gratitude)
    ]

    override func setUp() async throws {
        try await super.setUp()
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = gregorian
        repository = StubUniverseMessageRepository(messages: catalog)
        engine = UniverseMessageEngine(
            repository: repository,
            calendar: calendar,
            now: { Date(timeIntervalSince1970: 1_900_000_000) }
        )
        await engine.refreshIfNeeded()
    }

    // MARK: - Refresh

    func testRefreshIfNeededLoadsCatalogOnce() async {
        XCTAssertEqual(engine.catalog.count, 4)
        let fetchesBefore = repository.fetchCount
        await engine.refreshIfNeeded()
        XCTAssertEqual(repository.fetchCount, fetchesBefore)
    }

    func testRefreshIfNeededRecordsEmptyCatalogWithoutThrowing() async {
        let emptyEngine = UniverseMessageEngine(
            repository: StubUniverseMessageRepository(messages: []),
            calendar: calendar
        )

        await emptyEngine.refreshIfNeeded()

        XCTAssertTrue(emptyEngine.catalog.isEmpty)
        XCTAssertEqual(emptyEngine.lastError, .emptyCatalog)
        XCTAssertEqual(
            emptyEngine.message(for: Date()).id,
            UniverseMessageEngine.defaultMessage.id
        )
    }

    // MARK: - Determinism

    func testSameDateAlwaysReturnsSameMessage() {
        let morning = date(year: 2026, month: 7, day: 29, hour: 6)
        let noon = date(year: 2026, month: 7, day: 29, hour: 12)
        let night = date(year: 2026, month: 7, day: 29, hour: 23, minute: 50)

        let first = engine.message(for: morning)
        XCTAssertEqual(engine.message(for: noon).id, first.id)
        XCTAssertEqual(engine.message(for: night).id, first.id)
    }

    func testDeterminismAcrossEngineInstances() async {
        let day = date(year: 2026, month: 3, day: 15, hour: 10)
        let first = engine.message(for: day)

        let secondEngine = UniverseMessageEngine(
            repository: StubUniverseMessageRepository(messages: catalog),
            calendar: calendar
        )
        await secondEngine.refreshIfNeeded()

        XCTAssertEqual(secondEngine.message(for: day).id, first.id)
        XCTAssertEqual(secondEngine.message(for: day).category, first.category)
    }

    func testMessageForTodayMatchesMessageForNow() async {
        let today = date(year: 2026, month: 7, day: 29, hour: 15)
        let clocked = UniverseMessageEngine(
            repository: StubUniverseMessageRepository(messages: catalog),
            calendar: calendar,
            now: { today }
        )
        await clocked.refreshIfNeeded()
        XCTAssertEqual(clocked.messageForToday().id, clocked.message(for: today).id)
    }

    // MARK: - Day Change

    func testNextCalendarDayCanChangeMessage() {
        let dayOne = date(year: 2026, month: 7, day: 29, hour: 10)
        let dayTwo = date(year: 2026, month: 7, day: 30, hour: 10)

        let first = engine.message(for: dayOne)
        let second = engine.message(for: dayTwo)

        XCTAssertNotEqual(first.id, second.id)
    }

    // MARK: - No Repetition

    func testNoRepetitionWithinCatalogCycle() {
        let start = date(year: 2026, month: 1, day: 1, hour: 12)
        var seen = Set<String>()

        for offset in 0..<catalog.count {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else {
                return XCTFail("Could not advance day")
            }
            let id = engine.message(for: day).id
            XCTAssertFalse(seen.contains(id), "Repeated message \(id) within cycle")
            seen.insert(id)
        }

        XCTAssertEqual(seen.count, catalog.count)
    }

    func testNextCycleMayReuseMessagesAfterExhaustion() {
        let start = date(year: 2026, month: 1, day: 1, hour: 12)
        var firstCycle: [String] = []
        var secondCycle: [String] = []

        for offset in 0..<catalog.count {
            let day = calendar.date(byAdding: .day, value: offset, to: start)!
            firstCycle.append(engine.message(for: day).id)
        }
        for offset in catalog.count..<(catalog.count * 2) {
            let day = calendar.date(byAdding: .day, value: offset, to: start)!
            secondCycle.append(engine.message(for: day).id)
        }

        XCTAssertEqual(Set(firstCycle).count, catalog.count)
        XCTAssertEqual(Set(secondCycle).count, catalog.count)
        XCTAssertEqual(Set(secondCycle), Set(catalog.map(\.id)))
    }

    // MARK: - Performance

    func testMessageForPerformance() {
        let day = date(year: 2026, month: 7, day: 29, hour: 12)
        measure {
            for _ in 0..<5_000 {
                _ = engine.message(for: day)
            }
        }
    }

    func testDeterministicPermutationPerformance() {
        measure {
            for cycle in 0..<2_000 {
                _ = UniverseMessageEngine.deterministicPermutation(of: catalog, cycle: cycle)
            }
        }
    }

    // MARK: - Helpers

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return calendar.date(from: components)!
    }
}

// MARK: - Stub Repository

@MainActor
private final class StubUniverseMessageRepository: UniverseMessageRepositoryProtocol {

    private let messages: [UniverseMessage]
    private(set) var fetchCount: Int = 0

    init(messages: [UniverseMessage]) {
        self.messages = messages
    }

    func fetchAll() async throws -> [UniverseMessage] {
        fetchCount += 1
        if messages.isEmpty {
            throw UniverseMessageRepositoryError.emptyCatalog
        }
        return messages
    }

    func fetch(by id: String) async throws -> UniverseMessage? {
        messages.first { $0.id == id }
    }

    func ensureSeeded() async throws {}

    func fetchHistory() async throws -> [UniverseMessageHistoryEntry] { [] }

    func recordDisplay(_ message: UniverseMessage, on day: Date) async throws {}

    func toggleFavorite(_ message: UniverseMessage) async throws -> UniverseMessage {
        var copy = message
        copy.isFavorite.toggle()
        return copy
    }

    func favoriteMessages() async throws -> [UniverseMessage] {
        messages.filter(\.isFavorite)
    }

    func isFavorite(_ message: UniverseMessage) async throws -> Bool {
        messages.first(where: { $0.id == message.id })?.isFavorite ?? false
    }
}
