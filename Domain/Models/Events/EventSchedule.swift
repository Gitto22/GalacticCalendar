//
//  EventSchedule.swift
//  GalacticCalendar
//

import Foundation

/// Schedule helpers for timed, all-day, and multi-day events.
///
/// ## Persistence
/// Start is stored as ``Event/date`` (``Event/startDate`` alias). End is
/// ``Event/endDate``. ``Event/isMultiDay`` is derived — no extra SwiftData column.
///
/// ## Recurrence readiness
/// Occurrence expansion (Sprint 6.3+) should reuse ``occurs(on:start:end:calendar:)``
/// and ``dayStarts(from:through:calendar:)`` per generated window without changing
/// the stored ``RepeatRule`` encoding.
enum EventSchedule: Sendable {

    // MARK: - Normalization

    /// Normalizes start/end for an all-day event on a single calendar day.
    ///
    /// - Parameters:
    ///   - date: Any instant on the intended day.
    ///   - timeZoneIdentifier: IANA zone used for day boundaries.
    /// - Returns: `(startOfDay, endOfDay)` absolute instants.
    static func normalizeSameDayAllDay(
        date: Date,
        timeZoneIdentifier: String
    ) -> (date: Date, endDate: Date) {
        normalizeAllDay(
            start: date,
            end: date,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }

    /// Normalizes an all-day range to start-of-day … end-of-day (inclusive days).
    ///
    /// When ``end`` falls on a later day than ``start``, the span is preserved
    /// (multi-day all-day). If ``end`` is before ``start``, it is clamped to ``start``.
    /// - Parameters:
    ///   - start: Any instant on the start day.
    ///   - end: Any instant on the end day (or `nil` → same as start).
    ///   - timeZoneIdentifier: IANA zone for day boundaries.
    /// - Returns: Normalized `(startOfDay, endOfDay)` absolute instants.
    static func normalizeAllDay(
        start: Date,
        end: Date?,
        timeZoneIdentifier: String
    ) -> (date: Date, endDate: Date) {
        let calendar = calendar(for: timeZoneIdentifier)
        let startDay = calendar.startOfDay(for: start)
        let endSource = max(end ?? start, start)
        let endDay = calendar.startOfDay(for: endSource)
        let endOfEndDay =
            calendar.date(byAdding: DateComponents(day: 1, second: -1), to: endDay)
            ?? endDay.addingTimeInterval(86_399)
        return (startDay, endOfEndDay)
    }

    /// Applies all-day or timed schedule rules before persistence.
    ///
    /// Timed events pass through unchanged (caller must ensure ``endDate >= date``).
    /// All-day events normalize to inclusive day bounds, supporting multi-day spans.
    /// - Parameters:
    ///   - isAllDay: Whether the event occupies whole calendar days.
    ///   - date: Start instant.
    ///   - endDate: Optional end instant.
    ///   - timeZoneIdentifier: IANA zone for day boundaries.
    /// - Returns: Normalized `(date, endDate)`.
    static func normalizedBounds(
        isAllDay: Bool,
        date: Date,
        endDate: Date?,
        timeZoneIdentifier: String
    ) -> (date: Date, endDate: Date?) {
        guard isAllDay else {
            if let endDate, endDate < date {
                return (date, date)
            }
            return (date, endDate)
        }
        let bounds = normalizeAllDay(
            start: date,
            end: endDate,
            timeZoneIdentifier: timeZoneIdentifier
        )
        return (bounds.date, bounds.endDate)
    }

    // MARK: - Multi-day

    /// Returns whether start and end fall on different calendar days.
    static func spansMultipleCalendarDays(
        date: Date,
        endDate: Date?,
        timeZoneIdentifier: String
    ) -> Bool {
        guard let endDate else {
            return false
        }
        let calendar = calendar(for: timeZoneIdentifier)
        return calendar.isDate(date, inSameDayAs: endDate) == false
    }

    /// Returns whether an event schedule overlaps the calendar day of ``day``.
    ///
    /// Inclusive of the start day through the end day. Timed events ending at
    /// exactly ``day`` start still count on that day.
    /// - Parameters:
    ///   - day: Any instant on the queried day.
    ///   - start: Event start instant (``Event/date``).
    ///   - end: Event end instant, or `nil` for instantaneous / start-only.
    ///   - calendar: Calendar for day boundaries (typically catalog calendar).
    /// - Returns: `true` when the event should appear on that day.
    static func occurs(
        on day: Date,
        start: Date,
        end: Date?,
        calendar: Calendar
    ) -> Bool {
        let dayStart = calendar.startOfDay(for: day)
        guard let dayEndExclusive = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return false
        }
        let rangeEnd = end ?? start
        let rangeStart = min(start, rangeEnd)
        let rangeFinish = max(start, rangeEnd)
        return rangeStart < dayEndExclusive && rangeFinish >= dayStart
    }

    /// Returns inclusive start-of-day dates from ``start`` through ``end``.
    ///
    /// Caps runaway ranges at ``maximumDayCount`` for safety.
    /// - Parameters:
    ///   - start: Range start instant.
    ///   - end: Range end instant.
    ///   - calendar: Calendar for day arithmetic.
    ///   - maximumDayCount: Safety cap (default 400 ≈ 13 months).
    /// - Returns: Ordered day-start dates (never empty when dates are valid).
    static func dayStarts(
        from start: Date,
        through end: Date,
        calendar: Calendar,
        maximumDayCount: Int = 400
    ) -> [Date] {
        let startDay = calendar.startOfDay(for: min(start, end))
        let endDay = calendar.startOfDay(for: max(start, end))
        var days: [Date] = []
        days.reserveCapacity(min(maximumDayCount, 32))
        var cursor = startDay
        var count = 0
        while cursor <= endDay, count < maximumDayCount {
            days.append(cursor)
            count += 1
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else {
                break
            }
            cursor = next
        }
        return days.isEmpty ? [startDay] : days
    }

    // MARK: - Quick Operations

    /// Builds a start instant on ``day`` preserving wall-clock time from ``timeSource``.
    ///
    /// All-day events resolve to the start of ``day`` in ``timeZoneIdentifier``.
    static func start(
        onDay day: Date,
        timeFrom timeSource: Date,
        isAllDay: Bool,
        timeZoneIdentifier: String
    ) -> Date {
        let calendar = calendar(for: timeZoneIdentifier)
        if isAllDay {
            return calendar.startOfDay(for: day)
        }
        let dayStart = calendar.startOfDay(for: day)
        let timeParts = calendar.dateComponents(
            [.hour, .minute, .second],
            from: timeSource
        )
        return calendar.date(byAdding: timeParts, to: dayStart) ?? dayStart
    }

    /// Shifts ``date`` / ``endDate`` so the start becomes ``newStart``, keeping duration.
    static func shiftedBounds(
        date: Date,
        endDate: Date?,
        to newStart: Date,
        isAllDay: Bool,
        timeZoneIdentifier: String
    ) -> (date: Date, endDate: Date?) {
        let duration: TimeInterval
        if let endDate {
            duration = max(0, endDate.timeIntervalSince(date))
        } else {
            duration = 0
        }
        let provisionalEnd: Date? = duration > 0 ? newStart.addingTimeInterval(duration) : nil
        return normalizedBounds(
            isAllDay: isAllDay,
            date: newStart,
            endDate: provisionalEnd,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }

    /// Maps a target start chosen against a presented occurrence onto the master series.
    ///
    /// When ``presented`` is a virtual occurrence, the series shifts by the day delta
    /// between the presented occurrence and ``targetStart`` so the whole series moves
    /// relative to the tapped occurrence.
    static func resolvedMasterStart(
        master: Event,
        presented: Event,
        targetStart: Date,
        calendar: Calendar = .current
    ) -> Date {
        let presentedDay = calendar.startOfDay(for: presented.date)
        let targetDay = calendar.startOfDay(for: targetStart)
        let dayDelta = calendar.dateComponents([.day], from: presentedDay, to: targetDay).day ?? 0

        guard let shiftedMaster = calendar.date(byAdding: .day, value: dayDelta, to: master.date) else {
            return targetStart
        }

        if master.isAllDay {
            return start(
                onDay: shiftedMaster,
                timeFrom: master.date,
                isAllDay: true,
                timeZoneIdentifier: master.timeZoneIdentifier
            )
        }

        let targetTime = calendar.dateComponents([.hour, .minute, .second], from: targetStart)
        let presentedTime = calendar.dateComponents([.hour, .minute, .second], from: presented.date)
        let timeChanged =
            targetTime.hour != presentedTime.hour
            || targetTime.minute != presentedTime.minute
            || targetTime.second != presentedTime.second

        if timeChanged == false {
            return shiftedMaster
        }

        let shiftedDay = calendar.startOfDay(for: shiftedMaster)
        return calendar.date(byAdding: targetTime, to: shiftedDay) ?? shiftedMaster
    }

    // MARK: - Display Ordering

    /// Day-list sort: all-day first (including multi-day all-day), then by start ascending.
    static func displaySort(_ lhs: Event, _ rhs: Event) -> Bool {
        if lhs.isAllDay != rhs.isAllDay {
            return lhs.isAllDay && rhs.isAllDay == false
        }
        if lhs.startDate != rhs.startDate {
            return lhs.startDate < rhs.startDate
        }
        if lhs.endDate != rhs.endDate {
            switch (lhs.endDate, rhs.endDate) {
            case let (l?, r?):
                return l < r
            case (_?, nil):
                return false
            case (nil, _?):
                return true
            case (nil, nil):
                break
            }
        }
        return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
    }

    // MARK: - Private

    private static func calendar(for timeZoneIdentifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current
        return calendar
    }
}
