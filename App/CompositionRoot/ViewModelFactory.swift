//
//  ViewModelFactory.swift
//  GalacticCalendar
//

import Foundation

/// Factory reserved for constructing Presentation ViewModels.
///
/// No feature ViewModels are created until their modules are connected.
@MainActor
final class ViewModelFactory {

    // MARK: - Properties

    /// Shared dependency container used by future ViewModel construction.
    private let container: DependencyContainer

    // MARK: - Lifecycle

    /// Creates a factory bound to the Composition Root.
    /// - Parameter container: Application dependency container.
    init(container: DependencyContainer) {
        self.container = container
    }
}
