//
//  ColorPalette.swift
//  GalacticCalendar
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Semantic color tokens for Galactic Calendar.
///
/// Views must consume colors exclusively through this palette.
enum ColorPalette {

    // MARK: - Core

    /// Primary brand color used for key interactive emphasis.
    static let primary = Color.adaptive(
        light: Color(red: 0.23, green: 0.42, blue: 0.85),
        dark: Color(red: 0.42, green: 0.61, blue: 1.00)
    )

    /// Secondary brand color used for supporting emphasis.
    static let secondary = Color.adaptive(
        light: Color(red: 0.39, green: 0.49, blue: 0.64),
        dark: Color(red: 0.62, green: 0.71, blue: 0.84)
    )

    /// Base application background.
    static let background = Color.adaptive(
        light: Color(red: 0.95, green: 0.96, blue: 0.98),
        dark: Color(red: 0.04, green: 0.06, blue: 0.13)
    )

    /// Elevated surface color for panels and cards.
    static let surface = Color.adaptive(
        light: Color(red: 1.00, green: 1.00, blue: 1.00),
        dark: Color(red: 0.08, green: 0.11, blue: 0.18)
    )

    /// Accent color for highlights and focal calls to action.
    static let accent = Color.adaptive(
        light: Color(red: 0.10, green: 0.64, blue: 0.72),
        dark: Color(red: 0.37, green: 0.92, blue: 0.83)
    )

    // MARK: - Feedback

    /// Success state color.
    static let success = Color.adaptive(
        light: Color(red: 0.20, green: 0.66, blue: 0.33),
        dark: Color(red: 0.30, green: 0.85, blue: 0.45)
    )

    /// Warning state color.
    static let warning = Color.adaptive(
        light: Color(red: 0.90, green: 0.60, blue: 0.05),
        dark: Color(red: 1.00, green: 0.72, blue: 0.20)
    )

    /// Danger state color.
    static let danger = Color.adaptive(
        light: Color(red: 0.86, green: 0.20, blue: 0.22),
        dark: Color(red: 1.00, green: 0.35, blue: 0.35)
    )

    // MARK: - Content

    /// Primary readable text color.
    static let textPrimary = Color.adaptive(
        light: Color(red: 0.08, green: 0.10, blue: 0.16),
        dark: Color(red: 0.96, green: 0.97, blue: 0.99)
    )

    /// Secondary readable text color.
    static let textSecondary = Color.adaptive(
        light: Color(red: 0.35, green: 0.40, blue: 0.48),
        dark: Color(red: 0.70, green: 0.75, blue: 0.84)
    )

    /// Tertiary readable text color.
    static let textTertiary = Color.adaptive(
        light: Color(red: 0.55, green: 0.59, blue: 0.66),
        dark: Color(red: 0.52, green: 0.57, blue: 0.66)
    )

    /// Subtle separator color.
    static let separator = Color.adaptive(
        light: Color(red: 0.85, green: 0.87, blue: 0.91),
        dark: Color(red: 0.20, green: 0.24, blue: 0.33)
    )

    /// Overlay scrim used above imagery when readability must be preserved.
    static let overlay = Color.black.opacity(0.28)

    // MARK: - On Image (Home)

    /// Primary text and icon color drawn over monthly backgrounds.
    static let onImagePrimary = Color.white

    /// Accent text color for year and month-change affordances over imagery.
    static let onImageAccent = Color(red: 0.45, green: 0.78, blue: 1.00)

    /// Leading glow color used by circular Home controls.
    static let glowStart = Color(red: 0.35, green: 0.75, blue: 1.00)

    /// Trailing glow color used by circular Home controls.
    static let glowEnd = Color(red: 0.62, green: 0.42, blue: 1.00)

    /// Translucent fill used inside circular Home controls.
    static let controlFill = Color.black.opacity(0.28)

    /// Translucent fill used by Home cards over monthly backgrounds.
    static let cardFill = Color.black.opacity(0.42)

    /// Purple accent used by Universe Message quotes and captions.
    static let universeAccent = Color(red: 0.72, green: 0.48, blue: 1.00)

    // MARK: - Glass Opacities

    /// Opacity used by subtle glass separator strokes.
    static let glassStrokeSubtleOpacity = 0.35

    /// Opacity used by regular glass separator strokes.
    static let glassStrokeRegularOpacity = 0.45

    /// Opacity used by prominent glass separator strokes.
    static let glassStrokeProminentOpacity = 0.55

    /// Opacity used by circular control glow shadows.
    static let glowControlShadowOpacity = 0.55

    /// Opacity used by card glow shadows.
    static let glowCardShadowOpacity = 0.45

    // MARK: - Calendar

    /// Weekend text color for Saturday and Sunday labels/numbers.
    static let weekend = Color(red: 1.00, green: 0.42, blue: 0.48)

    /// Fill used by day cells over the monthly background.
    static let dayCellFill = Color.black.opacity(0.32)

    /// Subtle border used by non-highlighted day cells.
    static let dayCellBorder = Color.white.opacity(0.10)

    /// Opacity applied to days outside the visible month.
    static let dayOutsideOpacity = 0.35

    /// First event indicator color (purple).
    static let eventIndicatorPurple = Color(red: 0.72, green: 0.48, blue: 1.00)

    /// Second event indicator color (green).
    static let eventIndicatorGreen = Color(red: 0.30, green: 0.85, blue: 0.52)

    /// Third event indicator color (blue).
    static let eventIndicatorBlue = Color(red: 0.45, green: 0.78, blue: 1.00)

    /// Fourth event indicator color (orange).
    static let eventIndicatorOrange = Color(red: 1.00, green: 0.62, blue: 0.28)

    /// Ordered palette used by event indicator dots.
    static let eventIndicatorColors: [Color] = [
        eventIndicatorPurple,
        eventIndicatorGreen,
        eventIndicatorBlue,
        eventIndicatorOrange
    ]

    // MARK: - Event Editor

    /// Green token for ``EventColor/green``.
    static let eventColorGreen = Color(red: 0.30, green: 0.85, blue: 0.52)

    /// Yellow token for ``EventColor/yellow``.
    static let eventColorYellow = Color(red: 1.00, green: 0.86, blue: 0.28)

    /// Orange token for ``EventColor/orange``.
    static let eventColorOrange = Color(red: 1.00, green: 0.62, blue: 0.28)

    /// Red token for ``EventColor/red``.
    static let eventColorRed = Color(red: 1.00, green: 0.35, blue: 0.40)

    /// Purple accent used by event editor icons and highlights.
    static let editorAccent = universeAccent

    /// Placeholder text color inside the event editor.
    static let editorPlaceholder = Color.white.opacity(0.45)

    /// Fill used by editor selector tiles.
    static let editorTileFill = Color.black.opacity(0.35)

    /// Returns the Design System color for an event color token.
    static func color(for eventColor: EventColor) -> Color {
        switch eventColor {
        case .green: eventColorGreen
        case .yellow: eventColorYellow
        case .orange: eventColorOrange
        case .red: eventColorRed
        }
    }
}

// MARK: - Adaptive Color Support

private extension Color {

    /// Creates a color that adapts to light and dark appearances.
    /// - Parameters:
    ///   - light: Color used in light appearance.
    ///   - dark: Color used in dark appearance.
    /// - Returns: Adaptive ``Color``.
    static func adaptive(light: Color, dark: Color) -> Color {
        #if canImport(UIKit)
        Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
            }
        )
        #elseif canImport(AppKit)
        Color(
            nsColor: NSColor(name: nil) { appearance in
                let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                return NSColor(isDark ? dark : light)
            }
        )
        #else
        light
        #endif
    }
}
