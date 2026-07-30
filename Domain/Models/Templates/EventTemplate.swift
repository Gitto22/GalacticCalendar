//
//  EventTemplate.swift
//  GalacticCalendar
//

import Foundation

/// Reusable event blueprint stored offline (no absolute schedule / reminders).
///
/// ## Applied to new events
/// Copies content fields into ``EventEditorViewModel``. Date, wall-clock start,
/// and reminder fire dates are chosen at apply time — never copied from a past event.
struct EventTemplate: Identifiable, Equatable, Sendable, Hashable, Codable {

    // MARK: - Identity

    let id: UUID

    /// User-facing template name (list / picker).
    var name: String

    // MARK: - Content Snapshot

    var title: String
    var description: String
    var isAllDay: Bool

    /// Timed duration in seconds (default 1 hour). For all-day, day-span length.
    var durationSeconds: TimeInterval

    var repeatRule: RepeatRule
    var category: EventCategory
    var tags: [EventTag]
    var priority: EventPriority
    var status: EventStatus
    var color: EventColor

    /// Optional IANA zone preference; `nil` → device current when applying.
    var timeZoneIdentifier: String?

    let createdAt: Date
    var updatedAt: Date

    // MARK: - Lifecycle

    init(
        id: UUID = UUID(),
        name: String,
        title: String,
        description: String = "",
        isAllDay: Bool = false,
        durationSeconds: TimeInterval = 3_600,
        repeatRule: RepeatRule = .none,
        category: EventCategory = .other,
        tags: [EventTag] = [],
        priority: EventPriority = .normal,
        status: EventStatus = .pending,
        color: EventColor = .green,
        timeZoneIdentifier: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? title
            : name
        self.title = title
        self.description = description
        self.isAllDay = isAllDay
        self.durationSeconds = max(60, durationSeconds)
        self.repeatRule = repeatRule
        self.category = category
        self.tags = tags
        self.priority = priority
        self.status = status
        self.color = color
        self.timeZoneIdentifier = timeZoneIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Factories

    /// Builds a template from an existing event (strips absolute dates and reminders).
    static func from(event: Event, name: String? = nil) -> EventTemplate {
        let duration: TimeInterval
        if let end = event.endDate {
            duration = max(60, end.timeIntervalSince(event.startDate))
        } else {
            duration = 3_600
        }
        let resolvedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        return EventTemplate(
            name: (resolvedName?.isEmpty == false ? resolvedName! : event.title),
            title: event.title,
            description: event.description,
            isAllDay: event.isAllDay,
            durationSeconds: duration,
            repeatRule: event.repeatRule,
            category: event.category,
            tags: event.tags,
            priority: event.priority,
            status: event.status,
            color: event.color,
            timeZoneIdentifier: event.timeZoneIdentifier
        )
    }

    // MARK: - Materialization

    /// Schedule bounds for a new event on ``start``, without copying reminders.
    func scheduleBounds(
        on start: Date,
        timeZoneIdentifier: String? = nil
    ) -> (date: Date, endDate: Date?) {
        let zone = timeZoneIdentifier
            ?? self.timeZoneIdentifier
            ?? TimeZone.current.identifier
        if isAllDay {
            let endAnchor = start.addingTimeInterval(durationSeconds)
            let bounds = EventSchedule.normalizeAllDay(
                start: start,
                end: endAnchor,
                timeZoneIdentifier: zone
            )
            return (bounds.date, bounds.endDate)
        }
        return (start, start.addingTimeInterval(durationSeconds))
    }

    /// Returns an independent copy ready to persist as a duplicate template.
    func duplicated(name suffix: String = "") -> EventTemplate {
        let now = Date()
        let trimmed = suffix.trimmingCharacters(in: .whitespacesAndNewlines)
        let newName = trimmed.isEmpty ? name : "\(name) \(trimmed)"
        return EventTemplate(
            id: UUID(),
            name: newName,
            title: title,
            description: description,
            isAllDay: isAllDay,
            durationSeconds: durationSeconds,
            repeatRule: repeatRule,
            category: category,
            tags: tags,
            priority: priority,
            status: status,
            color: color,
            timeZoneIdentifier: timeZoneIdentifier,
            createdAt: now,
            updatedAt: now
        )
    }

    func touchingUpdatedAt(_ date: Date = Date()) -> EventTemplate {
        var copy = self
        copy.updatedAt = date
        return copy
    }
}
