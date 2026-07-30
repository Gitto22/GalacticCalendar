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
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(ColorPalette.editorAccent.opacity(0.45))
                .frame(width: 3)
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
                        style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                    )
            }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text("\(String(localized: "agenda_free_time_title")), \(rangeText), \(durationText)")
        )
    }
}
