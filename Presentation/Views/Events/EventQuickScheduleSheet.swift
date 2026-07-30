//
//  EventQuickScheduleSheet.swift
//  GalacticCalendar
//

import SwiftUI

/// Compact sheet to move/reprogram or copy an event to another date (± time).
struct EventQuickScheduleSheet: View {

    let operation: EventQuickDateOperation
    let isAllDay: Bool
    @Binding var selectedDate: Date
    let onConfirm: () async -> Void
    let onCancel: () -> Void

    @State private var isSaving: Bool = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.stackLoose) {
                Text(operation.title)
                    .font(Typography.title3)
                    .foregroundStyle(ColorPalette.onImagePrimary)

                DatePicker(
                    String(localized: "event_field_date"),
                    selection: $selectedDate,
                    displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(ColorPalette.editorAccent)
                .accessibilityLabel(Text(String(localized: "event_field_date")))
                .accessibilityIdentifier("event_quick_schedule_date")

                Spacer(minLength: 0)

                Button {
                    guard isSaving == false else { return }
                    Task {
                        isSaving = true
                        defer { isSaving = false }
                        await onConfirm()
                    }
                } label: {
                    Text(operation.confirmTitle)
                        .font(Typography.headline)
                        .foregroundStyle(ColorPalette.onImagePrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background {
                            RoundedRectangle(cornerRadius: Spacing.Radius.lg, style: .continuous)
                                .fill(ColorPalette.editorTileFill)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: Spacing.Radius.lg, style: .continuous)
                                .stroke(GlassEffect.linearGlowGradient, lineWidth: Spacing.cardStroke)
                        }
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
                .accessibilityLabel(Text(operation.confirmTitle))
                .accessibilityIdentifier("event_quick_schedule_confirm")
            }
            .padding(Spacing.md)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "event_delete_cancel")) {
                        onCancel()
                    }
                    .accessibilityIdentifier("event_quick_schedule_cancel")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("event_quick_schedule_sheet")
    }
}
