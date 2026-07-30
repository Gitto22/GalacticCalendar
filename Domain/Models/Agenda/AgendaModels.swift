//
//  AgendaModels.swift
//  GalacticCalendar
//

import Foundation

/// A free-time gap inside the agenda working window.
struct AgendaFreeBlock: Identifiable, Equatable, Sendable, Hashable {

    let id: UUID
    let start: Date
    let end: Date

    var duration: TimeInterval {
        max(0, end.timeIntervalSince(start))
    }

    init(id: UUID = UUID(), start: Date, end: Date) {
        self.id = id
        self.start = start
        self.end = max(end, start)
    }
}

/// Chronological timeline row for the Smart Daily Agenda.
enum AgendaTimelineItem: Identifiable, Equatable, Sendable {

    case event(Event)
    case free(AgendaFreeBlock)

    var id: String {
        switch self {
        case .event(let event):
            "event-\(event.id.uuidString)-\(Int(event.startDate.timeIntervalSince1970))"
        case .free(let block):
            "free-\(block.id.uuidString)"
        }
    }

    var sortDate: Date {
        switch self {
        case .event(let event):
            event.startDate
        case .free(let block):
            block.start
        }
    }
}

/// Aggregated day metrics for summary / end-of-day cards.
struct AgendaDaySummary: Equatable, Sendable {

    /// Calendar day (start-of-day).
    let day: Date

    /// Total events on the day (all-day + timed).
    let eventCount: Int

    /// All-day event count.
    let allDayCount: Int

    /// Timed event count.
    let timedCount: Int

    /// Occupied seconds inside the working window (merged timed intervals).
    let occupiedSeconds: TimeInterval

    /// Free seconds inside the working window.
    let freeSeconds: TimeInterval

    /// Working window length in seconds.
    let windowSeconds: TimeInterval
}

/// Immutable snapshot produced by ``AgendaTimelineBuilder``.
struct AgendaDaySnapshot: Equatable, Sendable {

    let summary: AgendaDaySummary
    let allDayEvents: [Event]
    let timedEvents: [Event]
    let freeBlocks: [AgendaFreeBlock]
    let timeline: [AgendaTimelineItem]
    let nextEvent: Event?
}
