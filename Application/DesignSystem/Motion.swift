//
//  Motion.swift
//  GalacticCalendar
//

import SwiftUI

/// Discrete SwiftUI animation tokens for the Calendar Experience.
///
/// Durations stay within 0.20…0.35s. Views own animation; ViewModels stay pure.
/// Generic UI feedback uses ``Animations``; calendar chrome uses these named tokens.
/// Shared durations reference ``Animations`` so timing stays single-sourced.
enum Motion {

    // MARK: - Calendar Experience (Sprint 5.6)

    /// Month grid / period change (chevrons, swipe, today, pickers).
    static let calendarMonthChange = Animation.easeInOut(duration: Animations.regularDuration)

    /// Selected / today day highlight indicator.
    static let calendarSelection = Animation.easeInOut(duration: 0.22)

    /// Monthly background crossfade.
    static let calendarBackground = Animation.easeInOut(duration: 0.32)

    /// Header month name and year text.
    static let calendarHeader = Animation.easeInOut(duration: 0.25)

    /// Event indicator appearance under day cells.
    static let calendarEvents = Animation.easeOut(duration: 0.30)

    // MARK: - Accessibility

    /// Returns ``animation`` unless Reduce Motion is enabled.
    /// - Parameters:
    ///   - animation: Proposed animation.
    ///   - reduceMotion: `accessibilityReduceMotion` environment value.
    /// - Returns: Animation or `nil` when motion should be reduced.
    static func resolved(
        _ animation: Animation,
        reduceMotion: Bool
    ) -> Animation? {
        reduceMotion ? nil : animation
    }
}
