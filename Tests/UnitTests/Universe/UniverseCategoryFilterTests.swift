//
//  UniverseCategoryFilterTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for History category filtering and legacy resolution.
@MainActor
final class UniverseCategoryFilterTests: XCTestCase {

    // MARK: - Fixtures

    private var calendar: Calendar!

    override func setUp() async throws {
        try await super.setUp()
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = gregorian
    }

    // MARK: - Resolve

    func testResolveMapsLegacyInspirationAndWonder() {
        XCTAssertEqual(UniverseCategory.resolve("inspiration"), .motivation)
        XCTAssertEqual(UniverseCategory.resolve("wonder"), .calm)
        XCTAssertEqual(UniverseCategory.resolve("motivation"), .motivation)
        XCTAssertNil(UniverseCategory.resolve(""))
        XCTAssertNil(UniverseCategory.resolve("unknown_legacy_tag"))
    }

    // MARK: - Category Filter

    func testFilterByCategory() async {
        let viewModel = makeViewModel(history: sampleHistory())
        await viewModel.load()

        viewModel.selectedCategory = .gratitude

        XCTAssertEqual(viewModel.displayedRows.map(\.messageId), ["um_gratitude"])
        XCTAssertEqual(viewModel.displayedRows.first?.category, .gratitude)
    }

    func testAllCategoriesShowsEverythingIncludingUncategorized() async {
        let viewModel = makeViewModel(history: sampleHistory())
        await viewModel.load()

        viewModel.selectedCategory = nil

        XCTAssertEqual(viewModel.displayedRows.count, 3)
    }

    // MARK: - Category + Favorites

    func testCategoryCombinedWithFavorites() async {
        let viewModel = makeViewModel(history: sampleHistory())
        await viewModel.load()

        viewModel.selectedCategory = .motivation
        viewModel.favoriteFilter = .favorites

        XCTAssertEqual(viewModel.displayedRows.map(\.messageId), ["um_motivation_fav"])
        XCTAssertTrue(viewModel.displayedRows.allSatisfy(\.isFavorite))
    }

    // MARK: - Uncategorized

    func testUncategorizedExcludedFromSpecificCategoryFilter() async {
        let viewModel = makeViewModel(history: sampleHistory())
        await viewModel.load()

        viewModel.selectedCategory = .motivation

        XCTAssertFalse(viewModel.displayedRows.contains(where: { $0.messageId == "um_none" }))
        XCTAssertTrue(viewModel.displayedRows.contains(where: { $0.messageId == "um_motivation_fav" }))
    }

    func testUncategorizedVisibleWhenShowingAll() async {
        let viewModel = makeViewModel(history: sampleHistory())
        await viewModel.load()

        viewModel.selectedCategory = nil
        let ids = viewModel.displayedRows.map(\.messageId)

        XCTAssertTrue(ids.contains("um_none"))
        XCTAssertNil(viewModel.displayedRows.first(where: { $0.messageId == "um_none" })?.category)
        XCTAssertNil(viewModel.displayedRows.first(where: { $0.messageId == "um_none" })?.categoryText)
    }

    // MARK: - Daily Algorithm Unaffected

    func testSelectableCategoriesDoNotChangeEngineSelection() async {
        let catalog = [
            UniverseMessage(id: "a", textKey: "k_a", category: .motivation),
            UniverseMessage(id: "b", textKey: "k_b", category: .calm)
        ]
        let repository = InMemoryFavoriteRepository(catalog: catalog)
        let engine = UniverseMessageEngine(repository: repository, calendar: calendar)
        await engine.refreshIfNeeded()

        let day = date(2026, 7, 29)
        let before = engine.message(for: day)

        let service = UniverseMessageService(repository: repository, engine: engine)
        _ = service.selectableCategories

        let after = engine.message(for: day)
        XCTAssertEqual(before.id, after.id)
        XCTAssertEqual(before.category, after.category)
    }

    // MARK: - Helpers

    private func sampleHistory() -> [UniverseMessageHistoryEntry] {
        [
            UniverseMessageHistoryEntry(
                dayStart: date(2026, 7, 29),
                messageId: "um_motivation_fav",
                textKey: "universe_message_body",
                category: .motivation,
                isFavorite: true
            ),
            UniverseMessageHistoryEntry(
                dayStart: date(2026, 7, 28),
                messageId: "um_gratitude",
                textKey: "universe_message_body_04",
                category: .gratitude,
                isFavorite: false
            ),
            UniverseMessageHistoryEntry(
                dayStart: date(2026, 7, 27),
                messageId: "um_none",
                textKey: "universe_message_body_02",
                category: nil,
                isFavorite: false
            )
        ]
    }

    private func makeViewModel(history: [UniverseMessageHistoryEntry]) -> UniverseHistoryViewModel {
        let repository = InMemoryFavoriteRepository(history: history)
        let engine = UniverseMessageEngine(repository: repository, calendar: calendar)
        let service = UniverseMessageService(repository: repository, engine: engine)
        return UniverseHistoryViewModel(
            repository: repository,
            favoriteService: service,
            calendar: calendar
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
