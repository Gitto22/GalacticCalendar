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

    /// Custom label content.
    private let label: () -> Label

    // MARK: - Lifecycle

    /// Creates a circular glass button with a system image.
    /// - Parameters:
    ///   - systemImage: SF Symbol token.
    ///   - font: Symbol font token.
    ///   - action: Tap handler.
    init(systemImage: String, font: Font, action: @escaping () -> Void) where Label == Image {
        self.font = font
        self.action = action
        self.label = { Image(systemName: systemImage) }
    }

    /// Creates a circular glass button with a custom label.
    /// - Parameters:
    ///   - font: Fallback font applied to the label container.
    ///   - action: Tap handler.
    ///   - label: Custom label builder.
    init(
        font: Font,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.font = font
        self.action = action
        self.label = label
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            label()
                .font(font)
                .foregroundStyle(ColorPalette.onImagePrimary)
                .frame(width: Spacing.headerControlSize, height: Spacing.headerControlSize)
                .galacticGlassCircle(.subtle)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}
