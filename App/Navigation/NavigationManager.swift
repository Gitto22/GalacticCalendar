//
//  NavigationManager.swift
//  GalacticCalendar
//

import Foundation
import SwiftUI

/// Owns a reserved ``NavigationPath`` for future shell push routing.
///
/// ## Private Beta (QA-06)
/// Not used by product screens. Feature navigation is modal
/// (`fullScreenCover` / `sheet`). This type remains in the Composition Root
/// so deep-link / Settings push can attach later without a second pattern.
@MainActor
@Observable
final class NavigationManager {

    // MARK: - Properties

    /// Reserved navigation path for future push destinations.
    var path = NavigationPath()

    // MARK: - Stack Operations

    /// Pushes a route onto the navigation stack.
    /// - Parameter route: Destination to present.
    func push(_ route: Route) {
        path.append(route)
    }

    /// Removes the top route from the navigation stack when possible.
    func pop() {
        guard path.isEmpty == false else {
            return
        }

        path.removeLast()
    }

    /// Clears the navigation stack and returns to the root destination.
    func popToRoot() {
        path = NavigationPath()
    }

    /// Replaces the current stack with the provided routes.
    /// - Parameter routes: Ordered destinations to apply.
    func setPath(_ routes: [Route]) {
        var newPath = NavigationPath()
        routes.forEach { newPath.append($0) }
        path = newPath
    }
}
