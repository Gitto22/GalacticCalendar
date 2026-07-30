//
//  CalendarMonthNavigation.swift
//  GalacticCalendar
//

import Foundation

/// Direction for month-to-month navigation (buttons, swipe, future animations).
enum CalendarMonthNavigationDirection: Int, Sendable, Equatable, Hashable {

    // MARK: - Cases

    /// Move toward the previous calendar month (swipe right).
    case previous = -1

    /// Move toward the next calendar month (swipe left).
    case next = 1

    // MARK: - Derived

    /// Month delta applied by ``CalendarEngine/monthByAdding(_:toMonth:year:)``.
    var monthOffset: Int { rawValue }
}

/// Intent describing a month navigation request.
///
/// Views may wrap application of this intent in ``Motion`` animations when
/// ``prefersAnimation`` is `true`. ViewModels apply state changes only.
struct CalendarMonthNavigationIntent: Sendable, Equatable {

    // MARK: - Properties

    /// Previous or next.
    let direction: CalendarMonthNavigationDirection

    /// How many months to move in ``direction`` (minimum `1`).
    let stepCount: Int

    /// When `true`, Presentation may wrap the state change in a discrete animation.
    let prefersAnimation: Bool

    // MARK: - Lifecycle

    /// Creates a navigation intent.
    /// - Parameters:
    ///   - direction: Previous or next.
    ///   - stepCount: Months to advance (clamped to at least 1).
    ///   - prefersAnimation: Whether Presentation should animate the transition.
    init(
        direction: CalendarMonthNavigationDirection,
        stepCount: Int = 1,
        prefersAnimation: Bool = true
    ) {
        self.direction = direction
        self.stepCount = max(1, stepCount)
        self.prefersAnimation = prefersAnimation
    }

    // MARK: - Convenience

    /// Single-step previous month (animated by default).
    static let previous = CalendarMonthNavigationIntent(direction: .previous)

    /// Single-step next month (animated by default).
    static let next = CalendarMonthNavigationIntent(direction: .next)

    /// Total month offset applied to the engine.
    var monthOffset: Int {
        direction.monthOffset * stepCount
    }
}
