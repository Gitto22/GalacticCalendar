//
//  EventOrganizationTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Sprint 6.4 tests for color, priority, and tags (persist / map / edit / display).
@MainActor
final class EventOrganizationTests: XCTestCase {

    // MARK: - Persistence / Mapping

    func testTagsRoundTripThroughMapper() throws {
        let original = Event(
            title: "Tagged",
            date: Date(timeIntervalSince1970: 1_900_000_000),
            tags: [.preset(.health), .preset(.family)],
            priority: .urgent,
            color: .orange
        )
        let restored = try EventEntityMapper.makeDomain(from: try EventEntityMapper.makeEntity(from: original))
        XCTAssertEqual(restored.tags.map(\.id), ["health", "family"])
        XCTAssertEqual(restored.priority, .urgent)
        XCTAssertEqual(restored.color, .orange)
        XCTAssertEqual(restored.category, .health)
    }

    func testLegacyPriorityTokensMapToNormalAndUrgent() {
        XCTAssertEqual(EventPriority(persisted: "medium"), .normal)
        XCTAssertEqual(EventPriority(persisted: "critical"), .urgent)
        XCTAssertEqual(EventPriority(persisted: "normal"), .normal)
        XCTAssertEqual(EventPriority(persisted: "urgent"), .urgent)
    }

    func testEmptyTagsSeedFromLegacyCategory() {
        let event = Event(
            title: "Legacy",
            date: Date(),
            category: .travel,
            tags: [],
            color: .yellow
        )
        XCTAssertEqual(event.tags, [.preset(.travel)])
        XCTAssertEqual(event.category, .travel)
    }

    func testCustomTagFactoryPreparesFutureLabels() {
        let custom = EventTag.custom(id: "custom-1", label: "Gym")
        XCTAssertTrue(custom.isCustom)
        XCTAssertEqual(EventEditorDisplayNames.title(for: custom), "Gym")
        XCTAssertEqual(try EventTagCodec.decode(try EventTagCodec.encode([custom])), [custom])
    }

    // MARK: - Editing

    func testEditorToggleTagsSyncsCategory() {
        let viewModel = EventEditorViewModel(
            persistenceService: EventPersistenceService(repository: InMemoryEventRepository())
        )
        XCTAssertTrue(viewModel.isTagSelected(.work))

        viewModel.toggleTag(.work)
        XCTAssertFalse(viewModel.isTagSelected(.work))
        XCTAssertEqual(viewModel.category, .other)

        viewModel.toggleTag(.studies)
        viewModel.toggleTag(.finances)
        XCTAssertTrue(viewModel.isTagSelected(.studies))
        XCTAssertTrue(viewModel.isTagSelected(.finances))
        XCTAssertEqual(viewModel.category, .studies)
    }

    func testEditorPersistsColorPriorityAndTags() async throws {
        let persistence = EventPersistenceService(repository: InMemoryEventRepository())
        try await persistence.refresh()

        let viewModel = EventEditorViewModel(
            persistenceService: persistence,
            initialDate: Date(timeIntervalSince1970: 1_900_000_000)
        )
        viewModel.title = "Organized"
        viewModel.reminderOption = .none
        viewModel.color = .red
        viewModel.priority = .urgent
        viewModel.tags = [.preset(.work), .preset(.personal)]

        await viewModel.createEvent()

        let stored = try XCTUnwrap(persistence.events.first)
        XCTAssertEqual(stored.color, .red)
        XCTAssertEqual(stored.priority, .urgent)
        XCTAssertEqual(stored.tags.map(\.id), ["work", "personal"])
    }

    // MARK: - Visualization / Grid Prep

    func testCalendarIndicatorsCarryColorAndPriority() {
        let events = [
            Event(title: "A", date: Date(), priority: .high, color: .green),
            Event(title: "B", date: Date(), priority: .urgent, color: .red)
        ]
        let indicators = CalendarEventIndicator.indicators(from: events)
        XCTAssertEqual(indicators.map(\.color), [.green, .red])
        XCTAssertEqual(indicators.map(\.priority), [.high, .urgent])

        let day = CalendarDay(
            id: "d",
            date: Date(),
            dayNumber: 1,
            membership: .currentMonth,
            isToday: false
        ).applyingEvents(events)

        XCTAssertEqual(day.eventColors, [.green, .red])
        XCTAssertEqual(day.eventIndicators.count, 2)
    }

    func testDesignSystemPaletteCoversAllEventColors() {
        for color in EventColor.allCases {
            _ = ColorPalette.color(for: color)
        }
        XCTAssertEqual(EventColor.allCases.map(\.rawValue), ["green", "yellow", "orange", "red"])
    }

    func testPriorityOrdering() {
        XCTAssertTrue(EventPriority.low < .normal)
        XCTAssertTrue(EventPriority.normal < .high)
        XCTAssertTrue(EventPriority.high < .urgent)
    }
}
