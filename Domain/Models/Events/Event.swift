//
//  Event.swift
//  GalacticCalendar
//

import Foundation

/// Recurrence rule for a Galactic Calendar event.
enum EventRepeatRule: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {

    // MARK: - Cases

    /// Event does not repeat.
    case none

    /// Event repeats every day.
    case daily

    /// Event repeats every week.
    case weekly

    /// Event repeats every month.
    case monthly

    /// Event repeats every year.
    case yearly

    // MARK: - Identifiable

    /// Stable identifier matching the raw value.
    var id: String { rawValue }
}

/// Domain entity representing a calendar event.
///
/// Pure Foundation model prepared for SwiftData / CloudKit persistence later.
struct Event: Identifiable, Equatable, Sendable, Hashable, Codable {

    // MARK: - Identity

    /// Stable unique identifier.
    let id: UUID

    // MARK: - Content

    /// Event title.
    var title: String

    /// Optional longer description.
    var description: String

    /// Date and time of the event.
    var date: Date

    /// Optional reminder fire date.
    var reminder: Date?

    /// Recurrence rule.
    var repeatRule: EventRepeatRule

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
    ///   - date: Event date.
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
        reminder: Date? = nil,
        repeatRule: EventRepeatRule = .none,
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
    /// Copies content fields and assigns a fresh identity and timestamps.
    /// - Parameter date: Optional date override for the duplicate. Defaults to the source date.
    /// - Returns: Independent event copy suitable for ``EventPersistenceService/create(_:)``.
    func duplicated(on date: Date? = nil) -> Event {
        let now = Date()
        return Event(
            id: UUID(),
            title: title,
            description: description,
            date: date ?? self.date,
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
