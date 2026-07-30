//
//  FreeTimeCard.swift
//  GalacticCalendar
//

import SwiftUI

/// Free-time gap row on the Smart Daily Agenda timeline.
struct FreeTimeCard: View {

    let rangeText: String
    let durationText: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            RoundedRectangle(cornerRadius: Spacing.Radius.xxs, style: .continuous)
                .fill(ColorPalette.editorAccent.opacity(ColorPalette.glassStrokeRegularOpacity))
                .frame(width: Spacing.accentBarWidth)
                .padding(.vertical, Spacing.xxxs)

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(String(localized: "agenda_free_time_title"))
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorPalette.onImageAccent)
                Text(rangeText)
                    .font(Typography.footnote)
                    .foregroundStyle(ColorPalette.editorPlaceholder)
            }

            Spacer(minLength: Spacing.xs)

            Text(durationText)
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.editorPlaceholder)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: Spacing.Radius.md, style: .continuous)
                    .stroke(
                        ColorPalette.separator.opacity(ColorPalette.glassStrokeSubtleOpacity),
                        style: StrokeStyle(
                            lineWidth: Spacing.hairline,
                            dash: [Spacing.xxs, Spacing.xxs]
                        )
                    )
            }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text("\(String(localized: "agenda_free_time_title")), \(rangeText), \(durationText)")
        )
    }
}
