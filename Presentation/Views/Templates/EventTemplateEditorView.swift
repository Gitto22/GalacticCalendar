//
//  EventTemplateEditorView.swift
//  GalacticCalendar
//

import SwiftUI

/// Create / edit popup for an offline ``EventTemplate``.
struct EventTemplateEditorView: View {

    @Bindable var viewModel: EventTemplateEditorViewModel
    private let onDismiss: () -> Void

    @State private var isShowingErrorAlert: Bool = false
    @State private var showsSuccessFeedback: Bool = false
    @State private var successDismissTask: Task<Void, Never>?

    init(viewModel: EventTemplateEditorViewModel, onDismiss: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.stackLoose) {
            headerActions
            nameField
            titleField
            descriptionField
            selectors

            if let validationMessage = viewModel.validationMessage {
                Text(validationMessage)
                    .font(Typography.footnote)
                    .foregroundStyle(ColorPalette.danger)
            }

            saveButton
        }
        .padding(Spacing.md)
        .glassEffect(.subtle, cornerRadius: Spacing.Radius.xl)
        .padding(.horizontal, Spacing.pageHorizontal)
        .onChange(of: viewModel.didCompleteMutation) { _, completed in
            guard completed else { return }
            presentSuccessThenDismiss()
        }
        .onChange(of: viewModel.lastError) { _, error in
            isShowingErrorAlert = error != nil
        }
        .alert(
            String(localized: "event_error_alert_title"),
            isPresented: $isShowingErrorAlert
        ) {
            Button(String(localized: "event_error_alert_dismiss"), role: .cancel) {
                viewModel.clearLastError()
            }
        } message: {
            Text(viewModel.errorAlertMessage ?? String(localized: "event_error_unknown"))
        }
        .onDisappear {
            successDismissTask?.cancel()
            successDismissTask = nil
        }
    }

    private var headerActions: some View {
        HStack(spacing: Spacing.sm) {
            Text(
                viewModel.isEditing
                    ? String(localized: "event_template_editor_edit_title")
                    : String(localized: "event_template_editor_create_title")
            )
            .font(Typography.title3)
            .foregroundStyle(ColorPalette.onImagePrimary)
            .lineLimit(1)

            Spacer(minLength: 0)

            GlassCircleButton(
                systemImage: Icons.Navigation.close,
                font: Typography.title3,
                foreground: ColorPalette.onImagePrimary,
                showsGlow: false
            ) {
                onDismiss()
            }
            .accessibilityLabel(Text(String(localized: "event_editor_close")))
        }
    }

    private var nameField: some View {
        labeledField(
            icon: Icons.Events.template,
            placeholder: String(localized: "event_template_field_name"),
            text: $viewModel.name
        )
    }

    private var titleField: some View {
        labeledField(
            icon: Icons.Events.title,
            placeholder: String(localized: "event_title_placeholder"),
            text: $viewModel.title
        )
    }

    private var descriptionField: some View {
        labeledField(
            icon: Icons.Events.description,
            placeholder: String(localized: "event_description_placeholder"),
            text: $viewModel.description,
            axis: .vertical
        )
    }

    private var selectors: some View {
        VStack(spacing: Spacing.xs) {
            Toggle(isOn: $viewModel.isAllDay) {
                Label(
                    String(localized: "event_field_all_day"),
                    systemImage: Icons.Events.allDay
                )
                .font(Typography.subheadline)
                .foregroundStyle(ColorPalette.onImagePrimary)
            }
            .tint(ColorPalette.editorAccent)

            Menu {
                ForEach(EventTemplateEditorViewModel.durationPresets, id: \.seconds) { preset in
                    Button(String(localized: String.LocalizationValue(preset.labelKey))) {
                        viewModel.durationSeconds = preset.seconds
                        if preset.seconds >= 86_400 {
                            viewModel.isAllDay = true
                        }
                    }
                }
            } label: {
                selectorLabel(
                    icon: Icons.Events.endTime,
                    title: String(localized: "event_template_field_duration"),
                    value: durationLabel
                )
            }

            Menu {
                ForEach(RepeatRule.editorSelectableRules) { rule in
                    Button(EventEditorDisplayNames.title(for: rule)) {
                        viewModel.repeatRule = rule
                    }
                }
            } label: {
                selectorLabel(
                    icon: Icons.Events.repeat,
                    title: String(localized: "event_field_repeat"),
                    value: EventEditorDisplayNames.title(for: viewModel.repeatRule)
                )
            }

            Menu {
                ForEach(EventPriority.allCases) { priority in
                    Button(EventEditorDisplayNames.title(for: priority)) {
                        viewModel.priority = priority
                    }
                }
            } label: {
                selectorLabel(
                    icon: Icons.Events.priority,
                    title: String(localized: "event_field_priority"),
                    value: EventEditorDisplayNames.title(for: viewModel.priority)
                )
            }

            Menu {
                ForEach(EventColor.allCases) { eventColor in
                    Button {
                        viewModel.color = eventColor
                    } label: {
                        Label {
                            Text(eventColor.rawValue.capitalized)
                        } icon: {
                            Image(systemName: Icons.Events.color)
                                .foregroundStyle(ColorPalette.color(for: eventColor))
                        }
                    }
                }
            } label: {
                selectorLabel(
                    icon: Icons.Events.color,
                    title: String(localized: "event_field_color"),
                    value: viewModel.color.rawValue.capitalized
                )
            }

            Menu {
                ForEach(EventTagPreset.allCases) { preset in
                    Button {
                        viewModel.toggleTag(.preset(preset))
                    } label: {
                        Label(
                            EventEditorDisplayNames.title(for: .preset(preset)),
                            systemImage: viewModel.tags.contains(.preset(preset))
                                ? Icons.Status.success
                                : Icons.Events.tags
                        )
                    }
                }
            } label: {
                selectorLabel(
                    icon: Icons.Events.tags,
                    title: String(localized: "event_field_tags"),
                    value: tagsLabel
                )
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task { await viewModel.save() }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: showsSuccessFeedback ? Icons.Status.success : Icons.Events.save)
                    .font(Typography.headline)
                Text(
                    showsSuccessFeedback
                        ? String(localized: "event_template_save_success")
                        : String(localized: "event_save_button")
                )
                .font(Typography.headline)
            }
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
        .disabled(viewModel.isSaving)
    }

    private func labeledField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        axis: Axis = .horizontal
    ) -> some View {
        HStack(alignment: axis == .vertical ? .top : .center, spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(Typography.callout)
                .foregroundStyle(ColorPalette.onImageAccent)
            TextField(placeholder, text: text, axis: axis)
                .font(Typography.callout)
                .foregroundStyle(ColorPalette.onImagePrimary)
                .lineLimit(axis == .vertical ? 3...6 : 1...1)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Spacing.Radius.md, style: .continuous)
                .fill(ColorPalette.editorTileFill)
        }
    }

    private func selectorLabel(icon: String, title: String, value: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(Typography.callout)
                .foregroundStyle(ColorPalette.onImageAccent)
            Text(title)
                .font(Typography.footnote)
                .foregroundStyle(ColorPalette.editorPlaceholder)
            Spacer(minLength: Spacing.xs)
            Text(value)
                .font(Typography.subheadline)
                .foregroundStyle(ColorPalette.onImagePrimary)
                .lineLimit(1)
            Image(systemName: Icons.Events.selectorChevron)
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.onImageAccent)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Spacing.Radius.md, style: .continuous)
                .fill(ColorPalette.editorTileFill)
        }
    }

    private var durationLabel: String {
        if let match = EventTemplateEditorViewModel.durationPresets.first(where: {
            $0.seconds == viewModel.durationSeconds
        }) {
            return String(localized: String.LocalizationValue(match.labelKey))
        }
        let minutes = Int(viewModel.durationSeconds / 60)
        return String(format: String(localized: "event_template_duration_minutes_format"), minutes)
    }

    private var tagsLabel: String {
        if viewModel.tags.isEmpty {
            return String(localized: "event_field_tags")
        }
        return viewModel.tags
            .prefix(2)
            .map { EventEditorDisplayNames.title(for: $0) }
            .joined(separator: ", ")
    }

    private func presentSuccessThenDismiss() {
        showsSuccessFeedback = true
        successDismissTask?.cancel()
        successDismissTask = Task {
            try? await Task.sleep(for: .milliseconds(650))
            guard Task.isCancelled == false else { return }
            onDismiss()
        }
    }
}
