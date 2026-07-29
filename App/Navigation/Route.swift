//
//  Route.swift
//  GalacticCalendar
//

import Foundation

/// High-level navigation destinations known to the application shell.
///
/// Only infrastructure routes are defined here. Product destinations
/// are added when their modules are connected.
enum Route: Hashable, Sendable {

    // MARK: - Cases

    /// Application root destination.
    case root
}
