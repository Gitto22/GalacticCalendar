//
//  TimelineView.swift
//  GalacticCalendar
//

import SwiftUI

/// Chronological timeline of timed events and free blocks.
struct AgendaTimelineView: View {

    let items: [AgendaTimelineItem]
    let durationText: (Event) -> String
    let freeRangeText: (AgendaFreeBlock) -> String
    let freeDurationText: (AgendaFreeBlock) -> String
    let onEventTap: (Event) -> Void

    /// Time-column width scales with Dynamic Type (default matches approved 56pt).
    @ScaledMetric(relativeTo: .caption) private var timeColumnWidth: CGFloat = 56

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "agenda_timeline_title"))
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.editorPlaceholder)

            if items.isEmpty {
                Text(String(localized: "agenda_timeline_empty"))
                    .font(Typography.callout)
                    .foregroundStyle(ColorPalette.editorPlaceholder)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Spacing.sm)
            } else {
                ForEach(items) { item in
                    switch item {
                    case .event(let event):
                        eventRow(event)
                    case .free(let block):
                        FreeTimeCard(
                            rangeText: freeRangeText(block),
                            durationText: freeDurationText(block)
                        )
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func eventRow(_ event: Event) -> some View {
        Button {
            onEventTap(event)
        } label: {
            HStack(alignment: .top, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(event.startDate.formatted(date: .omitted, time: .shortened))
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.editorPlaceholder)
                    Text(durationText(event))
                        .font(Typography.caption2)
                        .foregroundStyle(ColorPalette.onImageAccent)
                }
                .frame(width: timeColumnWidth, alignment: .leading)

                Circle()
                    .fill(ColorPalette.color(for: event.color))
                    .frame(
                        width: LayoutConstants.eventColorDotSize,
                        height: LayoutConstants.eventColorDotSize
                    )
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(event.title)
                        .font(Typography.headline)
                        .foregroundStyle(ColorPalette.onImagePrimary)
                        .lineLimit(2)

                    HStack(spacing: Spacing.xxs) {
                        Text(EventEditorDisplayNames.title(for: event.priority))
                            .font(Typography.caption2)
                            .foregroundStyle(ColorPalette.editorPlaceholder)
                        if event.tags.isEmpty == false {
                            Text("·")
                                .foregroundStyle(ColorPalette.editorPlaceholder)
                            Text(
                                event.tags.prefix(2)
                                    .map { EventEditorDisplayNames.title(for: $0) }
                                    .joined(separator: ", ")
                            )
                            .font(Typography.caption2)
                            .foregroundStyle(ColorPalette.onImageAccent)
                            .lineLimit(1)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: Spacing.Radius.md, style: .continuous)
                    .fill(ColorPalette.editorTileFill)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            Text("\(event.title), \(event.startDate.formatted(date: .omitted, time: .shortened)), \(durationText(event))")
        )
    }
}
