//
//  EventCatalogService.swift
//  GalacticCalendar
//

import Foundation

/// In-memory reactive catalog of ``Event`` values (single source of truth for reads).
///
/// ## Responsibilities
/// - Hold the sorted master event list and revision token.
/// - Expand multi-day spans and recurrence into visible days dynamically.
///
/// ## Non-responsibilities
/// - No repository I/O.
/// - No validation.
/// - No notification scheduling.
/// - No physical occurrence persistence.
/// - No corruption handling — ``EventRepository/fetchAll()`` already isolates
///   undecodable rows (QA-03) before ``replaceAll(with:)``.
///
/// ``EventPersistenceService`` mutates storage, then replaces this catalog.
@MainActor
final class EventCatalogService {

    // MARK: - Dependencies

    /// Calendar used for day-boundary queries.
    private let calendar: Calendar

    /// Expands recurrence rules into virtual occurrences.
    private let recurrenceEngine: RecurrenceEngine

    // MARK: - State

    /// In-memory master event catalog, sorted for display (all-day first, then by start).
    private(set) var events: [Event] = []

    /// Monotonic token advanced whenever ``events`` is replaced.
    private(set) var eventsRevision: Int = 0

    // MARK: - Lifecycle

    /// Creates an empty catalog.
    /// - Parameter calendar: Calendar for day queries.
    init(calendar: Calendar = .current) {
        self.calendar = calendar
        self.recurrenceEngine = RecurrenceEngine(calendar: calendar)
    }

    // MARK: - Mutation

    /// Replaces the catalog and advances ``eventsRevision``.
    /// - Parameter newEvents: Master events to publish (sorted for display).
    func replaceAll(with newEvents: [Event]) {
        events = newEvents.sorted(by: EventSchedule.displaySort)
        eventsRevision += 1
    }

    // MARK: - Queries

    /// Returns presentation events occurring on the given calendar day.
    ///
    /// Recurring masters are expanded dynamically; multi-day spans still appear
    /// on every overlapping day. Sorted all-day first.
    /// - Parameter date: Day anchor.
    /// - Returns: Materialized occurrence events (same master id).
    func events(on date: Date) -> [Event] {
        occurrences(on: date).map { $0.asEvent() }
    }

    /// Virtual occurrences overlapping the calendar day of ``date``.
    func occurrences(on date: Date) -> [EventOccurrence] {
        let expanded = events.flatMap { recurrenceEngine.occurrences(of: $0, on: date) }
        return expanded.sorted {
            EventSchedule.displaySort($0.asEvent(), $1.asEvent())
        }
    }

    /// Returns a catalog master event by identifier.
    /// - Parameter id: Event identifier.
    /// - Returns: Matching master event, if present.
    func event(id: UUID) -> Event? {
        events.first { $0.id == id }
    }

    /// Groups presentation events by start-of-day for the given interval.
    ///
    /// Recurrence + multi-day expansion so the month grid shows indicators on
    /// every visible occurrence day.
    /// - Parameter interval: Query interval (`end` exclusive).
    /// - Returns: Day-start keys mapped to materialized events.
    func eventsGroupedByDay(in interval: DateInterval) -> [Date: [Event]] {
        var grouped: [Date: [Event]] = [:]

        for master in events {
            let occurrences = recurrenceEngine.occurrences(of: master, in: interval)
            for occurrence in occurrences {
                let spanEnd = occurrence.occurrenceEnd ?? occurrence.occurrenceStart
                let days = EventSchedule.dayStarts(
                    from: occurrence.occurrenceStart,
                    through: spanEnd,
                    calendar: calendar
                )
                let presentation = occurrence.asEvent()
                for day in days where day >= interval.start && day < interval.end {
                    grouped[day, default: []].append(presentation)
                }
            }
        }

        for day in grouped.keys {
            var seen: Set<UUID> = []
            let unique = (grouped[day] ?? []).filter { seen.insert($0.id).inserted }
            grouped[day] = unique.sorted(by: EventSchedule.displaySort)
        }
        return grouped
    }

    // MARK: - Search / Filter (Sprint 6.7)

    /// Masters matching ``criteria`` in a **single pass** (content + facets + dates).
    ///
    /// Date constraints use recurrence expansion when needed. Organization
    /// filters run before expansion so non-matching masters are never expanded.
    func events(matching criteria: EventSearchCriteria) -> [Event] {
        if criteria.isEmpty {
            return events
        }
        var result: [Event] = []
        result.reserveCapacity(events.count)
        for master in events {
            guard criteria.matches(master) else { continue }
            guard matchesDateConstraint(master, criteria: criteria) else { continue }
            result.append(master)
        }
        return result
    }

    /// Day events after filtering masters with ``criteria`` (one expand pass).
    func events(on date: Date, matching criteria: EventSearchCriteria) -> [Event] {
        if criteria.isEmpty {
            return events(on: date)
        }

        if let onDate = criteria.onDate,
           calendar.isDate(onDate, inSameDayAs: date) == false {
            return []
        }

        if let interval = criteria.dateInterval {
            let dayStart = calendar.startOfDay(for: date)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                return []
            }
            let dayInterval = DateInterval(start: dayStart, end: dayEnd)
            guard dayInterval.intersects(interval) else {
                return []
            }
        }

        var facetCriteria = criteria
        facetCriteria.onDate = nil
        facetCriteria.dateInterval = nil

        var result: [Event] = []
        for master in events {
            guard facetCriteria.matches(master) else { continue }
            for occurrence in recurrenceEngine.occurrences(of: master, on: date) {
                result.append(occurrence.asEvent())
            }
        }
        return result.sorted(by: EventSchedule.displaySort)
    }

    /// Groups filtered events by day for the grid (masters filtered once).
    func eventsGroupedByDay(
        in interval: DateInterval,
        matching criteria: EventSearchCriteria
    ) -> [Date: [Event]] {
        if criteria.isEmpty {
            return eventsGroupedByDay(in: interval)
        }

        var contentCriteria = criteria
        // Intersect explicit interval with the grid window when both exist.
        if let criteriaInterval = criteria.dateInterval {
            let start = max(interval.start, criteriaInterval.start)
            let end = min(interval.end, criteriaInterval.end)
            guard start < end else { return [:] }
            contentCriteria.dateInterval = DateInterval(start: start, end: end)
        } else {
            contentCriteria.dateInterval = interval
            contentCriteria.onDate = criteria.onDate
        }

        var grouped: [Date: [Event]] = [:]
        for master in events {
            guard contentCriteria.matches(master) else { continue }
            guard matchesDateConstraint(master, criteria: contentCriteria) else { continue }

            let queryInterval = contentCriteria.dateInterval ?? interval
            let occurrences = recurrenceEngine.occurrences(of: master, in: queryInterval)
            for occurrence in occurrences {
                let spanEnd = occurrence.occurrenceEnd ?? occurrence.occurrenceStart
                let days = EventSchedule.dayStarts(
                    from: occurrence.occurrenceStart,
                    through: spanEnd,
                    calendar: calendar
                )
                let presentation = occurrence.asEvent()
                for day in days where day >= interval.start && day < interval.end {
                    if let onDate = criteria.onDate,
                       calendar.isDate(day, inSameDayAs: onDate) == false {
                        continue
                    }
                    grouped[day, default: []].append(presentation)
                }
            }
        }

        for day in grouped.keys {
            var seen: Set<UUID> = []
            let unique = (grouped[day] ?? []).filter { seen.insert($0.id).inserted }
            grouped[day] = unique.sorted(by: EventSchedule.displaySort)
        }
        return grouped
    }

    // MARK: - Private date matching

    /// Evaluates ``onDate`` / ``dateInterval`` with recurrence expansion when needed.
    private func matchesDateConstraint(
        _ master: Event,
        criteria: EventSearchCriteria
    ) -> Bool {
        if let onDate = criteria.onDate {
            if recurrenceEngine.occurrences(of: master, on: onDate).isEmpty {
                return false
            }
        }
        if let interval = criteria.dateInterval {
            if recurrenceEngine.occurrences(of: master, in: interval).isEmpty {
                // Fallback: multi-day master that starts before interval but spans into it.
                if EventSchedule.occurs(
                    on: interval.start,
                    start: master.date,
                    end: master.endDate,
                    calendar: calendar
                ) {
                    return true
                }
                return false
            }
        }
        return true
    }
}
