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
                newEventButton
            }
            .padding(.horizontal, Spacing.pageHorizontal)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.pageVertical)
        }
        .fullScreenCover(
            isPresented: $viewModel.isPresentingEventEditor,
            onDismiss: {
                viewModel.dismissEventEditor()
            }
        ) {
            eventEditorCover
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

            Spacer(minLength: Spacing.xs)

            GlassCircleButton(
                systemImage: Icons.Navigation.close,
                font: Typography.title3,
                foreground: ColorPalette.onImagePrimary,
                showsGlow: false
            ) {
                onDismiss()
            }
            .accessibilityLabel(Text(String(localized: "day_events_close")))
        }
    }

    // MARK: - List

    /// Scrollable event rows with swipe-to-delete.
    private var eventsList: some View {
        List {
            ForEach(viewModel.events) { event in
                EventRow(
                    event: event,
                    onTap: { viewModel.presentEdit(for: event) },
                    onEdit: { viewModel.presentEdit(for: event) },
                    onDuplicate: {
                        Task { await viewModel.duplicate(event) }
                    },
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
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassEffect(.subtle, cornerRadius: Spacing.Radius.xl)
    }

    // MARK: - New Event

    /// Bottom action that opens ``EventEditorView`` for creation.
    private var newEventButton: some View {
        Button {
            viewModel.presentNewEvent()
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: Icons.Events.add)
                    .font(Typography.headline)
                    .foregroundStyle(ColorPalette.editorAccent)

                Text(String(localized: "day_events_new_event"))
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
        .accessibilityLabel(Text(String(localized: "day_events_new_event")))
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
    let persistence = EventPersistenceService(
        repository: PreviewDayEventsRepository()
    )

    DayEventsView(
        viewModel: DayEventsViewModel(
            date: Date(),
            persistenceService: persistence
        ),
        onDismiss: {}
    )
    .environment(ThemeManager())
    .environment(persistence)
}

@MainActor
private final class PreviewDayEventsRepository: EventRepositoryProtocol {

    func create(_ event: Event) async throws {}

    func fetchAll() async throws -> [Event] { [] }

    func fetch(by id: UUID) async throws -> Event? { nil }

    func fetch(on date: Date) async throws -> [Event] {
        [
            Event(title: "Entrenamiento", date: date.addingTimeInterval(9 * 3600), color: .green),
            Event(title: "Reunión", date: date.addingTimeInterval(12 * 3600), status: .inProgress, color: .orange)
        ]
    }

    func fetch(in interval: DateInterval) async throws -> [Event] { [] }

    func fetchGroupedByDay(in interval: DateInterval) async throws -> [Date: [Event]] { [:] }

    func fetchRecurring() async throws -> [Event] { [] }

    func update(_ event: Event) async throws {}

    func delete(_ event: Event) async throws {}

    func delete(id: UUID) async throws {}

    func duplicate(_ event: Event) async throws -> Event { event.duplicated() }
}
#endif
