//
//  EventsRevisionRefresh.swift
//  GalacticCalendar
//

import Foundation

/// Builds SwiftUI identities that change when event indicators on a day change.
///
/// ``CalendarDay/id`` alone is date-based; appending count and colors forces
/// cell refresh after catalog mutations without altering layout.
enum CalendarDayRefreshIdentity {

    // MARK: - API

    /// - Parameter day: Annotated calendar day.
    /// - Returns: Stable refresh token for `.id(...)`.
    static func token(for day: CalendarDay) -> String {
        let colors = day.eventColors.map(\.rawValue).joined(separator: ",")
        return "\(day.id)#\(day.eventCount)#\(colors)"
    }
}
