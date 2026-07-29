//
//  EventIndicatorsView.swift
//  GalacticCalendar
//

import SwiftUI

/// Circular event indicators shown beneath a day number.
///
/// Renders zero to four dots using ``ColorPalette`` tokens only.
struct EventIndicatorsView: View {

    // MARK: - Properties

    /// Indicator colors to render. Excess values are truncated to four.
    private let colors: [Color]

    // MARK: - Lifecycle

    /// Creates an event indicator row.
    /// - Parameter colors: Colors for each visible indicator.
    init(colors: [Color]) {
        self.colors = Array(colors.prefix(CalendarConstants.maxEventIndicators))
    }

    /// Creates indicators from the shared palette.
    /// - Parameter sampleCount: Number of sample indicators to show (`0...4`).
    init(sampleCount: Int) {
        let clamped = max(0, min(sampleCount, CalendarConstants.maxEventIndicators))
        self.colors = Array(ColorPalette.eventIndicatorColors.prefix(clamped))
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.xxxs) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                Circle()
                    .fill(color)
                    .frame(
                        width: LayoutConstants.eventIndicatorSize,
                        height: LayoutConstants.eventIndicatorSize
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: LayoutConstants.eventIndicatorSize)
        .opacity(colors.isEmpty ? 0 : 1)
        .accessibilityHidden(true)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Event Indicators") {
    VStack(spacing: Spacing.sm) {
        EventIndicatorsView(sampleCount: 0)
        EventIndicatorsView(sampleCount: 2)
        EventIndicatorsView(sampleCount: 4)
    }
    .padding()
    .background(ColorPalette.cardFill)
}
#endif
