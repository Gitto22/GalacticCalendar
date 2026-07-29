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

    // MARK: - Lifecycle

    /// Creates the event editor popup.
    /// - Parameters:
    ///   - viewModel: Bound editor ViewModel.
    ///   - onDismiss: Called when the user closes without saving, or after a successful save.
    init(viewModel: EventEditorViewModel, onDismiss: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.stackLoose) {
            headerActions
            titleField
            descriptionField
            selectorsGrid
            saveButton
        }
        .padding(Spacing.md)
        .glassEffect(.subtle, cornerRadius: Spacing.Radius.xl)
        .padding(.horizontal, Spacing.pageHorizontal)
        .onChange(of: viewModel.didCompleteMutation) { _, completed in
            if completed {
                onDismiss()
            }
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

            GlassCircleButton(
                systemImage: Icons.Events.confirm,
                font: Typography.title3,
                foreground: ColorPalette.editorAccent,
                showsGlow: true
            ) {
                Task { await viewModel.createEvent() }
            }
            .disabled(viewModel.isSaving)
            .accessibilityLabel(Text(String(localized: "event_editor_confirm")))
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
            reminderSelector
            repeatSelector
            categorySelector
            prioritySelector
            statusSelector
            colorSelector
        }
    }

    /// Reminder menu tile.
    private var reminderSelector: some View {
        selectorMenu(
            icon: Icons.Events.reminder,
            label: String(localized: "event_field_reminder"),
            showsChevron: true
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
            showsChevron: true
        ) {
            valueRow {
                Text(EventEditorDisplayNames.title(for: viewModel.repeatRule))
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorPalette.onImagePrimary)
                    .lineLimit(1)
            }
        } menuContent: {
            ForEach(EventRepeatRule.allCases) { rule in
                Button(EventEditorDisplayNames.title(for: rule)) {
                    viewModel.repeatRule = rule
                }
            }
        }
    }

    /// Category menu tile with leading color dot.
    private var categorySelector: some View {
        selectorMenu(
            icon: Icons.Events.category,
            label: String(localized: "event_field_category"),
            showsChevron: true
        ) {
            valueRow {
                HStack(spacing: Spacing.xxs) {
                    Circle()
                        .fill(ColorPalette.eventColorGreen)
                        .frame(width: LayoutConstants.eventIndicatorSize, height: LayoutConstants.eventIndicatorSize)

                    Text(EventEditorDisplayNames.title(for: viewModel.category))
                        .font(Typography.subheadline)
                        .foregroundStyle(ColorPalette.onImagePrimary)
                        .lineLimit(1)
                }
            }
        } menuContent: {
            ForEach(EventCategory.allCases) { category in
                Button(EventEditorDisplayNames.title(for: category)) {
                    viewModel.category = category
                }
            }
        }
    }

    /// Priority menu tile with upward arrow accent.
    private var prioritySelector: some View {
        selectorMenu(
            icon: Icons.Events.priority,
            label: String(localized: "event_field_priority"),
            showsChevron: true
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
            showsChevron: true
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
                        .accessibilityLabel(Text(eventColor.rawValue))
                    }
                }
            }
        }
    }

    // MARK: - Save

    /// Full-width save action with sparkles and glow border.
    private var saveButton: some View {
        Button {
            Task { await viewModel.createEvent() }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: Icons.Events.save)
                    .font(Typography.headline)
                    .foregroundStyle(ColorPalette.editorAccent)

                Text(String(localized: "event_save_button"))
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
        .disabled(viewModel.isSaving)
        .accessibilityLabel(Text(String(localized: "event_save_button")))
    }

    // MARK: - Selector Helpers

    /// Builds a menu-backed selector tile.
    private func selectorMenu<Value: View, MenuItems: View>(
        icon: String,
        label: String,
        showsChevron: Bool,
        @ViewBuilder value: () -> Value,
        @ViewBuilder menuContent: () -> MenuItems
    ) -> some View {
        Menu {
            menuContent()
        } label: {
            selectorTile(icon: icon, label: label, showsChevron: showsChevron, value: value)
        }
        .buttonStyle(.plain)
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
                    repository: PreviewEventRepository(),
                    validationService: EventValidationService()
                )
            )
        )
    }
    .environment(ThemeManager())
}

/// In-memory repository used only by event editor previews.
@MainActor
private final class PreviewEventRepository: EventRepositoryProtocol {

    func create(_ event: Event) async throws {}

    func fetchAll() async throws -> [Event] { [] }

    func fetch(by id: UUID) async throws -> Event? { nil }

    func fetch(on date: Date) async throws -> [Event] { [] }

    func fetch(in interval: DateInterval) async throws -> [Event] { [] }

    func update(_ event: Event) async throws {}

    func delete(_ event: Event) async throws {}

    func delete(id: UUID) async throws {}
}
#endif
