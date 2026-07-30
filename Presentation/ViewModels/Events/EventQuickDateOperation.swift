//
//  EventQuickDateOperation.swift
//  GalacticCalendar
//

import Foundation

/// Quick schedule operations hosted by the day-events list (Sprint 6.6).
///
/// Share one date/time sheet; persistence stays on ``EventPersistenceService``.
enum EventQuickDateOperation: String, Equatable, Sendable, Identifiable {

    /// Move / reprogram the persisted event (same identity).
    case move

    /// Create a content copy on another date (new identity).
    case copy

    var id: String { rawValue }

    /// Navigation title for the shared sheet.
    var title: String {
        switch self {
        case .move:
            String(localized: "event_quick_op_move_title")
        case .copy:
            String(localized: "event_quick_op_copy_title")
        }
    }

    /// Primary confirm button label.
    var confirmTitle: String {
        switch self {
        case .move:
            String(localized: "event_quick_op_move_confirm")
        case .copy:
            String(localized: "event_quick_op_copy_confirm")
        }
    }
}
