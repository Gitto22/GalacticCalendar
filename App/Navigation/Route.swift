//
//  Route.swift
//  GalacticCalendar
//

import Foundation

/// Reserved high-level push destinations for the application shell.
///
/// ## Private Beta (QA-06)
/// Product navigation does **not** use this enum. Home / Calendar / Events /
/// Universe / Agenda present via ``fullScreenCover`` / ``sheet`` owned by
/// feature ViewModels.
///
/// Keep this type for future deep links or Settings push flows without
/// inventing a second product navigation pattern today.
enum Route: Hashable, Sendable {

    // MARK: - Cases

    /// Application root destination (reserved).
    case root
}
