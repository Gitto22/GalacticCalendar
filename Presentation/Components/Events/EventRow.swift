//
//  EventRow.swift
//  GalacticCalendar
//

import SwiftUI

/// Single event row for the day events list.
///
/// Shows event color, title, time, and status.
/// Tap edits; long-press reveals Edit / Duplicate / Delete.
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

    /// Invoked from the context menu Delete action.
    private let onDelete: () -> Void

    // MARK: - Lifecycle

    /// Creates an event row.
    /// - Parameters:
    ///   - event: Event to display.
    ///   - onTap: Primary tap handler (edit).
    ///   - onEdit: Context-menu edit handler.
    ///   - onDuplicate: Context-menu duplicate handler.
    ///   - onDelete: Context-menu delete handler.
    init(
        event: Event,
        onTap: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDuplicate: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.event = event
        self.onTap = onTap
        self.onEdit = onEdit
        self.onDuplicate = onDuplicate
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
                }

                Spacer(minLength: Spacing.xs)

                Text(statusText)
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.onImageAccent)
                    .lineLimit(1)
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

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(String(localized: "day_events_action_delete"), systemImage: Icons.Events.delete)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Subviews

    /// Leading color disk from ``EventColor``.
    private var colorIndicator: some View {
        Circle()
            .fill(ColorPalette.color(for: event.color))
            .frame(
                width: LayoutConstants.eventColorDotSize,
                height: LayoutConstants.eventColorDotSize
            )
            .accessibilityHidden(true)
    }

    // MARK: - Content Helpers

    /// Localized short time for the event.
    private var timeText: String {
        event.date.formatted(date: .omitted, time: .shortened)
    }

    /// Localized status title.
    private var statusText: String {
        EventEditorDisplayNames.title(for: event.status)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Event Row") {
    EventRow(
        event: Event(
            title: "Reunión de equipo",
            date: Date(),
            status: .pending,
            color: .green
        ),
        onTap: {},
        onEdit: {},
        onDuplicate: {},
        onDelete: {}
    )
    .padding(Spacing.pageHorizontal)
    .background(MonthBackgroundView())
    .environment(ThemeManager())
}
#endif
