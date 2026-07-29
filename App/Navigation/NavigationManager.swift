//
//  NavigationManager.swift
//  GalacticCalendar
//

import Foundation
import SwiftUI

/// Owns the navigation stack used by the application shell.
///
/// Presentation layers mutate navigation exclusively through this type
/// to keep routing concerns out of feature views.
@MainActor
@Observable
final class NavigationManager {

    // MARK: - Properties

    /// Navigation path driving the root ``NavigationStack``.
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
