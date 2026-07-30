//
//  FlowTagPicker.swift
//  GalacticCalendar
//

import SwiftUI

/// Compact wrap-style preset tag toggles for the event editor.
struct FlowTagPicker: View {

    // MARK: - Properties

    let presets: [EventTagPreset]
    let isSelected: (EventTagPreset) -> Bool
    let title: (EventTagPreset) -> String
    let onToggle: (EventTagPreset) -> Void

    // MARK: - Body

    var body: some View {
        FlexibleTagLayout(spacing: Spacing.xxs) {
            ForEach(presets) { preset in
                Button {
                    onToggle(preset)
                } label: {
                    Text(title(preset))
                        .font(Typography.caption2)
                        .foregroundStyle(
                            isSelected(preset)
                                ? ColorPalette.onImagePrimary
                                : ColorPalette.editorPlaceholder
                        )
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxxs)
                        .background {
                            Capsule(style: .continuous)
                                .fill(
                                    isSelected(preset)
                                        ? ColorPalette.editorAccent.opacity(ColorPalette.glassStrokeSubtleOpacity)
                                        : ColorPalette.editorTileFill
                                )
                        }
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(
                                    isSelected(preset)
                                        ? ColorPalette.editorAccent
                                        : ColorPalette.separator.opacity(ColorPalette.glassStrokeSubtleOpacity),
                                    lineWidth: LayoutConstants.dayCellBorderStroke
                                )
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(title(preset)))
                .accessibilityHint(Text(String(localized: "event_search_filter_a11y_hint")))
                .accessibilityValue(
                    Text(
                        isSelected(preset)
                            ? String(localized: "calendar_day_selected_a11y")
                            : String(localized: "calendar_day_not_selected_a11y")
                    )
                )
                .accessibilityAddTraits(isSelected(preset) ? [.isSelected, .isButton] : .isButton)
                .accessibilityIdentifier("event_editor_tag_\(preset.rawValue)")
            }
        }
    }
}

/// Simple wrapping layout for tag chips (avoids LazyVGrid column stretch).
private struct FlexibleTagLayout: Layout {

    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(proposal: proposal, subviews: subviews)
        let width = proposal.width ?? rows.map(\.width).max() ?? 0
        let height = rows.reduce(0) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * spacing
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = [Row()]
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let projected = rows[rows.count - 1].width
                + (rows[rows.count - 1].indices.isEmpty ? 0 : spacing)
                + size.width
            if projected > maxWidth, rows[rows.count - 1].indices.isEmpty == false {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            if row.indices.isEmpty == false {
                row.width += spacing
            }
            row.indices.append(index)
            row.width += size.width
            row.height = max(row.height, size.height)
            rows[rows.count - 1] = row
        }
        return rows
    }
}
