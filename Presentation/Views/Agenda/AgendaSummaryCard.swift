//
//  AgendaSummaryCard.swift
//  GalacticCalendar
//

import SwiftUI

/// Day summary / end-of-day metrics card for the Smart Daily Agenda.
struct AgendaSummaryCard: View {

    enum Style {
        case header
        case endOfDay
    }

    let style: Style
    let weekdayTitle: String
    let dateTitle: String
    let eventCount: Int
    let occupiedText: String
    let freeText: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if style == .header {
                Text(weekdayTitle)
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.editorPlaceholder)
                Text(dateTitle)
                    .font(Typography.title2)
                    .foregroundStyle(ColorPalette.onImagePrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(LayoutConstants.singleLineMinimumScale)
            } else {
                Text(String(localized: "agenda_end_of_day_title"))
                    .font(Typography.headline)
                    .foregroundStyle(ColorPalette.onImagePrimary)
                Text(
                    String(
                        format: String(localized: "agenda_completed_format"),
                        locale: .current,
                        eventCount
                    )
                )
                .font(Typography.callout)
                .foregroundStyle(ColorPalette.onImageAccent)
            }

            metricsRow
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .galacticGlassCard(.subtle, cornerRadius: Spacing.Radius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(style == .header ? "agenda_summary_header" : "agenda_summary_end")
    }

    private var metricsRow: some View {
        HStack(spacing: Spacing.md) {
            metric(
                title: String(localized: "agenda_metric_events"),
                value: "\(eventCount)"
            )
            metric(
                title: String(localized: "agenda_metric_occupied"),
                value: occupiedText
            )
            metric(
                title: String(localized: "agenda_metric_free"),
                value: freeText
            )
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxxs) {
            Text(title)
                .font(Typography.caption2)
                .foregroundStyle(ColorPalette.editorPlaceholder)
            Text(value)
                .font(Typography.subheadline)
                .foregroundStyle(ColorPalette.onImagePrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var accessibilityLabel: String {
        "\(dateTitle), \(eventCount) \(String(localized: "agenda_metric_events")), \(occupiedText), \(freeText)"
    }
}
