//
//  EventSearchCriteriaTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for Sprint 6.7 smart search / filter pipeline.
@MainActor
final class EventSearchCriteriaTests: XCTestCase {

    // MARK: - Fixtures

    private let day = Date(timeIntervalSince1970: 1_900_000_000)

    private func event(
        title: String = "Meeting",
        description: String = "Notes about the agenda",
        tags: [EventTag] = [.preset(.work)],
        priority: EventPriority = .high,
        color: EventColor = .green,
        category: EventCategory = .work,
        isAllDay: Bool = false,
        endOffset: TimeInterval? = 3_600,
        repeatRule: RepeatRule = .none,
        reminderOffset: TimeInterval? = nil
    ) -> Event {
        Event(
            title: title,
            description: description,
            date: day,
            endDate: endOffset.map { day.addingTimeInterval($0) },
            isAllDay: isAllDay,
            reminder: reminderOffset.map { day.addingTimeInterval($0) },
            repeatRule: repeatRule,
            category: category,
            tags: tags,
            priority: priority,
            status: .pending,
            color: color
        )
    }

    // MARK: - Text

    func testTextSearchMatchesTitleDescriptionAndTags() {
        let events = [
            event(title: "Launch", description: "Ship notes"),
            event(title: "Other", description: "nothing", tags: [.preset(.health)]),
            event(title: "Gym", description: "", tags: [.preset(.health)])
        ]

        var titleCriteria = EventSearchCriteria(textQuery: "launch")
        XCTAssertEqual(titleCriteria.filter(events).map(\.title), ["Launch"])

        var notesCriteria = EventSearchCriteria(textQuery: "ship")
        XCTAssertEqual(notesCriteria.filter(events).map(\.title), ["Launch"])

        var tagCriteria = EventSearchCriteria(textQuery: "health")
        XCTAssertEqual(Set(tagCriteria.filter(events).map(\.title)), ["Other", "Gym"])
    }

    // MARK: - Tags

    func testTagFilterRequiresAllSelectedTags() {
        let events = [
            event(tags: [.preset(.work), .preset(.studies)]),
            event(title: "Only work", tags: [.preset(.work)]),
            event(title: "Personal", tags: [.preset(.personal)])
        ]
        var criteria = EventSearchCriteria(tagIDs: ["work", "studies"])
        XCTAssertEqual(criteria.filter(events).map(\.title), ["Meeting"])
    }

    // MARK: - Intervals

    func testDateIntervalFilterViaCatalog() async throws {
        let early = event(title: "Early")
        let lateStart = Date(timeIntervalSince1970: 2_000_000_000)
        let late = Event(
            title: "Late",
            date: lateStart,
            endDate: lateStart.addingTimeInterval(3_600),
            color: .orange
        )
        let catalog = EventCatalogService()
        catalog.replaceAll(with: [early, late])

        let interval = DateInterval(
            start: Date(timeIntervalSince1970: 1_999_000_000),
            end: Date(timeIntervalSince1970: 2_100_000_000)
        )
        var criteria = EventSearchCriteria(dateInterval: interval)
        let matches = catalog.events(matching: criteria)
        XCTAssertEqual(matches.map(\.title), ["Late"])
    }

    func testQuickRangeThisWeekBuildsInterval() {
        let calendar = Calendar(identifier: .gregorian)
        let range = EventSearchCriteria.QuickDateRange.thisWeek
        let interval = range.dateInterval(
            now: Date(timeIntervalSince1970: 1_900_000_000),
            calendar: calendar
        )
        XCTAssertNotNil(interval)
        XCTAssertEqual(interval?.duration ?? 0, 7 * 86_400, accuracy: 1)
    }

    // MARK: - Priority

    func testPriorityFilter() {
        let events = [
            event(title: "High", priority: .high),
            event(title: "Low", priority: .low),
            event(title: "Urgent", priority: .urgent)
        ]
        var criteria = EventSearchCriteria(priorities: [.high, .urgent])
        XCTAssertEqual(Set(criteria.filter(events).map(\.title)), ["High", "Urgent"])
    }

    // MARK: - Combination

    func testCombinedFiltersWorkAndHighAndColor() {
        let events = [
            event(title: "Match", tags: [.preset(.work)], priority: .high, color: .green),
            event(title: "Wrong priority", tags: [.preset(.work)], priority: .low, color: .green),
            event(title: "Wrong tag", tags: [.preset(.personal)], priority: .high, color: .green),
            event(title: "Wrong color", tags: [.preset(.work)], priority: .high, color: .red)
        ]
        var criteria = EventSearchCriteria(
            tagIDs: ["work"],
            priorities: [.high],
            colors: [.green]
        )
        XCTAssertEqual(criteria.filter(events).map(\.title), ["Match"])
    }

    func testFacetFiltersAllDayRecurringReminder() {
        let events = [
            event(title: "All day", isAllDay: true, endOffset: nil),
            event(title: "Recurring", repeatRule: .weekly),
            event(title: "Reminder", reminderOffset: -900),
            event(title: "Plain")
        ]

        XCTAssertEqual(
            EventSearchCriteria(isAllDay: true).filter(events).map(\.title),
            ["All day"]
        )
        XCTAssertEqual(
            EventSearchCriteria(isRecurring: true).filter(events).map(\.title),
            ["Recurring"]
        )
        XCTAssertEqual(
            EventSearchCriteria(hasReminder: true).filter(events).map(\.title),
            ["Reminder"]
        )
        XCTAssertEqual(
            EventSearchCriteria(hasReminder: false).filter(events).map(\.title).sorted(),
            ["All day", "Plain", "Recurring"]
        )
    }

    // MARK: - Empty

    func testEmptyCriteriaReturnsAll() {
        let events = [event(title: "A"), event(title: "B")]
        XCTAssertTrue(EventSearchCriteria().isEmpty)
        XCTAssertEqual(EventSearchCriteria().filter(events).count, 2)
    }

    func testEmptyResultsWhenNothingMatches() {
        let events = [event(title: "Only")]
        var criteria = EventSearchCriteria(textQuery: "zzzz")
        XCTAssertTrue(criteria.filter(events).isEmpty)
    }

    // MARK: - Performance

    func testFilterSinglePassPerformance() {
        var seed: [Event] = []
        seed.reserveCapacity(2_000)
        for index in 0..<2_000 {
            seed.append(
                event(
                    title: "Event \(index)",
                    description: index.isMultiple(of: 7) ? "needle" : "other",
                    tags: [.preset(index.isMultiple(of: 3) ? .work : .personal)],
                    priority: index.isMultiple(of: 5) ? .high : .normal,
                    color: index.isMultiple(of: 2) ? .green : .orange
                )
            )
        }
        var criteria = EventSearchCriteria(
            textQuery: "needle",
            tagIDs: ["work"],
            priorities: [.high]
        )

        measure {
            let matches = criteria.filter(seed)
            XCTAssertFalse(matches.isEmpty)
        }
    }

    // MARK: - Persistence façade

    func testPersistenceEventsMatchingTracksCatalog() async throws {
        let match = event(title: "Alpha", priority: .urgent, color: .red)
        let other = event(title: "Beta", priority: .low, color: .green)
        let persistence = EventPersistenceService(
            repository: InMemoryEventRepository(seed: [match, other])
        )
        try await persistence.refresh()

        var criteria = EventSearchCriteria(priorities: [.urgent], colors: [.red])
        XCTAssertEqual(persistence.events(matching: criteria).map(\.title), ["Alpha"])
    }

    func testRepositoryFetchMatching() async throws {
        let repo = InMemoryEventRepository(seed: [
            event(title: "Keep", tags: [.preset(.family)]),
            event(title: "Drop", tags: [.preset(.work)])
        ])
        var criteria = EventSearchCriteria(tagIDs: ["family"])
        let matches = try await repo.fetch(matching: criteria)
        XCTAssertEqual(matches.map(\.title), ["Keep"])
    }

    func testSearchViewModelIncrementalResults() async throws {
        let match = event(title: "Workshop notes", priority: .high, color: .yellow)
        let other = event(title: "Idle", priority: .low)
        let persistence = EventPersistenceService(
            repository: InMemoryEventRepository(seed: [match, other])
        )
        try await persistence.refresh()

        let viewModel = EventSearchViewModel(persistenceService: persistence)
        XCTAssertTrue(viewModel.results.count >= 2)

        viewModel.searchText = "workshop"
        viewModel.selectedPriorities = [.high]
        XCTAssertEqual(viewModel.results.map(\.title), ["Workshop notes"])

        viewModel.clearFilters()
        XCTAssertTrue(viewModel.criteria.isEmpty)
    }
}
