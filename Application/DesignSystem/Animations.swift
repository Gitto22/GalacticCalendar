//
//  Animations.swift
//  GalacticCalendar
//

import SwiftUI

/// Reusable animation tokens for Galactic Calendar.
///
/// Prefer ``Motion`` for calendar chrome (month change, selection, backgrounds).
/// Prefer these tokens for editor / generic control feedback.
enum Animations {

    // MARK: - Durations

    /// Short interaction duration.
    static let shortDuration: Double = 0.18

    /// Standard interaction duration.
    static let regularDuration: Double = 0.28

    /// Long emphasis duration.
    static let longDuration: Double = 0.45

    // MARK: - Curves

    /// Quick snappy animation for compact UI feedback.
    static let snappy = Animation.easeInOut(duration: shortDuration)

    /// Standard animation for most UI transitions.
    static let standard = Animation.easeInOut(duration: regularDuration)

    /// Emphasized animation for larger layout changes.
    static let emphasized = Animation.easeInOut(duration: longDuration)

    /// Spring used for interactive affordances.
    static let interactive = Animation.spring(response: 0.32, dampingFraction: 0.86)

    /// Soft spring used for background and ambient transitions.
    static let ambient = Animation.spring(response: 0.55, dampingFraction: 0.90)
}

// MARK: - View Convenience

extension View {

    /// Applies a Design System animation when the given value changes.
    /// - Parameters:
    ///   - animation: Animation token.
    ///   - value: Value that triggers the animation.
    /// - Returns: Modified view.
    func appAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        self.animation(animation, value: value)
    }
}
