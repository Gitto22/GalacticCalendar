//
//  UniverseMessageShareTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for Universe Message share payload generation.
@MainActor
final class UniverseMessageShareTests: XCTestCase {

    // MARK: - Fixtures

    private var calendar: Calendar!
    private var sampleDate: Date!

    override func setUp() async throws {
        try await super.setUp()
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = gregorian

        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 29
        sampleDate = calendar.date(from: components)!
    }

    // MARK: - Generation

    func testMakeShareTextIncludesMessageDateAndAppName() {
        let text = UniverseMessageViewModel.makeShareText(
            message: "Small steps still move you forward.",
            date: sampleDate,
            calendar: calendar
        )

        XCTAssertTrue(text.contains("Small steps still move you forward."))
        XCTAssertTrue(text.contains(String(localized: "universe_share_headline")))
        XCTAssertTrue(text.contains(String(localized: "universe_share_app_name")))

        let formattedDate = sampleDate.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted).calendar(calendar)
        )
        XCTAssertTrue(text.contains(formattedDate))
    }

    func testShareTextFromViewModelUsesCurrentMessage() async {
        let repository = StubShareRepository()
        let engine = UniverseMessageEngine(
            repository: repository,
            calendar: calendar,
            now: { self.sampleDate }
        )
        let viewModel = UniverseMessageViewModel(
            engine: engine,
            repository: repository,
            calendar: calendar,
            now: { self.sampleDate }
        )

        await viewModel.loadInitial()
        let text = viewModel.shareText()

        XCTAssertTrue(text.contains(viewModel.message))
        XCTAssertTrue(text.contains(String(localized: "universe_share_app_name")))
        XCTAssertTrue(text.contains(String(localized: "universe_share_headline")))
    }

    // MARK: - Empty Message

    func testMakeShareTextUsesFallbackWhenMessageEmpty() {
        let text = UniverseMessageViewModel.makeShareText(
            message: "   ",
            date: sampleDate,
            calendar: calendar
        )

        XCTAssertTrue(text.contains(String(localized: "universe_share_empty_message")))
        XCTAssertTrue(text.contains(String(localized: "universe_share_app_name")))
        XCTAssertFalse(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    func testMakeShareTextUsesFallbackWhenMessageBlank() {
        let text = UniverseMessageViewModel.makeShareText(
            message: "",
            date: sampleDate,
            calendar: calendar
        )

        XCTAssertTrue(text.contains(String(localized: "universe_share_empty_message")))
        XCTAssertTrue(text.contains(String(localized: "universe_share_headline")))
    }

    // MARK: - Localization

    func testSharePayloadUsesLocalizedKeys() {
        let text = UniverseMessageViewModel.makeShareText(
            message: "Hello",
            date: sampleDate,
            calendar: calendar
        )

        // Headline and app name resolve through Localizable.strings.
        XCTAssertTrue(text.contains(String(localized: "universe_share_headline")))
        XCTAssertTrue(text.contains(String(localized: "universe_share_app_name")))
        XCTAssertTrue(text.contains("Hello"))
    }

    func testHistoryViewModelForwardsSharePreparation() {
        let item = UniverseHistoryRowItem(
            id: sampleDate,
            messageId: "um_001",
            dayStart: sampleDate,
            dateText: "29 Jul 2026",
            message: "Shared body",
            categoryText: "Motivation",
            category: .motivation,
            isFavorite: false
        )
        let repository = StubShareRepository()
        let engine = UniverseMessageEngine(repository: repository, calendar: calendar)
        let service = UniverseMessageService(repository: repository, engine: engine)
        let history = UniverseHistoryViewModel(
            repository: repository,
            favoriteService: service,
            calendar: calendar
        )

        let text = history.shareText(for: item)
        let expected = UniverseMessageViewModel.makeShareText(
            message: "Shared body",
            date: sampleDate,
            calendar: calendar
        )

        XCTAssertEqual(text, expected)
    }
}

// MARK: - Stub

@MainActor
private final class StubShareRepository: UniverseMessageRepositoryProtocol {

    func fetchAll() async throws -> [UniverseMessage] {
        [
            UniverseMessage(
                id: "um_share",
                textKey: "universe_message_body",
                category: .motivation
            )
        ]
    }

    func fetch(by id: String) async throws -> UniverseMessage? {
        try await fetchAll().first { $0.id == id }
    }

    func ensureSeeded() async throws {}

    func fetchHistory() async throws -> [UniverseMessageHistoryEntry] { [] }

    func recordDisplay(_ message: UniverseMessage, on day: Date) async throws {}

    func toggleFavorite(_ message: UniverseMessage) async throws -> UniverseMessage { message }

    func favoriteMessages() async throws -> [UniverseMessage] { [] }

    func isFavorite(_ message: UniverseMessage) async throws -> Bool { false }
}
