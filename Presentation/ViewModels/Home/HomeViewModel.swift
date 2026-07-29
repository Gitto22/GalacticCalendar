//
//  HomeViewModel.swift
//  GalacticCalendar
//

import Foundation

/// Presentation model for the Home screen.
///
/// Holds UI state only. Domain logic, persistence, CloudKit, and
/// calendar/event behavior are intentionally out of scope for now.
@MainActor
@Observable
final class HomeViewModel {

    // MARK: - Lifecycle

    /// Creates an empty Home presentation model.
    init() {
        // TODO: Accept injected use cases / managers from the Composition Root.
    }

    // MARK: - State

    // TODO: Expose the currently visible month for background and header binding.
    // TODO: Expose Universe Message presentation state when the feature is connected.
    // TODO: Expose calendar presentation state without implementing calendar logic here.

    // MARK: - Intents

    // TODO: Define user intents for header actions.
    // TODO: Define user intents for calendar interactions when the calendar module is connected.
    // TODO: Define user intents for Universe Message interactions when enabled.
}
