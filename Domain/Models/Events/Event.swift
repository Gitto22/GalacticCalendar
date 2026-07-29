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
    var date: Date

    /// Optional end date and time (absolute instant). `nil` means no explicit end.
    var endDate: Date?

    /// IANA time zone identifier used when the schedule was edited.
    ///
    /// Stored for CloudKit / multi-device display. Absolute `date` / `endDate`
    /// values remain timezone-independent Foundation instants.
    var timeZoneIdentifier: String

    /// Optional reminder fire date.
    var reminder: Date?

    /// Recurrence rule (stored and restored; occurrences are not expanded yet).
    var repeatRule: RepeatRule

    // MARK: - Classification

    /// Event category.
    var category: EventCategory

    /// Event priority.
    var priority: EventPriority

    /// Event status.
    var status: EventStatus

    /// Event accent color token.
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
    ///   - timeZoneIdentifier: IANA time zone id. Defaults to the current zone.
    ///   - reminder: Optional reminder date.
    ///   - repeatRule: Recurrence rule.
    ///   - category: Category.
    ///   - priority: Priority.
    ///   - status: Status.
    ///   - color: Color token.
    ///   - createdAt: Creation date.
    ///   - updatedAt: Last update date.
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        date: Date,
        endDate: Date? = nil,
        timeZoneIdentifier: String = TimeZone.current.identifier,
        reminder: Date? = nil,
        repeatRule: RepeatRule = .none,
        category: EventCategory = .other,
        priority: EventPriority = .medium,
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
        self.timeZoneIdentifier = timeZoneIdentifier
        self.reminder = reminder
        self.repeatRule = repeatRule
        self.category = category
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

    /// Returns a new event ready to be persisted as a duplicate.
    ///
    /// Copies content fields (including ``repeatRule``) and assigns a fresh identity.
    /// - Parameter date: Optional date override for the duplicate. Defaults to the source date.
    /// - Returns: Independent event copy suitable for ``EventPersistenceService/create(_:)``.
    func duplicated(on date: Date? = nil) -> Event {
        let now = Date()
        let start = date ?? self.date
        let resolvedEnd: Date? = {
            guard let endDate else {
                return nil
            }
            guard let date else {
                return endDate
            }
            let duration = endDate.timeIntervalSince(self.date)
            return start.addingTimeInterval(duration)
        }()

        return Event(
            id: UUID(),
            title: title,
            description: description,
            date: start,
            endDate: resolvedEnd,
            timeZoneIdentifier: timeZoneIdentifier,
            reminder: reminder,
            repeatRule: repeatRule,
            category: category,
            priority: priority,
            status: status,
            color: color,
            createdAt: now,
            updatedAt: now
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
