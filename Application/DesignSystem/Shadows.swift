//
//  Shadows.swift
//  GalacticCalendar
//

import SwiftUI

/// Reusable shadow style definition.
struct ShadowStyle: Equatable {

    // MARK: - Properties

    /// Shadow color token.
    let color: Color

    /// Blur radius.
    let radius: CGFloat

    /// Horizontal offset.
    let x: CGFloat

    /// Vertical offset.
    let y: CGFloat

    // MARK: - Lifecycle

    /// Creates a shadow style.
    /// - Parameters:
    ///   - color: Shadow color.
    ///   - radius: Blur radius.
    ///   - x: Horizontal offset.
    ///   - y: Vertical offset.
    init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

/// Shadow tokens for Galactic Calendar.
enum Shadows {

    // MARK: - Styles

    /// Soft elevation for subtle separation.
    static let soft = ShadowStyle(
        color: Color.black.opacity(0.12),
        radius: Spacing.xs,
        y: Spacing.xxs
    )

    /// Medium elevation for cards and panels.
    static let medium = ShadowStyle(
        color: Color.black.opacity(0.18),
        radius: Spacing.md,
        y: Spacing.xs
    )

    /// Strong elevation for floating controls.
    static let elevated = ShadowStyle(
        color: Color.black.opacity(0.28),
        radius: Spacing.lg,
        y: Spacing.sm
    )

    /// Glow shadow for circular Home controls.
    static let glowControl = ShadowStyle(
        color: ColorPalette.glowStart.opacity(ColorPalette.glowControlShadowOpacity),
        radius: Spacing.xs,
        y: 0
    )

    /// Glow shadow for Galactic glass cards.
    static let glowCard = ShadowStyle(
        color: ColorPalette.glowEnd.opacity(ColorPalette.glowCardShadowOpacity),
        radius: Spacing.xs,
        y: 0
    )
}

// MARK: - View Convenience

extension View {

    /// Applies a Design System shadow style.
    /// - Parameter style: Shadow token to apply.
    /// - Returns: Modified view.
    func appShadow(_ style: ShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
