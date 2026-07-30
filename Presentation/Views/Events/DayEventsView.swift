//
//  DayEventsView.swift
//  GalacticCalendar
//

import SwiftUI

/// Day events list screen for Galactic Calendar.
///
/// Shows every event for a selected day, ordered by time.
/// Tap edits, swipe-left deletes, long-press opens the contextual menu.
struct DayEventsView: View {

    // MARK: - Properties

    /// Observable day-events state and actions.
    @Bindable var viewModel: DayEventsViewModel

    /// Dismiss handler for the close control.
    private let onDismiss: () -> Void

    /// Controls the operation-failure alert.
    @State private var isShowingErrorAlert: Bool = false

    // MARK: - Lifecycle

    /// Creates the day events screen.
    /// - Parameters:
    ///   - viewModel: Bound day-events ViewModel.
    ///   - onDismiss: Called when the user closes the screen.
    init(viewModel: DayEventsViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            MonthBackgroundView()

            VStack(spacing: Spacing.stackLoose) {
                header
                eventsList
                createActions
            }
            .padding(.horizontal, Spacing.pageHorizontal)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.pageVertical)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("day_events_screen")
        .fullScreenCover(
            isPresented: $viewModel.isPresentingEventEditor,
            onDismiss: {
                viewModel.dismissEventEditor()
            }
        ) {
            eventEditorCover
        }
        .fullScreenCover(
            isPresented: $viewModel.isPresentingTemplatePicker,
            onDismiss: {
                viewModel.dismissTemplatePicker()
            }
        ) {
            templatePickerCover
        }
        .fullScreenCover(
            isPresented: $viewModel.isPresentingTemplates,
            onDismiss: {
                viewModel.dismissTemplatesManager()
            }
        ) {
            templatesManagerCover
        }
        .sheet(
            isPresented: $viewModel.isPresentingQuickSchedule,
            onDismiss: {
                viewModel.dismissQuickSchedule()
            }
        ) {
            quickScheduleSheet
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
    }

    // MARK: - Header

    /// Close control and localized day title.
    private var header: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(String(localized: "day_events_title"))
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.editorPlaceholder)

                Text(dayTitle)
                    .font(Typography.title2)
                    .foregroundStyle(ColorPalette.onImagePrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(LayoutConstants.singleLineMinimumScale)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(String(localized: "day_events_title")), \(dayTitle)")
            .accessibilityIdentifier("day_events_title")

            Spacer(minLength: Spacing.xs)

            if viewModel.canUseTemplates {
                GlassCircleButton(
                    systemImage: Icons.Events.template,
                    font: Typography.title3,
                    foreground: ColorPalette.onImagePrimary,
                    showsGlow: false
                ) {
                    viewModel.presentTemplatesManager()
                }
                .accessibilityLabel(Text(String(localized: "event_templates_manage")))
                .accessibilityHint(Text(String(localized: "day_events_templates_a11y_hint")))
                .accessibilityIdentifier("day_events_templates")
            }

            GlassCircleButton(
                systemImage: Icons.Navigation.close,
                font: Typography.title3,
                foreground: ColorPalette.onImagePrimary,
                showsGlow: false
            ) {
                onDismiss()
            }
            .accessibilityLabel(Text(String(localized: "day_events_close")))
            .accessibilityHint(Text(String(localized: "day_events_close_a11y_hint")))
            .accessibilityIdentifier("day_events_close")
        }
    }

    // MARK: - List

    /// Scrollable event rows with swipe-to-delete.
    ///
    /// All-day events appear first in their own section, then timed events.
    private var eventsList: some View {
        List {
            if viewModel.allDayEvents.isEmpty == false {
                Section {
                    ForEach(viewModel.allDayEvents) { event in
                        eventRow(for: event)
                    }
                } header: {
                    sectionHeader(String(localized: "day_events_all_day_section"))
                }
            }

            if viewModel.timedEvents.isEmpty == false {
                Section {
                    ForEach(viewModel.timedEvents) { event in
                        eventRow(for: event)
                    }
                } header: {
                    if viewModel.allDayEvents.isEmpty == false {
                        sectionHeader(String(localized: "day_events_timed_section"))
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassEffect(.subtle, cornerRadius: Spacing.Radius.xl)
    }

    /// Shared row chrome for day-list events.
    @ViewBuilder
    private func eventRow(for event: Event) -> some View {
        EventRow(
            event: event,
            onTap: { viewModel.presentEdit(for: event) },
            onEdit: { viewModel.presentEdit(for: event) },
            onDuplicate: {
                Task { await viewModel.duplicate(event) }
            },
            onMove: { viewModel.presentMove(event) },
            onCopy: { viewModel.presentCopy(event) },
            onDelete: {
                Task { await viewModel.delete(event) }
            }
        )
        .listRowInsets(
            EdgeInsets(
                top: Spacing.xxs,
                leading: Spacing.sm,
                bottom: Spacing.xxs,
                trailing: Spacing.sm
            )
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Task { await viewModel.delete(event) }
            } label: {
                Label(
                    String(localized: "day_events_action_delete"),
                    systemImage: Icons.Events.delete
                )
            }
            .accessibilityIdentifier("day_events_swipe_delete_\(event.id.uuidString)")
        }
    }

    /// Localized section title above all-day or timed groups.
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Typography.caption)
            .foregroundStyle(ColorPalette.editorPlaceholder)
            .textCase(nil)
    }

    // MARK: - New Event

    /// Create actions: blank event or from template.
    private var createActions: some View {
        VStack(spacing: Spacing.xs) {
            newEventButton
            if viewModel.canUseTemplates {
                createFromTemplateButton
            }
        }
    }

    /// Bottom action that opens ``EventEditorView`` for creation.
    private var newEventButton: some View {
        Button {
            viewModel.presentNewEvent()
        } label: {
            actionLabel(
                icon: Icons.Events.add,
                title: String(localized: "day_events_new_event")
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(String(localized: "day_events_new_event")))
        .accessibilityHint(Text(String(localized: "day_events_new_event_a11y_hint")))
        .accessibilityIdentifier("day_events_new_event")
    }

    /// Opens the template picker for create-from-template.
    private var createFromTemplateButton: some View {
        Button {
            viewModel.presentCreateFromTemplate()
        } label: {
            actionLabel(
                icon: Icons.Events.template,
                title: String(localized: "event_create_from_template")
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(String(localized: "event_create_from_template")))
        .accessibilityHint(Text(String(localized: "event_create_from_template_a11y_hint")))
        .accessibilityIdentifier("day_events_create_from_template")
    }

    private func actionLabel(icon: String, title: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(Typography.headline)
                .foregroundStyle(ColorPalette.editorAccent)

            Text(title)
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

    // MARK: - Event Editor

    /// Nested editor presented over the cosmic background.
    @ViewBuilder
    private var eventEditorCover: some View {
        ZStack {
            MonthBackgroundView()

            if let editorViewModel = viewModel.eventEditorViewModel {
                EventEditorView(viewModel: editorViewModel) {
                    viewModel.dismissEventEditor()
                }
            }
        }
    }

    @ViewBuilder
    private var templatePickerCover: some View {
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

    @ViewBuilder
    private var templatesManagerCover: some View {
        if let manager = viewModel.templatesViewModel {
            EventTemplatesView(viewModel: manager) {
                viewModel.dismissTemplatesManager()
            }
        }
    }

    @ViewBuilder
    private var quickScheduleSheet: some View {
        if let operation = viewModel.quickScheduleOperation,
           let event = viewModel.quickScheduleEvent {
            EventQuickScheduleSheet(
                operation: operation,
                isAllDay: event.isAllDay,
                selectedDate: $viewModel.quickScheduleDate,
                onConfirm: {
                    await viewModel.confirmQuickSchedule()
                },
                onCancel: {
                    viewModel.dismissQuickSchedule()
                }
            )
        }
    }

    // MARK: - Content Helpers

    /// Localized medium date for the selected day.
    private var dayTitle: String {
        viewModel.date.formatted(
            Date.FormatStyle(date: .complete, time: .omitted)
                .locale(.autoupdatingCurrent)
        )
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Day Events") {
    let day = Date()
    let persistence = EventPersistenceService(
        repository: EventsPreviewRepository(
            seed: [
                Event(
                    title: "Vacaciones",
                    date: day,
                    isAllDay: true,
                    color: .yellow
                ),
                Event(title: "Entrenamiento", date: day.addingTimeInterval(9 * 3600), color: .green),
                Event(
                    title: "Reunión",
                    date: day.addingTimeInterval(12 * 3600),
                    status: .inProgress,
                    color: .orange
                )
            ]
        )
    )

    DayEventsView(
        viewModel: DayEventsViewModel(
            date: day,
            persistenceService: persistence
        ),
        onDismiss: {}
    )
    .environment(ThemeManager())
    .environment(CalendarAppearanceManager())
    .environment(persistence)
    .task {
        do {
            try await persistence.refresh()
        } catch {
            // Failure recorded on EventPersistenceService.lastError.
        }
    }
}
#endif
