//
//  EventIndicatorsView.swift
//  GalacticCalendar
//

import SwiftUI

/// Circular event indicators shown beneath a day number.
///
/// Matches the approved calendar design:
/// - 0 events → no indicators
/// - 1...4 events → that many circles
/// - more than 4 → four circles, with "+" on the fourth
///
/// Colors come exclusively from ``EventColor`` via ``ColorPalette``.
struct EventIndicatorsView: View {

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Properties

    /// Domain event colors for visible indicators (max four).
    private let eventColors: [EventColor]

    /// Total events on the day (may exceed four).
    private let totalCount: Int

    // MARK: - Lifecycle

    /// Creates indicators from domain event colors and total count.
    /// - Parameters:
    ///   - eventColors: Domain colors for visible indicators.
    ///   - totalCount: Total events on the day (may exceed four).
    init(eventColors: [EventColor], totalCount: Int) {
        self.eventColors = Array(eventColors.prefix(CalendarConstants.maxEventIndicators))
        self.totalCount = max(0, totalCount)
    }

    /// Creates indicators from a domain calendar day.
    /// - Parameter day: Day carrying event colors and count.
    init(day: CalendarDay) {
        self.init(eventColors: day.eventColors, totalCount: day.eventCount)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.xxxs) {
            ForEach(Array(eventColors.enumerated()), id: \.offset) { index, eventColor in
                indicator(
                    color: ColorPalette.color(for: eventColor),
                    showsPlus: showsOverflow && index == eventColors.count - 1
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: LayoutConstants.eventIndicatorSize)
        .opacity(eventColors.isEmpty ? 0 : 1)
        .animation(
            Motion.resolved(Motion.calendarEvents, reduceMotion: reduceMotion),
            value: appearanceToken
        )
        .accessibilityHidden(true)
    }

    // MARK: - Derived

    /// Stable token so indicators animate when count/colors change with the month.
    private var appearanceToken: String {
        let colors = eventColors.map(\.rawValue).joined(separator: ",")
        return "\(totalCount)-\(colors)"
    }

    /// `true` when more events exist than visible indicator slots.
    private var showsOverflow: Bool {
        totalCount > CalendarConstants.maxEventIndicators
    }

    // MARK: - Indicators

    /// Single circular indicator, optionally with overflow plus.
    private func indicator(color: Color, showsPlus: Bool) -> some View {
        ZStack {
            Circle()
                .fill(color)

            if showsPlus {
                Image(systemName: Icons.Events.add)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(ColorPalette.onImagePrimary)
            }
        }
        .frame(
            width: LayoutConstants.eventIndicatorSize,
            height: LayoutConstants.eventIndicatorSize
        )
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Event Indicators") {
    VStack(spacing: Spacing.sm) {
        EventIndicatorsView(eventColors: [], totalCount: 0)
        EventIndicatorsView(eventColors: [.green], totalCount: 1)
        EventIndicatorsView(eventColors: [.green, .yellow], totalCount: 2)
        EventIndicatorsView(
            eventColors: [.green, .yellow, .orange, .red],
            totalCount: 4
        )
        EventIndicatorsView(
            eventColors: [.green, .yellow, .orange, .red],
            totalCount: 6
        )
    }
    .padding()
    .background(ColorPalette.cardFill)
}
#endif
