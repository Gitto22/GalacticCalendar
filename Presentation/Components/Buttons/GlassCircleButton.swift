//
//  GlassCircleButton.swift
//  GalacticCalendar
//

import SwiftUI

/// Reusable circular Galactic glass control.
///
/// Used by the approved Home header and available for other Home chrome.
struct GlassCircleButton<Label: View>: View {

    // MARK: - Properties

    /// Button action. May be empty while feature wiring is deferred.
    private let action: () -> Void

    /// Font applied when rendering system-image labels.
    private let font: Font

    /// Foreground color applied to the label.
    private let foreground: Color

    /// Whether the approved glow stroke is applied.
    private let showsGlow: Bool

    /// Custom label content.
    private let label: () -> Label

    // MARK: - Lifecycle

    /// Creates a circular glass button with a system image.
    /// - Parameters:
    ///   - systemImage: SF Symbol token.
    ///   - font: Symbol font token.
    ///   - foreground: Label color token.
    ///   - showsGlow: Whether the glow stroke is applied.
    ///   - action: Tap handler.
    init(
        systemImage: String,
        font: Font,
        foreground: Color = ColorPalette.onImagePrimary,
        showsGlow: Bool = true,
        action: @escaping () -> Void
    ) where Label == Image {
        self.font = font
        self.foreground = foreground
        self.showsGlow = showsGlow
        self.action = action
        self.label = { Image(systemName: systemImage) }
    }

    /// Creates a circular glass button with a custom label.
    /// - Parameters:
    ///   - font: Fallback font applied to the label container.
    ///   - foreground: Label color token.
    ///   - showsGlow: Whether the glow stroke is applied.
    ///   - action: Tap handler.
    ///   - label: Custom label builder.
    init(
        font: Font,
        foreground: Color = ColorPalette.onImagePrimary,
        showsGlow: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.font = font
        self.foreground = foreground
        self.showsGlow = showsGlow
        self.action = action
        self.label = label
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            label()
                .font(font)
                .foregroundStyle(foreground)
                .frame(width: Spacing.headerControlSize, height: Spacing.headerControlSize)
                .modifier(
                    GlassEffectModifier(
                        intensity: .subtle,
                        shapeStyle: .circle,
                        cornerRadius: 0,
                        showsGlow: showsGlow
                    )
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}
