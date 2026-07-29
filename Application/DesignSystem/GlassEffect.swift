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

/// Shape variants supported by the Galactic glass system.
enum GlassShapeStyle: Sendable {

    // MARK: - Cases

    /// Rounded rectangular glass used by Home cards.
    case roundedRect

    /// Circular glass used by Home header controls.
    case circle
}

/// Reusable glass (frosted) effect modifier with optional Galactic glow.
struct GlassEffectModifier: ViewModifier {

    // MARK: - Properties

    /// Visual intensity of the glass material.
    let intensity: GlassIntensity

    /// Geometry applied to the glass surface.
    let shapeStyle: GlassShapeStyle

    /// Corner radius used by rounded rectangular glass.
    let cornerRadius: CGFloat

    /// Whether the approved blue-to-purple glow stroke is applied.
    let showsGlow: Bool

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .background { glassBackground }
            .overlay { glassStroke }
    }

    // MARK: - Background

    /// Frosted fill clipped to the selected glass shape.
    @ViewBuilder
    private var glassBackground: some View {
        switch shapeStyle {
        case .roundedRect:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(material)
                .background(ColorPalette.cardFill, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        case .circle:
            Circle()
                .fill(material)
                .background(ColorPalette.controlFill, in: Circle())
        }
    }

    // MARK: - Stroke

    /// Separator or glow stroke matching the approved Home chrome.
    @ViewBuilder
    private var glassStroke: some View {
        if showsGlow {
            glowStroke
                .appShadow(shapeStyle == .circle ? Shadows.glowControl : Shadows.glowCard)
        } else {
            plainStroke
        }
    }

    /// Neutral separator stroke for non-glow glass.
    @ViewBuilder
    private var plainStroke: some View {
        switch shapeStyle {
        case .roundedRect:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(ColorPalette.separator.opacity(strokeOpacity), lineWidth: Spacing.cardStroke)
        case .circle:
            Circle()
                .stroke(ColorPalette.separator.opacity(strokeOpacity), lineWidth: Spacing.headerControlStroke)
        }
    }

    /// Approved glow stroke for Galactic surfaces.
    @ViewBuilder
    private var glowStroke: some View {
        switch shapeStyle {
        case .roundedRect:
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(GlassEffect.linearGlowGradient, lineWidth: Spacing.cardStroke)
        case .circle:
            Circle()
                .stroke(GlassEffect.angularGlowGradient, lineWidth: Spacing.headerControlStroke)
        }
    }

    // MARK: - Tokens

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
            ColorPalette.glassStrokeSubtleOpacity
        case .regular:
            ColorPalette.glassStrokeRegularOpacity
        case .prominent:
            ColorPalette.glassStrokeProminentOpacity
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

    // MARK: - Gradients

    /// Linear glow used by rounded Galactic cards.
    static var linearGlowGradient: LinearGradient {
        LinearGradient(
            colors: [
                ColorPalette.glowStart,
                ColorPalette.glowEnd,
                ColorPalette.glowStart
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Angular glow used by circular Galactic controls.
    static var angularGlowGradient: AngularGradient {
        AngularGradient(
            colors: [
                ColorPalette.glowStart,
                ColorPalette.glowEnd,
                ColorPalette.glowStart
            ],
            center: .center
        )
    }

    /// Compact linear glow used by decorative badges.
    static var badgeGlowGradient: LinearGradient {
        LinearGradient(
            colors: [ColorPalette.glowStart, ColorPalette.glowEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
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
        modifier(
            GlassEffectModifier(
                intensity: intensity,
                shapeStyle: .roundedRect,
                cornerRadius: cornerRadius,
                showsGlow: false
            )
        )
    }

    /// Applies the approved Galactic glass card treatment.
    /// - Parameters:
    ///   - intensity: Frosted intensity token.
    ///   - cornerRadius: Corner radius token.
    /// - Returns: Modified view.
    func galacticGlassCard(
        _ intensity: GlassIntensity = .subtle,
        cornerRadius: CGFloat = GlassEffect.defaultCornerRadius
    ) -> some View {
        modifier(
            GlassEffectModifier(
                intensity: intensity,
                shapeStyle: .roundedRect,
                cornerRadius: cornerRadius,
                showsGlow: true
            )
        )
    }

    /// Applies the approved Galactic glass circle treatment.
    /// - Parameter intensity: Frosted intensity token.
    /// - Returns: Modified view.
    func galacticGlassCircle(
        _ intensity: GlassIntensity = .subtle
    ) -> some View {
        modifier(
            GlassEffectModifier(
                intensity: intensity,
                shapeStyle: .circle,
                cornerRadius: 0,
                showsGlow: true
            )
        )
    }
}
