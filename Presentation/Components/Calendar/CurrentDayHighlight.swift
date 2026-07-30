//
//  CurrentDayHighlight.swift
//  GalacticCalendar
//

import SwiftUI

/// Reusable blue glow highlight for the current or selected day cell.
///
/// Visual treatment comes exclusively from the Design System.
struct CurrentDayHighlight: View {

    // MARK: - Properties

    /// Corner radius applied to the highlight stroke.
    private let cornerRadius: CGFloat

    // MARK: - Lifecycle

    /// Creates a day highlight overlay.
    /// - Parameter cornerRadius: Corner radius token for the stroke shape.
    init(cornerRadius: CGFloat = Spacing.Radius.sm) {
        self.cornerRadius = cornerRadius
    }

    // MARK: - Body

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(ColorPalette.onImageAccent, lineWidth: LayoutConstants.dayHighlightStroke)
            .appShadow(Shadows.dayHighlight)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - View Convenience

extension View {

    /// Overlays ``CurrentDayHighlight`` when `isHighlighted` is true.
    /// - Parameters:
    ///   - isHighlighted: Whether the highlight should appear.
    ///   - cornerRadius: Corner radius token for the highlight.
    /// - Returns: Modified view.
    func currentDayHighlight(
        _ isHighlighted: Bool,
        cornerRadius: CGFloat = Spacing.Radius.sm
    ) -> some View {
        modifier(
            CurrentDayHighlightModifier(
                isHighlighted: isHighlighted,
                cornerRadius: cornerRadius
            )
        )
    }
}

/// Applies a discreet opacity transition to the day highlight.
private struct CurrentDayHighlightModifier: ViewModifier {

    // MARK: - Properties

    let isHighlighted: Bool
    let cornerRadius: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .overlay {
                if isHighlighted {
                    CurrentDayHighlight(cornerRadius: cornerRadius)
                        .transition(.opacity)
                }
            }
            .animation(
                Motion.resolved(Motion.calendarSelection, reduceMotion: reduceMotion),
                value: isHighlighted
            )
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Current Day Highlight") {
    RoundedRectangle(cornerRadius: Spacing.Radius.sm, style: .continuous)
        .fill(ColorPalette.dayCellFill)
        .frame(width: Spacing.xxxl, height: Spacing.xxxl)
        .overlay(CurrentDayHighlight())
        .padding()
        .background(ColorPalette.background)
}
#endif
