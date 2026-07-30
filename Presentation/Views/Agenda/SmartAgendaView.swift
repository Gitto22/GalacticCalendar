//
//  SmartAgendaView.swift
//  GalacticCalendar
//

import SwiftUI

/// Smart Daily Agenda — day summary, Universe Message, timeline, free time, next event.
struct SmartAgendaView: View {

    @Bindable var viewModel: SmartAgendaViewModel
    private let onDismiss: () -> Void

    init(viewModel: SmartAgendaViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            MonthBackgroundView()

            VStack(spacing: Spacing.stackLoose) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.stackLoose) {
                        AgendaSummaryCard(
                            style: .header,
                            weekdayTitle: viewModel.weekdayTitle,
                            dateTitle: viewModel.dateTitle,
                            eventCount: viewModel.summary.eventCount,
                            occupiedText: viewModel.durationText(viewModel.summary.occupiedSeconds),
                            freeText: viewModel.durationText(viewModel.summary.freeSeconds)
                        )

                        universeSection

                        if let next = viewModel.nextEvent {
                            nextEventCard(next)
                        }

                        allDaySection

                        AgendaTimelineView(
                            items: viewModel.timeline,
                            durationText: { viewModel.eventDurationText($0) },
                            freeRangeText: {
                                viewModel.timeRangeText(start: $0.start, end: $0.end)
                            },
                            freeDurationText: {
                                viewModel.durationText($0.duration)
                            },
                            onEventTap: { event in
                                viewModel.presentEdit(for: event)
                            }
                        )

                        AgendaSummaryCard(
                            style: .endOfDay,
                            weekdayTitle: viewModel.weekdayTitle,
                            dateTitle: viewModel.dateTitle,
                            eventCount: viewModel.summary.eventCount,
                            occupiedText: viewModel.durationText(viewModel.summary.occupiedSeconds),
                            freeText: viewModel.durationText(viewModel.summary.freeSeconds)
                        )
                    }
                    .padding(.bottom, Spacing.pageVertical)
                }
            }
            .padding(.horizontal, Spacing.pageHorizontal)
            .padding(.top, Spacing.md)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("smart_agenda_screen")
        .task {
            await viewModel.bootstrap()
        }
        .fullScreenCover(
            isPresented: $viewModel.isPresentingEventEditor,
            onDismiss: { viewModel.dismissEventEditor() }
        ) {
            if let editor = viewModel.eventEditorViewModel {
                ZStack {
                    MonthBackgroundView()
                    EventEditorView(viewModel: editor) {
                        viewModel.dismissEventEditor()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            Text(String(localized: "agenda_title"))
                .font(Typography.title2)
                .foregroundStyle(ColorPalette.onImagePrimary)
                .lineLimit(1)
                .minimumScaleFactor(LayoutConstants.singleLineMinimumScale)

            Spacer(minLength: Spacing.xs)

            GlassCircleButton(
                systemImage: Icons.Calendar.previous,
                font: Typography.title3,
                foreground: ColorPalette.onImagePrimary,
                showsGlow: false
            ) {
                viewModel.goToPreviousDay()
            }
            .accessibilityLabel(Text(String(localized: "agenda_previous_day_a11y")))

            if viewModel.isShowingToday == false {
                Button(String(localized: "agenda_today")) {
                    viewModel.goToToday()
                }
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.onImageAccent)
            }

            GlassCircleButton(
                systemImage: Icons.Calendar.next,
                font: Typography.title3,
                foreground: ColorPalette.onImagePrimary,
                showsGlow: false
            ) {
                viewModel.goToNextDay()
            }
            .accessibilityLabel(Text(String(localized: "agenda_next_day_a11y")))

            GlassCircleButton(
                systemImage: Icons.Events.add,
                font: Typography.title3,
                foreground: ColorPalette.onImagePrimary,
                showsGlow: false
            ) {
                viewModel.presentNewEvent()
            }
            .accessibilityLabel(Text(String(localized: "day_events_new_event")))
            .accessibilityIdentifier("agenda_add_event")

            GlassCircleButton(
                systemImage: Icons.Navigation.close,
                font: Typography.title3,
                foreground: ColorPalette.onImagePrimary,
                showsGlow: false
            ) {
                onDismiss()
            }
            .accessibilityLabel(Text(String(localized: "agenda_close")))
            .accessibilityIdentifier("agenda_close")
        }
    }

    // MARK: - Universe

    @ViewBuilder
    private var universeSection: some View {
        if viewModel.universeMessage.isEmpty == false {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label(
                    String(localized: "universe_message_caption"),
                    systemImage: Icons.Home.quote
                )
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.onImageAccent)

                Text(viewModel.universeMessage)
                    .font(Typography.callout)
                    .foregroundStyle(ColorPalette.onImagePrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Spacing.md)
            .galacticGlassCard(.subtle, cornerRadius: Spacing.Radius.lg)
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: - Next event

    private func nextEventCard(_ event: Event) -> some View {
        Button {
            viewModel.presentEdit(for: event)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(String(localized: "agenda_next_event_title"))
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.onImageAccent)

                EventColorTitleRow(
                    event: event,
                    titleLineLimit: 2,
                    subtitle: event.startDate.formatted(date: .omitted, time: .shortened)
                )
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
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
        .accessibilityLabel(
            Text("\(String(localized: "agenda_next_event_title")), \(event.title)")
        )
        .accessibilityHint(Text(String(localized: "agenda_event_a11y_hint")))
        .accessibilityIdentifier("agenda_next_event")
    }

    // MARK: - All day

    @ViewBuilder
    private var allDaySection: some View {
        if viewModel.allDayEvents.isEmpty == false {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(String(localized: "agenda_all_day_title"))
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.editorPlaceholder)

                ForEach(viewModel.allDayEvents) { event in
                    Button {
                        viewModel.presentEdit(for: event)
                    } label: {
                        EventColorTitleRow(
                            event: event,
                            titleFont: Typography.subheadline,
                            trailing: String(localized: "event_all_day_label")
                        )
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.sm)
                        .background {
                            RoundedRectangle(cornerRadius: Spacing.Radius.md, style: .continuous)
                                .fill(ColorPalette.editorTileFill)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        Text("\(event.title), \(String(localized: "event_all_day_label"))")
                    )
                    .accessibilityHint(Text(String(localized: "agenda_event_a11y_hint")))
                    .accessibilityIdentifier("agenda_all_day_\(event.id.uuidString)")
                }
            }
        } else if viewModel.isEmptyDay {
            Text(String(localized: "agenda_empty_day"))
                .font(Typography.callout)
                .foregroundStyle(ColorPalette.editorPlaceholder)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
