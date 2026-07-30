//
//  AgendaTimelineBuilder.swift
//  GalacticCalendar
//

import Foundation

/// Pure Domain builder for Smart Daily Agenda timelines and free-time gaps.
///
/// ## Responsibilities
/// - Partition all-day vs timed events.
/// - Merge overlapping timed intervals inside a working window.
/// - Detect free blocks and build a chronological timeline.
/// - Compute occupied / free totals and the next upcoming timed event.
///
/// ## Non-responsibilities
/// - No persistence, notifications, or SwiftUI.
enum AgendaTimelineBuilder: Sendable {

    // MARK: - Configuration

    /// Domain-owned agenda defaults (no Config dependency).
    enum Defaults {
        /// Inclusive start hour (local) for free-time / occupied calculations.
        static let workingDayStartHour: Int = 8

        /// Exclusive end hour (local) for the agenda working window (20:00).
        static let workingDayEndHour: Int = 20

        /// Fallback timed duration when an event has no ``endDate`` (1 hour).
        static let defaultEventDuration: TimeInterval = 3_600
    }

    /// Local working-hours window used for free-time detection.
    struct WorkingHours: Equatable, Sendable {
        var startHour: Int
        var endHour: Int

        static let `default` = WorkingHours(
            startHour: Defaults.workingDayStartHour,
            endHour: Defaults.workingDayEndHour
        )

        var durationSeconds: TimeInterval {
            TimeInterval(max(0, endHour - startHour) * 3_600)
        }
    }

    // MARK: - Build

    /// Builds a full agenda snapshot for ``day``.
    ///
    /// - Parameters:
    ///   - events: Day events from the catalog (`events(on:)`), any order.
    ///   - day: Agenda calendar day.
    ///   - now: Clock for “next event” (injectable in tests).
    ///   - calendar: Calendar for day / hour arithmetic.
    ///   - workingHours: Free-time window (default 08:00–20:00).
    ///   - defaultDuration: Used when a timed event has no end.
    static func build(
        events: [Event],
        day: Date,
        now: Date = Date(),
        calendar: Calendar = .current,
        workingHours: WorkingHours = .default,
        defaultDuration: TimeInterval = Defaults.defaultEventDuration
    ) -> AgendaDaySnapshot {
        let dayStart = calendar.startOfDay(for: day)
        let sorted = events.sorted(by: EventSchedule.displaySort)
        let allDay = sorted.filter(\.isAllDay)
        let timed = sorted.filter { $0.isAllDay == false }

        guard
            let windowStart = calendar.date(
                bySettingHour: workingHours.startHour,
                minute: 0,
                second: 0,
                of: dayStart
            ),
            let windowEnd = calendar.date(
                bySettingHour: workingHours.endHour,
                minute: 0,
                second: 0,
                of: dayStart
            ),
            windowEnd > windowStart
        else {
            return emptySnapshot(day: dayStart, allDay: allDay, timed: timed)
        }

        let busy = mergedBusyIntervals(
            timed: timed,
            windowStart: windowStart,
            windowEnd: windowEnd,
            defaultDuration: defaultDuration
        )
        let freeBlocks = freeBlocks(in: windowStart..<windowEnd, busy: busy)
        let occupied = busy.reduce(TimeInterval(0)) { $0 + $1.duration }
        let windowSeconds = windowEnd.timeIntervalSince(windowStart)
        let freeSeconds = max(0, windowSeconds - occupied)

        let timeline = makeTimeline(timed: timed, freeBlocks: freeBlocks)
        let next = nextEvent(in: timed, day: dayStart, now: now, calendar: calendar)

        let summary = AgendaDaySummary(
            day: dayStart,
            eventCount: allDay.count + timed.count,
            allDayCount: allDay.count,
            timedCount: timed.count,
            occupiedSeconds: occupied,
            freeSeconds: freeSeconds,
            windowSeconds: windowSeconds
        )

        return AgendaDaySnapshot(
            summary: summary,
            allDayEvents: allDay,
            timedEvents: timed,
            freeBlocks: freeBlocks,
            timeline: timeline,
            nextEvent: next
        )
    }

    // MARK: - Interval math

    struct TimeIntervalRange: Equatable, Sendable {
        var start: Date
        var end: Date

        var duration: TimeInterval {
            max(0, end.timeIntervalSince(start))
        }
    }

    /// Clips and merges overlapping timed events inside the working window.
    static func mergedBusyIntervals(
        timed: [Event],
        windowStart: Date,
        windowEnd: Date,
        defaultDuration: TimeInterval
    ) -> [TimeIntervalRange] {
        var ranges: [TimeIntervalRange] = []
        ranges.reserveCapacity(timed.count)

        for event in timed {
            let rawEnd = event.endDate ?? event.startDate.addingTimeInterval(defaultDuration)
            let start = max(event.startDate, windowStart)
            let end = min(max(rawEnd, event.startDate), windowEnd)
            guard end > start else { continue }
            ranges.append(TimeIntervalRange(start: start, end: end))
        }

        guard ranges.isEmpty == false else { return [] }

        let ordered = ranges.sorted { $0.start < $1.start }
        var merged: [TimeIntervalRange] = [ordered[0]]
        for range in ordered.dropFirst() {
            guard var last = merged.last else { continue }
            if range.start <= last.end {
                last.end = max(last.end, range.end)
                merged[merged.count - 1] = last
            } else {
                merged.append(range)
            }
        }
        return merged
    }

    /// Free gaps between ``window`` bounds given merged busy intervals.
    static func freeBlocks(
        in window: Range<Date>,
        busy: [TimeIntervalRange]
    ) -> [AgendaFreeBlock] {
        var cursor = window.lowerBound
        var blocks: [AgendaFreeBlock] = []
        for interval in busy {
            if interval.start > cursor {
                blocks.append(AgendaFreeBlock(start: cursor, end: interval.start))
            }
            cursor = max(cursor, interval.end)
        }
        if cursor < window.upperBound {
            blocks.append(AgendaFreeBlock(start: cursor, end: window.upperBound))
        }
        return blocks.filter { $0.duration >= 60 }
    }

    /// Next timed event after ``now`` when viewing today; otherwise first timed of the day.
    static func nextEvent(
        in timed: [Event],
        day: Date,
        now: Date,
        calendar: Calendar
    ) -> Event? {
        let ordered = timed.sorted { $0.startDate < $1.startDate }
        guard ordered.isEmpty == false else { return nil }

        if calendar.isDate(day, inSameDayAs: now) {
            return ordered.first { $0.startDate > now }
        }
        if day > calendar.startOfDay(for: now) {
            return ordered.first
        }
        return nil
    }

    // MARK: - Private

    private static func makeTimeline(
        timed: [Event],
        freeBlocks: [AgendaFreeBlock]
    ) -> [AgendaTimelineItem] {
        var items: [AgendaTimelineItem] = []
        items.reserveCapacity(timed.count + freeBlocks.count)
        items.append(contentsOf: timed.map { .event($0) })
        items.append(contentsOf: freeBlocks.map { .free($0) })
        return items.sorted { lhs, rhs in
            if lhs.sortDate != rhs.sortDate {
                return lhs.sortDate < rhs.sortDate
            }
            // Events before free blocks that start at the same instant.
            switch (lhs, rhs) {
            case (.event, .free):
                return true
            case (.free, .event):
                return false
            default:
                return false
            }
        }
    }

    private static func emptySnapshot(
        day: Date,
        allDay: [Event],
        timed: [Event]
    ) -> AgendaDaySnapshot {
        AgendaDaySnapshot(
            summary: AgendaDaySummary(
                day: day,
                eventCount: allDay.count + timed.count,
                allDayCount: allDay.count,
                timedCount: timed.count,
                occupiedSeconds: 0,
                freeSeconds: 0,
                windowSeconds: 0
            ),
            allDayEvents: allDay,
            timedEvents: timed,
            freeBlocks: [],
            timeline: timed.map { .event($0) },
            nextEvent: timed.sorted { $0.startDate < $1.startDate }.first
        )
    }
}
