//
//  Event.swift
//  GalacticCalendar
//

import Foundation

/// Domain entity representing a calendar event.
///
/// Pure Foundation model prepared for SwiftData / CloudKit persistence.
struct Event: Identifiable, Equatable, Sendable, Hashable, Codable {

    // MARK: - Identity

    /// Stable unique identifier.
    let id: UUID

    // MARK: - Content

    /// Event title.
    var title: String

    /// Optional longer description.
    var description: String

    /// Start date and time of the event (absolute instant).
    ///
    /// Persisted field name kept as `date` for SwiftData / CloudKit compatibility.
    /// Prefer ``startDate`` at call sites. For all-day events, normalized to the
    /// start of the calendar day in ``timeZoneIdentifier`` (see ``EventSchedule``).
    var date: Date

    /// Optional end date and time (absolute instant). `nil` means no explicit end.
    ///
    /// For all-day events, normalized to the end of the last calendar day in the
    /// span. A later-day value creates a multi-day event (``isMultiDay``).
    var endDate: Date?

    /// `true` when the event occupies whole calendar day(s) (no wall-clock times).
    ///
    /// Compatible with future recurrence expansion and CloudKit mirroring.
    var isAllDay: Bool

    /// IANA time zone identifier used when the schedule was edited.
    ///
    /// Stored for CloudKit / multi-device display. Absolute `date` / `endDate`
    /// values remain timezone-independent Foundation instants.
    var timeZoneIdentifier: String

    /// Optional reminder fire date.
    var reminder: Date?

    /// Recurrence rule (stored and restored).
    ///
    /// Occurrences are expanded dynamically by ``RecurrenceEngine`` — never
    /// persisted as separate rows. Reserved fields on ``RecurrenceRule``
    /// (`byWeekdays`, `excludedDates`, custom payload) prepare Sprint 6.4+.
    var repeatRule: RepeatRule

    // MARK: - Classification

    /// Legacy single category (kept for CloudKit / older clients).
    ///
    /// Prefer ``tags`` for multi-label organization. When tags include presets,
    /// ``category`` is synced from the first preset for compatibility.
    var category: EventCategory

    /// Zero or more organization tags (presets + future custom).
    var tags: [EventTag]

    /// Event priority (low / normal / high / urgent).
    var priority: EventPriority

    /// Event status.
    var status: EventStatus

    /// Event accent color token from the Design System palette.
    var color: EventColor

    // MARK: - Timestamps

    /// Creation timestamp.
    let createdAt: Date

    /// Last update timestamp.
    var updatedAt: Date

    // MARK: - Lifecycle

    /// Creates an event.
    /// - Parameters:
    ///   - id: Unique identifier.
    ///   - title: Event title.
    ///   - description: Event description.
    ///   - date: Start date and time.
    ///   - endDate: Optional end date and time.
    ///   - isAllDay: Whether the event is all-day.
    ///   - timeZoneIdentifier: IANA time zone id. Defaults to the current zone.
    ///   - reminder: Optional reminder date.
    ///   - repeatRule: Recurrence rule.
    ///   - category: Legacy single category.
    ///   - tags: Organization tags (multiple allowed).
    ///   - priority: Priority.
    ///   - status: Status.
    ///   - color: Color token from the Design System palette.
    ///   - createdAt: Creation date.
    ///   - updatedAt: Last update date.
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        date: Date,
        endDate: Date? = nil,
        isAllDay: Bool = false,
        timeZoneIdentifier: String = TimeZone.current.identifier,
        reminder: Date? = nil,
        repeatRule: RepeatRule = .none,
        category: EventCategory = .other,
        tags: [EventTag] = [],
        priority: EventPriority = .normal,
        status: EventStatus = .pending,
        color: EventColor = .green,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.date = date
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.timeZoneIdentifier = timeZoneIdentifier
        self.reminder = reminder
        self.repeatRule = repeatRule
        if tags.isEmpty, let preset = EventTagPreset.from(category: category) {
            self.tags = [.preset(preset)]
        } else {
            self.tags = tags
        }
        if let firstPreset = self.tags.compactMap(\.preset).first {
            self.category = firstPreset.asCategory
        } else {
            self.category = category
        }
        self.priority = priority
        self.status = status
        self.color = color
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Mutation Helpers

extension Event {

    /// Returns a copy marked as updated at the provided timestamp.
    /// - Parameter date: Update timestamp. Defaults to now.
    /// - Returns: Updated event copy.
    func touchingUpdatedAt(_ date: Date = Date()) -> Event {
        var copy = self
        copy.updatedAt = date
        return copy
    }

    /// Returns a new event ready to be persisted as a duplicate / copy.
    ///
    /// Copies content fields (title, description/notes, color, tags, priority,
    /// recurrence, duration, all-day, time zone). Assigns a fresh identity and
    /// resets ``status`` to ``EventStatus/pending``.
    ///
    /// Does **not** keep the source absolute date/time unless ``date`` is omitted
    /// (then the schedule is still rematerialized with a recomputed reminder).
    /// Reminder fire dates are recomputed from the relative offset of the source.
    /// - Parameter date: Optional start override for the duplicate.
    /// - Returns: Independent event copy suitable for ``EventPersistenceService/create(_:)``.
    func duplicated(on date: Date? = nil) -> Event {
        let now = Date()
        let start = date ?? self.date
        let bounds = EventSchedule.shiftedBounds(
            date: self.date,
            endDate: endDate,
            to: start,
            isAllDay: isAllDay,
            timeZoneIdentifier: timeZoneIdentifier
        )
        let reminderOffset = EventReminderOption.option(for: reminder, eventDate: self.date)
        let resolvedReminder = reminderOffset.reminderDate(relativeTo: bounds.date)

        return Event(
            id: UUID(),
            title: title,
            description: description,
            date: bounds.date,
            endDate: bounds.endDate,
            isAllDay: isAllDay,
            timeZoneIdentifier: timeZoneIdentifier,
            reminder: resolvedReminder,
            repeatRule: repeatRule,
            category: category,
            tags: tags,
            priority: priority,
            status: .pending,
            color: color,
            createdAt: now,
            updatedAt: now
        )
    }

    /// Returns this event with its schedule moved to ``newStart`` (same identity).
    ///
    /// Preserves content, status, recurrence, and relative reminder offset.
    /// Used by Move / Reprogramar quick operations.
    /// - Parameter newStart: Absolute start after the move / reschedule.
    /// - Returns: Updated snapshot for ``EventPersistenceService/update(_:)``.
    func rescheduled(to newStart: Date) -> Event {
        let bounds = EventSchedule.shiftedBounds(
            date: date,
            endDate: endDate,
            to: newStart,
            isAllDay: isAllDay,
            timeZoneIdentifier: timeZoneIdentifier
        )
        let reminderOffset = EventReminderOption.option(for: reminder, eventDate: date)
        var copy = self
        copy.date = bounds.date
        copy.endDate = bounds.endDate
        copy.reminder = reminderOffset.reminderDate(relativeTo: bounds.date)
        copy.updatedAt = Date()
        return copy
    }
}

// MARK: - Schedule Helpers

extension Event {

    /// Start of the event (alias of ``date`` for multi-day / editor APIs).
    ///
    /// Not a separate persistence column — keeps CloudKit / legacy rows compatible.
    var startDate: Date {
        get { date }
        set { date = newValue }
    }

    /// `true` when ``endDate`` falls on a different calendar day than ``startDate``.
    var isMultiDay: Bool {
        EventSchedule.spansMultipleCalendarDays(
            date: date,
            endDate: endDate,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }

    /// `true` when ``endDate`` falls on a different calendar day than ``date``.
    ///
    /// Prefer ``isMultiDay``; kept as a synonym for Sprint 6.1 call sites.
    var spansMultipleCalendarDays: Bool {
        isMultiDay
    }

    /// Returns whether this event should appear on the given calendar day.
    /// - Parameters:
    ///   - day: Any instant on the queried day.
    ///   - calendar: Calendar for day boundaries.
    /// - Returns: `true` when the schedule overlaps that day.
    func occurs(on day: Date, calendar: Calendar = .current) -> Bool {
        EventSchedule.occurs(
            on: day,
            start: startDate,
            end: endDate,
            calendar: calendar
        )
    }
}

// MARK: - Local Reminder Helpers

extension Event {

    /// Builds the stable local-notification identifier for an event id.
    /// - Parameter eventID: Event identifier.
    /// - Returns: Notification request identifier.
    static func reminderNotificationIdentifier(for eventID: UUID) -> String {
        "galactic.event.reminder.\(eventID.uuidString)"
    }

    /// Stable local-notification identifier for this event's reminder.
    var reminderNotificationIdentifier: String {
        Self.reminderNotificationIdentifier(for: id)
    }

    /// `true` when ``reminder`` exists and is strictly after `now`.
    /// - Parameter now: Reference instant. Defaults to the current date.
    /// - Returns: Whether a local notification should be scheduled.
    func shouldScheduleReminder(relativeTo now: Date = Date()) -> Bool {
        guard let reminder else {
            return false
        }
        return reminder > now
    }
}
