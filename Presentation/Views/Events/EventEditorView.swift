//
//  EventEditorView.swift
//  GalacticCalendar
//

import SwiftUI

/// Approved event creation and editing popup for Galactic Calendar.
///
/// Layout, hierarchy, and chrome match the design reference exactly.
/// All business logic lives in ``EventEditorViewModel``.
struct EventEditorView: View {

    // MARK: - Dependencies

    /// Observable editor state and persistence actions.
    @Bindable var viewModel: EventEditorViewModel

    /// Dismiss handler invoked by the close control after cancel.
    private let onDismiss: () -> Void

    /// Controls the delete confirmation dialog.
    @State private var isShowingDeleteConfirmation: Bool = false

    /// Controls the operation-failure alert.
    @State private var isShowingErrorAlert: Bool = false

    /// Controls the template-save failure alert.
    @State private var isShowingTemplateErrorAlert: Bool = false

    /// Brief success feedback before dismissing after a successful save/delete.
    @State private var showsSuccessFeedback: Bool = false

    /// Non-dismissing feedback after save-as-template.
    @State private var showsTemplateSavedFeedback: Bool = false

    /// Dismiss-after-success work; cancelled when the editor disappears.
    @State private var successDismissTask: Task<Void, Never>?

    // MARK: - Lifecycle

    /// Creates the event editor popup.
    /// - Parameters:
    ///   - viewModel: Bound editor ViewModel.
    ///   - onDismiss: Called when the user closes without saving, or after a successful mutation.
    init(viewModel: EventEditorViewModel, onDismiss: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.stackLoose) {
                headerActions
                titleField
                descriptionField
                selectorsGrid

                if viewModel.hasValidationIssues {
                    validationMessage
                }

                saveButton

                if viewModel.isEditing == false, viewModel.canUseTemplates {
                    createFromTemplateButton
                }

                if viewModel.isEditing, viewModel.canUseTemplates {
                    saveAsTemplateButton
                }

                if viewModel.isEditing {
                    deleteButton
                }
            }
            .padding(Spacing.md)
            .glassEffect(.subtle, cornerRadius: Spacing.Radius.xl)
        }
        .padding(.horizontal, Spacing.pageHorizontal)
        .accessibilityIdentifier("event_editor")
        .onChange(of: viewModel.didCompleteMutation) { _, completed in
            guard completed else {
                return
            }
            presentSuccessThenDismiss()
        }
        .onChange(of: viewModel.didSaveAsTemplate) { _, saved in
            guard saved else { return }
            showsTemplateSavedFeedback = true
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(Animations.regularDuration * 1_000_000_000))
                showsTemplateSavedFeedback = false
                viewModel.clearTemplateFeedback()
            }
        }
        .onChange(of: viewModel.lastError) { _, error in
            guard error != nil, viewModel.shouldPresentErrorAlert else {
                return
            }
            isShowingErrorAlert = true
        }
        .onChange(of: viewModel.lastTemplateError) { _, error in
            isShowingTemplateErrorAlert = error != nil
        }
        .task {
            // Permission prompt only; popup layout is unchanged.
            await viewModel.requestNotificationAuthorizationIfNeeded()
        }
        .fullScreenCover(
            isPresented: $viewModel.isPresentingTemplatePicker,
            onDismiss: { viewModel.dismissTemplatePicker() }
        ) {
            if let picker = viewModel.templatePickerViewModel {
                EventTemplatePickerView(
                    viewModel: picker,
                    onSelect: { template in
                        viewModel.applyTemplate(template)
                    },
                    onDismiss: {
                        viewModel.dismissTemplatePicker()
                    }
                )
            }
        }
        .confirmationDialog(
            String(localized: "event_delete_confirm_title"),
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "event_delete_confirm_action"), role: .destructive) {
                Task { await viewModel.deleteEvent() }
            }
            Button(String(localized: "event_delete_cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "event_delete_confirm_message"))
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
        .alert(
            String(localized: "event_error_alert_title"),
            isPresented: $isShowingTemplateErrorAlert
        ) {
            Button(String(localized: "event_error_alert_dismiss"), role: .cancel) {
                viewModel.clearTemplateFeedback()
            }
        } message: {
            Text(viewModel.templateErrorAlertMessage)
        }
        .onDisappear {
            successDismissTask?.cancel()
            successDismissTask = nil
        }
    }

    // MARK: - Header

    /// Close and confirm controls anchored to the trailing edge.
    private var headerActions: some View {
        HStack(spacing: Spacing.sm) {
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
            .accessibilityHint(Text(String(localized: "event_editor_close_a11y_hint")))
            .accessibilityIdentifier("event_editor_close")

            GlassCircleButton(
                systemImage: showsSuccessFeedback ? Icons.Status.success : Icons.Events.confirm,
                font: Typography.title3,
                foreground: showsSuccessFeedback ? ColorPalette.success : ColorPalette.editorAccent,
                showsGlow: true
            ) {
                Task { await persistChanges() }
            }
            .disabled(viewModel.isSaving || showsSuccessFeedback)
            .accessibilityLabel(
                Text(
                    showsSuccessFeedback
                        ? String(localized: "event_save_success")
                        : String(localized: "event_editor_confirm")
                )
            )
            .accessibilityHint(Text(String(localized: "event_editor_confirm_a11y_hint")))
            .accessibilityIdentifier("event_editor_confirm")
            .appAnimation(Animations.snappy, value: showsSuccessFeedback)
        }
    }

    // MARK: - Feedback

    /// Inline validation copy using existing typography and status colors.
    private var validationMessage: some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Image(systemName: Icons.Status.warning)
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.warning)

            Text(viewModel.validationMessage)
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.warning)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    /// Shows success affordances on existing controls, then dismisses.
    private func presentSuccessThenDismiss() {
        showsSuccessFeedback = true
        successDismissTask?.cancel()
        successDismissTask = Task { @MainActor in
            do {
                try await Task.sleep(
                    nanoseconds: UInt64(Animations.regularDuration * 1_000_000_000)
                )
            } catch {
                // Cancellation still dismisses so the editor does not remain stuck.
            }
            guard Task.isCancelled == false else {
                return
            }
            onDismiss()
        }
    }

    // MARK: - Title

    /// Single-line title input with leading calendar glyph.
    private var titleField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: Icons.Events.title)
                .font(Typography.title3)
                .foregroundStyle(ColorPalette.editorAccent)

            TextField(
                "",
                text: $viewModel.title,
                prompt: Text(String(localized: "event_title_placeholder"))
                    .foregroundStyle(ColorPalette.editorPlaceholder)
            )
            .font(Typography.body)
            .foregroundStyle(ColorPalette.onImagePrimary)
            .textInputAutocapitalization(.sentences)
            .accessibilityLabel(Text(String(localized: "event_title_placeholder")))
            .accessibilityIdentifier("event_editor_title")
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .overlay {
            RoundedRectangle(cornerRadius: Spacing.Radius.md, style: .continuous)
                .stroke(ColorPalette.separator.opacity(ColorPalette.glassStrokeSubtleOpacity), lineWidth: Spacing.cardStroke)
        }
    }

    // MARK: - Description

    /// Multi-line description editor with ruled lines and purple border.
    private var descriptionField: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: Icons.Events.description)
                .font(Typography.title3)
                .foregroundStyle(ColorPalette.editorAccent)
                .padding(.top, Spacing.xxxs)

            ZStack(alignment: .topLeading) {
                descriptionRulingLines

                TextEditor(text: $viewModel.description)
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.onImagePrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: LayoutConstants.eventDescriptionMinHeight)
                    .accessibilityLabel(Text(String(localized: "event_description_placeholder")))
                    .accessibilityIdentifier("event_editor_description")

                if viewModel.description.isEmpty {
                    Text(String(localized: "event_description_placeholder"))
                        .font(Typography.body)
                        .foregroundStyle(ColorPalette.editorPlaceholder)
                        .padding(.top, Spacing.xxs)
                        .padding(.leading, Spacing.xxxs)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding(Spacing.sm)
        .overlay {
            RoundedRectangle(cornerRadius: Spacing.Radius.md, style: .continuous)
                .stroke(ColorPalette.editorAccent, lineWidth: Spacing.cardStroke)
        }
    }

    /// Horizontal ruling lines behind the description editor.
    private var descriptionRulingLines: some View {
        VStack(spacing: Spacing.md) {
            ForEach(0..<5, id: \.self) { _ in
                Rectangle()
                    .fill(ColorPalette.separator.opacity(ColorPalette.glassStrokeSubtleOpacity))
                    .frame(height: LayoutConstants.dayCellBorderStroke)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, Spacing.lg)
        .allowsHitTesting(false)
    }

    // MARK: - Selectors

    /// Two-column selector grid matching the approved layout.
    private var selectorsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Spacing.sm),
                GridItem(.flexible(), spacing: Spacing.sm)
            ],
            spacing: Spacing.sm
        ) {
            allDayToggle
            startDateSelector
            endDateSelector
            if viewModel.isAllDay == false {
                startTimeSelector
                endTimeSelector
            }
            timeZoneSelector
            reminderSelector
            repeatSelector
            recurrenceEndSelector
            recurrenceCountSelector
            recurrenceEndDateSelector
            tagsSelector
            prioritySelector
            statusSelector
            colorSelector
        }
        .environment(\.timeZone, EventTimeZone.timeZone(for: viewModel.timeZoneIdentifier))
    }

    /// All-day switch; when on, start/end time tiles are hidden.
    private var allDayToggle: some View {
        selectorTile(
            icon: Icons.Events.allDay,
            label: String(localized: "event_field_all_day"),
            showsChevron: false
        ) {
            valueRow {
                Toggle("", isOn: $viewModel.isAllDay)
                    .labelsHidden()
                    .tint(ColorPalette.editorAccent)
                    .accessibilityLabel(Text(String(localized: "event_field_all_day")))
                    .accessibilityIdentifier("event_editor_all_day")
            }
        }
    }

    /// Start calendar day selector.
    private var startDateSelector: some View {
        datePickerTile(
            icon: Icons.Events.eventDate,
            label: String(localized: "event_field_start_date"),
            selection: $viewModel.date,
            components: .date,
            accessibilityIdentifier: "event_editor_start_date"
        )
    }

    /// End calendar day selector (never before the start date).
    private var endDateSelector: some View {
        datePickerTile(
            icon: Icons.Events.endDate,
            label: String(localized: "event_field_end_date"),
            selection: $viewModel.endDate,
            components: .date,
            accessibilityIdentifier: "event_editor_end_date"
        )
    }

    /// Start time selector using the native time picker.
    private var startTimeSelector: some View {
        datePickerTile(
            icon: Icons.Events.startTime,
            label: String(localized: "event_field_start_time"),
            selection: $viewModel.date,
            components: .hourAndMinute,
            accessibilityIdentifier: "event_editor_start_time"
        )
    }

    /// End time selector using the native time picker.
    private var endTimeSelector: some View {
        datePickerTile(
            icon: Icons.Events.endTime,
            label: String(localized: "event_field_end_time"),
            selection: $viewModel.endDate,
            components: .hourAndMinute,
            accessibilityIdentifier: "event_editor_end_time"
        )
    }

    /// Time zone menu prepared for multi-device / CloudKit display.
    private var timeZoneSelector: some View {
        selectorMenu(
            icon: Icons.Events.timeZone,
            label: String(localized: "event_field_timezone"),
            showsChevron: true,
            accessibilityIdentifier: "event_editor_timezone"
        ) {
            valueRow {
                Text(viewModel.timeZoneDisplayName)
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorPalette.onImagePrimary)
                    .lineLimit(1)
            }
        } menuContent: {
            ForEach(viewModel.selectableTimeZoneIdentifiers, id: \.self) { identifier in
                Button(EventTimeZone.displayName(for: identifier)) {
                    viewModel.timeZoneIdentifier = identifier
                }
            }
        }
    }

    /// Reminder menu tile.
    private var reminderSelector: some View {
        selectorMenu(
            icon: Icons.Events.reminder,
            label: String(localized: "event_field_reminder"),
            showsChevron: true,
            accessibilityIdentifier: "event_editor_reminder"
        ) {
            valueRow {
                Text(EventEditorDisplayNames.title(for: viewModel.reminderOption))
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorPalette.onImagePrimary)
                    .lineLimit(1)
            }
        } menuContent: {
            ForEach(EventReminderOption.allCases) { option in
                Button(EventEditorDisplayNames.title(for: option)) {
                    viewModel.reminderOption = option
                }
            }
        }
    }

    /// Repeat menu tile.
    private var repeatSelector: some View {
        selectorMenu(
            icon: Icons.Events.repeat,
            label: String(localized: "event_field_repeat"),
            showsChevron: true,
            accessibilityIdentifier: "event_editor_repeat"
        ) {
            valueRow {
                Text(EventEditorDisplayNames.title(for: viewModel.repeatRule))
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorPalette.onImagePrimary)
                    .lineLimit(1)
            }
        } menuContent: {
            ForEach(RepeatRule.editorSelectableRules) { rule in
                Button(EventEditorDisplayNames.title(for: rule)) {
                    viewModel.repeatRule = rule
                }
            }
        }
    }

    /// Recurrence end-mode menu (hidden when the event does not repeat).
    @ViewBuilder
    private var recurrenceEndSelector: some View {
        if viewModel.repeatRule.isRecurring {
            selectorMenu(
                icon: Icons.Events.repeatEnd,
                label: String(localized: "event_field_repeat_end"),
                showsChevron: true,
                accessibilityIdentifier: "event_editor_repeat_end"
            ) {
                valueRow {
                    Text(EventEditorDisplayNames.title(for: viewModel.recurrenceEndKind))
                        .font(Typography.subheadline)
                        .foregroundStyle(ColorPalette.onImagePrimary)
                        .lineLimit(1)
                }
            } menuContent: {
                ForEach(RecurrenceEndKind.allCases) { kind in
                    Button(EventEditorDisplayNames.title(for: kind)) {
                        viewModel.recurrenceEndKind = kind
                    }
                }
            }
        }
    }

    /// Occurrence count stepper tile.
    @ViewBuilder
    private var recurrenceCountSelector: some View {
        if viewModel.repeatRule.isRecurring, viewModel.recurrenceEndKind == .afterCount {
            selectorTile(
                icon: Icons.Events.repeatCount,
                label: String(localized: "event_field_repeat_count"),
                showsChevron: false
            ) {
                valueRow {
                    Stepper(
                        value: $viewModel.recurrenceEndCount,
                        in: 1...999
                    ) {
                        Text("\(viewModel.recurrenceEndCount)")
                            .font(Typography.subheadline)
                            .foregroundStyle(ColorPalette.onImagePrimary)
                    }
                    .labelsHidden()
                    .tint(ColorPalette.editorAccent)
                    .accessibilityLabel(Text(String(localized: "event_field_repeat_count")))
                    .accessibilityValue(Text("\(viewModel.recurrenceEndCount)"))
                    .accessibilityIdentifier("event_editor_repeat_count")
                }
            }
        }
    }

    /// Recurrence end-date picker tile.
    @ViewBuilder
    private var recurrenceEndDateSelector: some View {
        if viewModel.repeatRule.isRecurring, viewModel.recurrenceEndKind == .onDate {
            datePickerTile(
                icon: Icons.Events.repeatEnd,
                label: String(localized: "event_field_repeat_end_date"),
                selection: $viewModel.recurrenceEndDate,
                components: .date,
                accessibilityIdentifier: "event_editor_repeat_end_date"
            )
        }
    }

    /// Multi-select tag tile (presets only; custom tags reserved).
    private var tagsSelector: some View {
        selectorTile(
            icon: Icons.Events.tags,
            label: String(localized: "event_field_tags"),
            showsChevron: false
        ) {
            valueRow {
                FlowTagPicker(
                    presets: viewModel.selectableTagPresets,
                    isSelected: viewModel.isTagSelected,
                    title: EventEditorDisplayNames.title(for:),
                    onToggle: viewModel.toggleTag
                )
            }
        }
    }

    /// Priority menu tile with upward arrow accent.
    private var prioritySelector: some View {
        selectorMenu(
            icon: Icons.Events.priority,
            label: String(localized: "event_field_priority"),
            showsChevron: true,
            accessibilityIdentifier: "event_editor_priority"
        ) {
            valueRow {
                HStack(spacing: Spacing.xxs) {
                    if viewModel.priority >= .high {
                        Image(systemName: Icons.Events.priorityUp)
                            .font(Typography.caption)
                            .foregroundStyle(ColorPalette.eventColorRed)
                    }

                    Text(EventEditorDisplayNames.title(for: viewModel.priority))
                        .font(Typography.subheadline)
                        .foregroundStyle(ColorPalette.onImagePrimary)
                        .lineLimit(1)
                }
            }
        } menuContent: {
            ForEach(EventPriority.allCases) { priority in
                Button(EventEditorDisplayNames.title(for: priority)) {
                    viewModel.priority = priority
                }
            }
        }
    }

    /// Status menu tile.
    private var statusSelector: some View {
        selectorMenu(
            icon: Icons.Events.status,
            label: String(localized: "event_field_status"),
            showsChevron: true,
            accessibilityIdentifier: "event_editor_status"
        ) {
            valueRow {
                Text(EventEditorDisplayNames.title(for: viewModel.status))
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorPalette.onImagePrimary)
                    .lineLimit(1)
            }
        } menuContent: {
            ForEach(EventStatus.allCases) { status in
                Button(EventEditorDisplayNames.title(for: status)) {
                    viewModel.status = status
                }
            }
        }
    }

    /// Event color tile with four selectable dots.
    private var colorSelector: some View {
        selectorTile(
            icon: Icons.Events.color,
            label: String(localized: "event_field_color"),
            showsChevron: false
        ) {
            valueRow {
                HStack(spacing: Spacing.xs) {
                    ForEach(EventColor.allCases) { eventColor in
                        Button {
                            viewModel.color = eventColor
                        } label: {
                            Circle()
                                .fill(ColorPalette.color(for: eventColor))
                                .frame(
                                    width: LayoutConstants.eventColorDotSize,
                                    height: LayoutConstants.eventColorDotSize
                                )
                                .overlay {
                                    if viewModel.color == eventColor {
                                        Circle()
                                            .stroke(ColorPalette.onImagePrimary, lineWidth: LayoutConstants.dayCellBorderStroke)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(EventEditorDisplayNames.title(for: eventColor)))
                        .accessibilityHint(Text(String(localized: "event_color_a11y_hint")))
                        .accessibilityAddTraits(viewModel.color == eventColor ? .isSelected : [])
                        .accessibilityIdentifier("event_editor_color_\(eventColor.rawValue)")
                    }
                }
            }
        }
    }

    // MARK: - Save

    /// Full-width save action with sparkles and glow border.
    private var saveButton: some View {
        Button {
            Task { await persistChanges() }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: showsSuccessFeedback ? Icons.Status.success : Icons.Events.save)
                    .font(Typography.headline)
                    .foregroundStyle(
                        showsSuccessFeedback ? ColorPalette.success : ColorPalette.editorAccent
                    )

                Text(
                    showsSuccessFeedback
                        ? String(localized: "event_save_success")
                        : String(localized: "event_save_button")
                )
                    .font(Typography.headline)
                    .foregroundStyle(ColorPalette.onImagePrimary)
            }
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
            .appShadow(Shadows.glowCard)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSaving || showsSuccessFeedback)
        .accessibilityLabel(
            Text(
                showsSuccessFeedback
                    ? String(localized: "event_save_success")
                    : String(localized: "event_save_button")
            )
        )
        .accessibilityHint(Text(String(localized: "event_editor_confirm_a11y_hint")))
        .accessibilityIdentifier("event_editor_save")
        .appAnimation(Animations.snappy, value: showsSuccessFeedback)
    }

    // MARK: - Templates

    /// Create-mode affordance to fill the form from a saved template.
    private var createFromTemplateButton: some View {
        Button {
            viewModel.presentTemplatePicker()
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: Icons.Events.template)
                    .font(Typography.headline)
                    .foregroundStyle(ColorPalette.editorAccent)

                Text(String(localized: "event_create_from_template"))
                    .font(Typography.headline)
                    .foregroundStyle(ColorPalette.onImagePrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: Spacing.Radius.lg, style: .continuous)
                    .fill(ColorPalette.editorTileFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Spacing.Radius.lg, style: .continuous)
                    .stroke(
                        ColorPalette.separator.opacity(ColorPalette.glassStrokeSubtleOpacity),
                        lineWidth: Spacing.cardStroke
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(String(localized: "event_create_from_template")))
        .accessibilityHint(Text(String(localized: "event_create_from_template_a11y_hint")))
        .accessibilityIdentifier("event_editor_create_from_template")
    }

    /// Edit-mode affordance to snapshot the draft as an offline template.
    private var saveAsTemplateButton: some View {
        Button {
            Task { await viewModel.saveCurrentAsTemplate() }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: showsTemplateSavedFeedback ? Icons.Status.success : Icons.Events.saveTemplate)
                    .font(Typography.headline)
                    .foregroundStyle(
                        showsTemplateSavedFeedback ? ColorPalette.success : ColorPalette.editorAccent
                    )

                Text(
                    showsTemplateSavedFeedback
                        ? String(localized: "event_template_save_success")
                        : String(localized: "event_save_as_template")
                )
                .font(Typography.headline)
                .foregroundStyle(ColorPalette.onImagePrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: Spacing.Radius.lg, style: .continuous)
                    .fill(ColorPalette.editorTileFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Spacing.Radius.lg, style: .continuous)
                    .stroke(
                        ColorPalette.separator.opacity(ColorPalette.glassStrokeSubtleOpacity),
                        lineWidth: Spacing.cardStroke
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSaving)
        .accessibilityLabel(Text(String(localized: "event_save_as_template")))
        .accessibilityHint(Text(String(localized: "event_save_as_template_a11y_hint")))
        .accessibilityIdentifier("event_editor_save_as_template")
        .appAnimation(Animations.snappy, value: showsTemplateSavedFeedback)
    }

    // MARK: - Delete

    /// Destructive action shown only while editing an existing event.
    private var deleteButton: some View {
        Button {
            isShowingDeleteConfirmation = true
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: Icons.Events.delete)
                    .font(Typography.headline)
                    .foregroundStyle(ColorPalette.danger)

                Text(String(localized: "event_delete_button"))
                    .font(Typography.headline)
                    .foregroundStyle(ColorPalette.danger)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: Spacing.Radius.lg, style: .continuous)
                    .fill(ColorPalette.editorTileFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Spacing.Radius.lg, style: .continuous)
                    .stroke(
                        ColorPalette.danger.opacity(ColorPalette.glassStrokeRegularOpacity),
                        lineWidth: Spacing.cardStroke
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSaving)
        .accessibilityLabel(Text(String(localized: "event_delete_button")))
        .accessibilityHint(Text(String(localized: "event_delete_a11y_hint")))
        .accessibilityIdentifier("event_editor_delete")
    }

    // MARK: - Persistence

    /// Persists create or update according to the current editor mode.
    private func persistChanges() async {
        await viewModel.saveEvent()
    }

    // MARK: - Selector Helpers

    /// Builds a menu-backed selector tile.
    private func selectorMenu<Value: View, MenuItems: View>(
        icon: String,
        label: String,
        showsChevron: Bool,
        accessibilityIdentifier: String,
        @ViewBuilder value: () -> Value,
        @ViewBuilder menuContent: () -> MenuItems
    ) -> some View {
        Menu {
            menuContent()
        } label: {
            selectorTile(icon: icon, label: label, showsChevron: showsChevron, value: value)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    /// Selector tile hosting a compact native ``DatePicker``.
    private func datePickerTile(
        icon: String,
        label: String,
        selection: Binding<Date>,
        components: DatePicker.Components,
        accessibilityIdentifier: String
    ) -> some View {
        selectorTile(icon: icon, label: label, showsChevron: false) {
            valueRow {
                DatePicker(
                    "",
                    selection: selection,
                    displayedComponents: components
                )
                .labelsHidden()
                .tint(ColorPalette.editorAccent)
                .font(Typography.subheadline)
                .foregroundStyle(ColorPalette.onImagePrimary)
                .accessibilityLabel(Text(label))
                .accessibilityValue(Text(datePickerAccessibilityValue(selection.wrappedValue, components: components)))
                .accessibilityIdentifier(accessibilityIdentifier)
            }
        }
    }

    /// Formats a date/time for VoiceOver on editor pickers.
    private func datePickerAccessibilityValue(
        _ date: Date,
        components: DatePicker.Components
    ) -> String {
        if components.contains(.hourAndMinute), components.contains(.date) == false {
            return date.formatted(date: .omitted, time: .shortened)
        }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    /// Shared glass tile chrome for selector cells.
    private func selectorTile<Value: View>(
        icon: String,
        label: String,
        showsChevron: Bool,
        @ViewBuilder value: () -> Value
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(Typography.footnote)
                    .foregroundStyle(ColorPalette.editorAccent)

                Text(label)
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.editorPlaceholder)
                    .lineLimit(1)

                Spacer(minLength: 0)

                if showsChevron {
                    Image(systemName: Icons.Events.selectorChevron)
                        .font(Typography.caption2)
                        .foregroundStyle(ColorPalette.editorPlaceholder)
                }
            }

            value()
        }
        .padding(Spacing.sm)
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
    }

    /// Wraps selector value content with consistent leading alignment.
    private func valueRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Event Editor") {
    ZStack {
        MonthBackgroundView()

        EventEditorView(
            viewModel: EventEditorViewModel(
                persistenceService: EventPersistenceService(
                    repository: EventsPreviewRepository(),
                    validationService: EventValidationService()
                )
            )
        )
    }
    .environment(ThemeManager())
    .environment(CalendarAppearanceManager())
}
#endif
