//
//  RecurrenceEngine.swift
//  GalacticCalendar
//

import Foundation

/// Expands ``Event`` recurrence rules into virtual ``EventOccurrence`` values.
///
/// ## Contract
/// - Never writes SwiftData rows — occurrences are computed only.
/// - Honors multi-day ``Event/endDate`` duration on every occurrence.
/// - Query windows bound unbounded series (``.never`` end).
///
/// ## Complexity
/// Roughly O(k) per event for k occurrences intersecting the window, with an
/// O(1)/O(log)-ish advance toward the window start for daily/weekly/biweekly.
struct RecurrenceEngine: Sendable {

    // MARK: - Properties

    /// Calendar used for month/year stepping and day boundaries.
    private let calendar: Calendar

    /// Safety cap on generated occurrences per query.
    private let maximumOccurrences: Int

    // MARK: - Lifecycle

    /// Creates an expansion engine.
    /// - Parameters:
    ///   - calendar: Calendar for date arithmetic (Monday-first optional).
    ///   - maximumOccurrences: Hard stop per event/query (default 500).
    init(calendar: Calendar = .current, maximumOccurrences: Int = 500) {
        self.calendar = calendar
        self.maximumOccurrences = max(1, maximumOccurrences)
    }

    // MARK: - Public API

    /// Occurrences of ``event`` whose schedule overlaps ``interval``.
    /// - Parameters:
    ///   - event: Master stored event.
    ///   - interval: Query window (`end` exclusive preferred).
    /// - Returns: Occurrences sorted by start ascending.
    func occurrences(
        of event: Event,
        in interval: DateInterval
    ) -> [EventOccurrence] {
        let rule = event.repeatRule.asRecurrenceRule
        let duration = eventDuration(event)
        let seriesStart = event.startDate

        guard rule.isRecurring else {
            guard scheduleOverlaps(
                start: seriesStart,
                end: seriesStart.addingTimeInterval(duration),
                interval: interval
            ) else {
                return []
            }
            return [
                EventOccurrence(
                    master: event,
                    occurrenceStart: seriesStart,
                    occurrenceEnd: event.endDate.map { _ in seriesStart.addingTimeInterval(duration) },
                    occurrenceIndex: 1
                )
            ]
        }

        return expandRecurring(
            event: event,
            rule: rule,
            seriesStart: seriesStart,
            duration: duration,
            interval: interval
        )
    }

    /// Occurrences that overlap a single calendar day.
    func occurrences(of event: Event, on day: Date) -> [EventOccurrence] {
        let dayStart = calendar.startOfDay(for: day)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return []
        }
        return occurrences(
            of: event,
            in: DateInterval(start: dayStart, end: dayEnd)
        )
    }

    /// `true` when any occurrence overlaps the calendar day of ``day``.
    func occurs(_ event: Event, on day: Date) -> Bool {
        occurrences(of: event, on: day).isEmpty == false
    }

    // MARK: - Expansion

    private func expandRecurring(
        event: Event,
        rule: RecurrenceRule,
        seriesStart: Date,
        duration: TimeInterval,
        interval: DateInterval
    ) -> [EventOccurrence] {
        let seekStart = interval.start.addingTimeInterval(-duration)
        var (cursor, index) = firstOccurrence(onOrAfter: seekStart, seriesStart: seriesStart, rule: rule)
        var results: [EventOccurrence] = []
        results.reserveCapacity(16)

        var steps = 0
        let maxSteps = maximumOccurrences * 4

        while steps < maxSteps, results.count < maximumOccurrences {
            steps += 1

            if isSeriesFinished(occurrenceStart: cursor, index: index, rule: rule) {
                break
            }

            // Past the window far enough that later starts cannot overlap.
            if cursor >= interval.end {
                break
            }

            let occurrenceEnd = event.endDate == nil
                ? nil
                : cursor.addingTimeInterval(duration)
            let rangeEnd = occurrenceEnd ?? cursor

            if scheduleOverlaps(start: cursor, end: rangeEnd, interval: interval),
               isExcluded(cursor, rule: rule) == false {
                results.append(
                    EventOccurrence(
                        master: event,
                        occurrenceStart: cursor,
                        occurrenceEnd: occurrenceEnd,
                        occurrenceIndex: index
                    )
                )
            }

            guard let next = nextDate(after: cursor, rule: rule) else {
                break
            }
            if next <= cursor {
                break
            }
            cursor = next
            index += 1
        }

        return results
    }

    /// Finds the first occurrence start ≥ ``target``, counting indices from the series start.
    private func firstOccurrence(
        onOrAfter target: Date,
        seriesStart: Date,
        rule: RecurrenceRule
    ) -> (date: Date, index: Int) {
        if target <= seriesStart {
            return (seriesStart, 1)
        }

        var cursor = seriesStart
        var index = 1
        var steps = 0

        // Fast path for fixed-length periods.
        if let jumped = jumpForward(from: seriesStart, toward: target, rule: rule) {
            cursor = jumped.date
            index = jumped.index
        }

        while cursor < target, steps < maximumOccurrences * 4 {
            steps += 1
            if isSeriesFinished(occurrenceStart: cursor, index: index, rule: rule) {
                break
            }
            guard let next = nextDate(after: cursor, rule: rule) else {
                break
            }
            if next <= cursor {
                break
            }
            cursor = next
            index += 1
        }
        return (cursor, index)
    }

    private func jumpForward(
        from seriesStart: Date,
        toward target: Date,
        rule: RecurrenceRule
    ) -> (date: Date, index: Int)? {
        let interval = max(1, rule.interval)
        let delta = target.timeIntervalSince(seriesStart)
        guard delta > 0 else {
            return nil
        }

        switch rule.frequency {
        case .never:
            return nil
        case .daily:
            let days = Int(delta / 86_400)
            let steps = max(0, days / interval)
            guard let date = calendar.date(byAdding: .day, value: steps * interval, to: seriesStart) else {
                return nil
            }
            return (date, steps + 1)
        case .weekly:
            let days = Int(delta / 86_400)
            let steps = max(0, days / (7 * interval))
            guard let date = calendar.date(byAdding: .day, value: steps * 7 * interval, to: seriesStart) else {
                return nil
            }
            return (date, steps + 1)
        case .biweekly:
            let days = Int(delta / 86_400)
            let period = 14 * interval
            let steps = max(0, days / period)
            guard let date = calendar.date(byAdding: .day, value: steps * period, to: seriesStart) else {
                return nil
            }
            return (date, steps + 1)
        case .monthly, .yearly:
            // Calendar month/year lengths vary — walk from an approximate index.
            return nil
        }
    }

    private func nextDate(after date: Date, rule: RecurrenceRule) -> Date? {
        let interval = max(1, rule.interval)
        switch rule.frequency {
        case .never:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: interval, to: date)
        case .weekly:
            return calendar.date(byAdding: .day, value: 7 * interval, to: date)
        case .biweekly:
            return calendar.date(byAdding: .day, value: 14 * interval, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: interval, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: interval, to: date)
        }
    }

    private func isSeriesFinished(
        occurrenceStart: Date,
        index: Int,
        rule: RecurrenceRule
    ) -> Bool {
        switch rule.end {
        case .never:
            return false
        case .after(let count):
            return index > max(1, count)
        case .onDate(let endDate):
            let endDay = calendar.startOfDay(for: endDate)
            let startDay = calendar.startOfDay(for: occurrenceStart)
            return startDay > endDay
        }
    }

    private func isExcluded(_ occurrenceStart: Date, rule: RecurrenceRule) -> Bool {
        guard rule.excludedDates.isEmpty == false else {
            return false
        }
        let day = calendar.startOfDay(for: occurrenceStart)
        return rule.excludedDates.contains { calendar.isDate($0, inSameDayAs: day) }
    }

    private func eventDuration(_ event: Event) -> TimeInterval {
        guard let end = event.endDate else {
            return 0
        }
        return max(0, end.timeIntervalSince(event.startDate))
    }

    private func scheduleOverlaps(start: Date, end: Date, interval: DateInterval) -> Bool {
        start < interval.end && end >= interval.start
    }
}
