//
//  EventRow.swift
//  GalacticCalendar
//

import SwiftUI

/// Single event row for the day events list.
///
/// Shows color, title, schedule, priority, and up to two tags without clutter.
/// Tap edits; long-press reveals Edit / Duplicate / Move / Copy / Delete.
struct EventRow: View {

    // MARK: - Properties

    /// Domain event rendered by this row.
    private let event: Event

    /// Invoked on a primary tap.
    private let onTap: () -> Void

    /// Invoked from the context menu Edit action.
    private let onEdit: () -> Void

    /// Invoked from the context menu Duplicate action.
    private let onDuplicate: () -> Void

    /// Invoked from the context menu Move action.
    private let onMove: () -> Void

    /// Invoked from the context menu Copy action.
    private let onCopy: () -> Void

    /// Invoked from the context menu Delete action.
    private let onDelete: () -> Void

    // MARK: - Lifecycle

    /// Creates an event row.
    init(
        event: Event,
        onTap: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDuplicate: @escaping () -> Void,
        onMove: @escaping () -> Void = {},
        onCopy: @escaping () -> Void = {},
        onDelete: @escaping () -> Void
    ) {
        self.event = event
        self.onTap = onTap
        self.onEdit = onEdit
        self.onDuplicate = onDuplicate
        self.onMove = onMove
        self.onCopy = onCopy
        self.onDelete = onDelete
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: Spacing.sm) {
                colorIndicator

                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(event.title)
                        .font(Typography.headline)
                        .foregroundStyle(ColorPalette.onImagePrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(LayoutConstants.singleLineMinimumScale)

                    Text(timeText)
                        .font(Typography.footnote)
                        .foregroundStyle(ColorPalette.editorPlaceholder)
                        .lineLimit(1)

                    if visibleTags.isEmpty == false {
                        tagsRow
                    }
                }

                Spacer(minLength: Spacing.xs)

                VStack(alignment: .trailing, spacing: Spacing.xxxs) {
                    priorityBadge
                    Text(statusText)
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.onImageAccent)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: Spacing.Radius.md, style: .continuous)
                    .fill(ColorPalette.editorTileFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Spacing.Radius.md, style: .continuous)
                    .stroke(
                        ColorPalette.separator.opacity(ColorPalette.glassStrokeSubtleOpacity),
                        lineWidth: LayoutConstants.dayCellBorderStroke
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: Spacing.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label(String(localized: "day_events_action_edit"), systemImage: Icons.Events.edit)
            }

            Button {
                onDuplicate()
            } label: {
                Label(String(localized: "day_events_action_duplicate"), systemImage: Icons.Events.duplicate)
            }

            Button {
                onMove()
            } label: {
                Label(String(localized: "day_events_action_move"), systemImage: Icons.Events.move)
            }

            Button {
                onCopy()
            } label: {
                Label(String(localized: "day_events_action_copy"), systemImage: Icons.Events.copy)
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(String(localized: "day_events_action_delete"), systemImage: Icons.Events.delete)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint(Text(String(localized: "day_events_row_a11y_hint")))
        .accessibilityValue(Text(statusText))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("event_row_\(event.id.uuidString)")
    }

    // MARK: - Subviews

    /// Leading color disk from ``EventColor`` (Design System palette).
    private var colorIndicator: some View {
        Circle()
            .fill(ColorPalette.color(for: event.color))
            .frame(
                width: LayoutConstants.eventColorDotSize,
                height: LayoutConstants.eventColorDotSize
            )
            .accessibilityHidden(true)
    }

    /// Compact priority label.
    private var priorityBadge: some View {
        HStack(spacing: Spacing.xxxs) {
            if event.priority >= .high {
                Image(systemName: Icons.Events.priorityUp)
                    .font(Typography.caption2)
                    .foregroundStyle(ColorPalette.eventColorRed)
            }
            Text(EventEditorDisplayNames.title(for: event.priority))
                .font(Typography.caption2)
                .foregroundStyle(
                    event.priority >= .urgent
                        ? ColorPalette.eventColorRed
                        : ColorPalette.editorPlaceholder
                )
                .lineLimit(1)
        }
    }

    /// Up to two tag chips.
    private var tagsRow: some View {
        HStack(spacing: Spacing.xxxs) {
            ForEach(visibleTags, id: \.id) { tag in
                Text(EventEditorDisplayNames.title(for: tag))
                    .font(Typography.caption2)
                    .foregroundStyle(ColorPalette.onImageAccent)
                    .padding(.horizontal, Spacing.xxs)
                    .padding(.vertical, 1)
                    .background {
                        Capsule(style: .continuous)
                            .fill(ColorPalette.editorAccent.opacity(0.2))
                    }
            }
            if event.tags.count > visibleTags.count {
                Text("+\(event.tags.count - visibleTags.count)")
                    .font(Typography.caption2)
                    .foregroundStyle(ColorPalette.editorPlaceholder)
            }
        }
    }

    // MARK: - Content Helpers

    private var visibleTags: [EventTag] {
        Array(event.tags.prefix(2))
    }

    private var timeText: String {
        if event.isMultiDay {
            return multiDayScheduleText
        }
        if event.isAllDay {
            return String(localized: "event_all_day_label")
        }
        return event.startDate.formatted(date: .omitted, time: .shortened)
    }

    private var multiDayScheduleText: String {
        let start = event.startDate.formatted(.dateTime.day().month(.abbreviated))
        let endSource = event.endDate ?? event.startDate
        let end = endSource.formatted(.dateTime.day().month(.abbreviated))
        if event.isAllDay {
            return String(
                format: String(localized: "event_multi_day_all_day_format"),
                locale: .current,
                start,
                end
            )
        }
        return String(
            format: String(localized: "event_multi_day_timed_format"),
            locale: .current,
            start,
            end
        )
    }

    private var statusText: String {
        EventEditorDisplayNames.title(for: event.status)
    }

    private var accessibilitySummary: String {
        var parts = [event.title, timeText, EventEditorDisplayNames.title(for: event.priority)]
        parts.append(contentsOf: visibleTags.map(EventEditorDisplayNames.title(for:)))
        return parts.joined(separator: ", ")
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Event Row") {
    EventRow(
        event: Event(
            title: "Reunión de equipo",
            date: Date(),
            tags: [.preset(.work), .preset(.personal)],
            priority: .urgent,
            status: .pending,
            color: .green
        ),
        onTap: {},
        onEdit: {},
        onDuplicate: {},
        onMove: {},
        onCopy: {},
        onDelete: {}
    )
    .padding(Spacing.pageHorizontal)
    .background(MonthBackgroundView())
    .environment(ThemeManager())
    .environment(CalendarAppearanceManager())
}
#endif
