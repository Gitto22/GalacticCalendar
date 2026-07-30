//
//  UniverseMessageViewModelTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for Home integration of ``UniverseMessageViewModel``.
@MainActor
final class UniverseMessageViewModelTests: XCTestCase {

    // MARK: - Fixtures

    private var calendar: Calendar!
    private var clockBox: ClockBox!
    private let catalog: [UniverseMessage] = [
        UniverseMessage(id: "a", textKey: "universe_message_body", category: .motivation),
        UniverseMessage(id: "b", textKey: "universe_message_body_02", category: .reflection),
        UniverseMessage(id: "c", textKey: "universe_message_body_03", category: .motivation)
    ]

    override func setUp() async throws {
        try await super.setUp()
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = gregorian
        clockBox = ClockBox(value: date(year: 2026, month: 7, day: 29, hour: 10))
    }

    // MARK: - Initial Load

    func testLoadInitialPublishesTodaysMessage() async {
        let engine = makeEngine(messages: catalog)
        let viewModel = makeViewModel(engine: engine)

        await viewModel.loadInitial()

        let expected = engine.message(for: clockBox.value)
        XCTAssertEqual(
            viewModel.message,
            String(localized: String.LocalizationValue(expected.textKey))
        )
        XCTAssertEqual(viewModel.category, expected.category)
        XCTAssertTrue(calendar.isDate(viewModel.date, inSameDayAs: clockBox.value))
    }

    func testLoadInitialIsIdempotentForSameDay() async {
        let viewModel = makeViewModel(engine: makeEngine(messages: catalog))

        await viewModel.loadInitial()
        let firstMessage = viewModel.message
        let firstDate = viewModel.date

        await viewModel.loadInitial()

        XCTAssertEqual(viewModel.message, firstMessage)
        XCTAssertEqual(viewModel.date, firstDate)
    }

    // MARK: - Day Change

    func testRefreshIfDayChangedUpdatesMessage() async {
        let viewModel = makeViewModel(engine: makeEngine(messages: catalog))
        await viewModel.loadInitial()
        let firstMessage = viewModel.message

        clockBox.value = date(year: 2026, month: 7, day: 30, hour: 10)
        viewModel.refreshIfDayChanged()

        XCTAssertNotEqual(viewModel.message, firstMessage)
        XCTAssertTrue(calendar.isDate(viewModel.date, inSameDayAs: clockBox.value))
        XCTAssertFalse(viewModel.message.isEmpty)
    }

    func testRefreshIfDayChangedDoesNothingSameDay() async {
        let viewModel = makeViewModel(engine: makeEngine(messages: catalog))
        await viewModel.loadInitial()
        let firstMessage = viewModel.message

        clockBox.value = date(year: 2026, month: 7, day: 29, hour: 22)
        viewModel.refreshIfDayChanged()

        XCTAssertEqual(viewModel.message, firstMessage)
    }

    func testPublishForAdvancesAcrossMidnightBoundary() async {
        let viewModel = makeViewModel(engine: makeEngine(messages: catalog))
        await viewModel.loadInitial()
        let dayOne = viewModel.message

        let dayTwo = date(year: 2026, month: 7, day: 30, hour: 0, minute: 0, second: 1)
        await viewModel.publish(for: dayTwo)

        XCTAssertNotEqual(viewModel.message, dayOne)
        XCTAssertTrue(calendar.isDate(viewModel.date, inSameDayAs: dayTwo))
    }

    // MARK: - Default Message

    func testDefaultMessageWhenCatalogEmpty() async {
        let viewModel = makeViewModel(engine: makeEngine(messages: []))

        await viewModel.loadInitial()

        XCTAssertEqual(
            viewModel.message,
            String(localized: String.LocalizationValue(
                UniverseMessageEngine.defaultMessage.textKey
            ))
        )
        XCTAssertEqual(viewModel.category, UniverseMessageEngine.defaultMessage.category)
        XCTAssertFalse(viewModel.isFavorite)
    }

    func testEngineReturnsDefaultWhenCatalogEmpty() async {
        let engine = makeEngine(messages: [])
        await engine.refreshIfNeeded()

        let selected = engine.message(for: clockBox.value)
        XCTAssertEqual(selected.id, UniverseMessageEngine.defaultMessage.id)
        XCTAssertEqual(engine.lastError, .emptyCatalog)
    }

    // MARK: - Helpers

    private func makeEngine(messages: [UniverseMessage]) -> UniverseMessageEngine {
        let box = clockBox!
        return UniverseMessageEngine(
            repository: StubUniverseMessageRepository(messages: messages),
            calendar: calendar,
            now: { box.value }
        )
    }

    private func makeViewModel(engine: UniverseMessageEngine) -> UniverseMessageViewModel {
        let box = clockBox!
        return UniverseMessageViewModel(
            engine: engine,
            calendar: calendar,
            now: { box.value }
        )
    }

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

// MARK: - Clock Box

@MainActor
private final class ClockBox {
    var value: Date

    init(value: Date) {
        self.value = value
    }
}

// MARK: - Stub Repository

@MainActor
private final class StubUniverseMessageRepository: UniverseMessageRepositoryProtocol {

    private let messages: [UniverseMessage]

    init(messages: [UniverseMessage]) {
        self.messages = messages
    }

    func fetchAll() async throws -> [UniverseMessage] {
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
