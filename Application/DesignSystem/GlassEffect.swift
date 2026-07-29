//
//  GlassEffect.swift
//  GalacticCalendar
//

import SwiftUI

/// Intensity levels for the reusable glass surface treatment.
enum GlassIntensity: Sendable {

    // MARK: - Cases

    /// Subtle frosted treatment.
    case subtle

    /// Standard frosted treatment.
    case regular

    /// Strong frosted treatment.
    case prominent
}

/// Reusable glass (frosted) effect modifier.
struct GlassEffectModifier: ViewModifier {

    // MARK: - Properties

    /// Visual intensity of the glass material.
    let intensity: GlassIntensity

    /// Corner radius applied to the glass shape.
    let cornerRadius: CGFloat

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .background(material, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(ColorPalette.separator.opacity(strokeOpacity), lineWidth: 1)
            )
    }

    // MARK: - Private

    /// Material resolved from the selected intensity.
    private var material: Material {
        switch intensity {
        case .subtle:
            .ultraThinMaterial
        case .regular:
            .thinMaterial
        case .prominent:
            .regularMaterial
        }
    }

    /// Stroke opacity resolved from the selected intensity.
    private var strokeOpacity: Double {
        switch intensity {
        case .subtle:
            0.35
        case .regular:
            0.45
        case .prominent:
            0.55
        }
    }
}

/// Glass effect tokens and view helpers for Galactic Calendar.
enum GlassEffect {

    // MARK: - Defaults

    /// Default corner radius for glass surfaces.
    static let defaultCornerRadius = Spacing.Radius.lg

    /// Default intensity for glass surfaces.
    static let defaultIntensity = GlassIntensity.regular
}

// MARK: - View Convenience

extension View {

    /// Applies the Design System glass effect.
    /// - Parameters:
    ///   - intensity: Frosted intensity token.
    ///   - cornerRadius: Corner radius token.
    /// - Returns: Modified view.
    func glassEffect(
        _ intensity: GlassIntensity = GlassEffect.defaultIntensity,
        cornerRadius: CGFloat = GlassEffect.defaultCornerRadius
    ) -> some View {
        modifier(GlassEffectModifier(intensity: intensity, cornerRadius: cornerRadius))
    }
}
