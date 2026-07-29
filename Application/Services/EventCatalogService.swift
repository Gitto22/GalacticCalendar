//
//  EventCatalogService.swift
//  GalacticCalendar
//

import Foundation

/// In-memory reactive catalog of ``Event`` values (single source of truth for reads).
///
/// ## Responsibilities
/// - Hold the sorted event list and revision token.
/// - Answer day / interval / identity queries against that list.
///
/// ## Non-responsibilities
/// - No repository I/O.
/// - No validation.
/// - No notification scheduling.
///
/// ``EventPersistenceService`` mutates storage, then replaces this catalog.
@MainActor
final class EventCatalogService {

    // MARK: - Dependencies

    /// Calendar used for day-boundary queries.
    private let calendar: Calendar

    // MARK: - State

    /// In-memory event catalog, sorted by date ascending.
    private(set) var events: [Event] = []

    /// Monotonic token advanced whenever ``events`` is replaced.
    private(set) var eventsRevision: Int = 0

    // MARK: - Lifecycle

    /// Creates an empty catalog.
    /// - Parameter calendar: Calendar for day queries.
    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    // MARK: - Mutation

    /// Replaces the catalog and advances ``eventsRevision``.
    /// - Parameter newEvents: Events to publish (sorted by date).
    func replaceAll(with newEvents: [Event]) {
        events = newEvents.sorted { $0.date < $1.date }
        eventsRevision += 1
    }

    // MARK: - Queries

    /// Returns catalog events occurring on the given calendar day, sorted by time.
    /// - Parameter date: Day anchor.
    /// - Returns: Matching events from ``events``.
    func events(on date: Date) -> [Event] {
        let dayStart = calendar.startOfDay(for: date)
        return events
            .filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
            .sorted { $0.date < $1.date }
    }

    /// Returns a catalog event by identifier.
    /// - Parameter id: Event identifier.
    /// - Returns: Matching event, if present.
    func event(id: UUID) -> Event? {
        events.first { $0.id == id }
    }

    /// Groups catalog events by start-of-day for the given interval.
    /// - Parameter interval: Query interval (`end` exclusive).
    /// - Returns: Day-start keys mapped to events.
    func eventsGroupedByDay(in interval: DateInterval) -> [Date: [Event]] {
        let filtered = events.filter { event in
            event.date >= interval.start && event.date < interval.end
        }
        return Dictionary(grouping: filtered) { event in
            calendar.startOfDay(for: event.date)
        }
    }

    /// Returns catalog events whose ``RepeatRule`` is recurring.
    /// - Returns: Recurring events (occurrences are not expanded).
    func recurringEvents() -> [Event] {
        events.filter(\.repeatRule.isRecurring)
    }

    /// Returns catalog events inside a date interval, sorted by time.
    /// - Parameter interval: Query interval.
    /// - Returns: Matching events.
    func events(in interval: DateInterval) -> [Event] {
        events.filter { event in
            event.date >= interval.start && event.date < interval.end
        }
        .sorted { $0.date < $1.date }
    }
}
