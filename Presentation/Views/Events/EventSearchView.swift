//
//  EventSearchView.swift
//  GalacticCalendar
//

import SwiftUI

/// Incremental event search / filter screen (Sprint 6.7).
///
/// Views only render state from ``EventSearchViewModel``.
struct EventSearchView: View {

    @Bindable var viewModel: EventSearchViewModel
    private let onDismiss: () -> Void
    private let onSelectEvent: ((Event) -> Void)?

    init(
        viewModel: EventSearchViewModel,
        onSelectEvent: ((Event) -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onSelectEvent = onSelectEvent
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            MonthBackgroundView()

            VStack(spacing: Spacing.stackLoose) {
                header
                searchField
                filtersScroll
                resultsContent
            }
            .padding(.horizontal, Spacing.pageHorizontal)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.pageVertical)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            Text(String(localized: "event_search_title"))
                .font(Typography.title2)
                .foregroundStyle(ColorPalette.onImagePrimary)
                .lineLimit(1)
                .minimumScaleFactor(LayoutConstants.singleLineMinimumScale)

            Spacer(minLength: Spacing.xs)

            if viewModel.hasActiveFilters {
                Button(String(localized: "event_search_clear")) {
                    viewModel.clearFilters()
                }
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.onImageAccent)
                .accessibilityIdentifier("event_search_clear")
            }

            GlassCircleButton(
                systemImage: Icons.Navigation.close,
                font: Typography.title3,
                foreground: ColorPalette.onImagePrimary,
                showsGlow: false
            ) {
                onDismiss()
            }
            .accessibilityLabel(Text(String(localized: "event_search_close")))
            .accessibilityHint(Text(String(localized: "event_search_close_a11y_hint")))
            .accessibilityIdentifier("event_search_close")
        }
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: Icons.Universe.search)
                .font(Typography.callout)
                .foregroundStyle(ColorPalette.onImageAccent)

            TextField(
                String(localized: "event_search_placeholder"),
                text: $viewModel.searchText
            )
            .font(Typography.callout)
            .foregroundStyle(ColorPalette.onImagePrimary)
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
            .autocorrectionDisabled()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .galacticGlassCard(.subtle, cornerRadius: Spacing.Radius.lg)
        .accessibilityLabel(Text(String(localized: "event_search_placeholder")))
        .accessibilityIdentifier("event_search_field")
    }

    // MARK: - Filters

    private var filtersScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                dateRangeChips
                tagChips
                priorityChips
                colorChips
                facetChips
            }
        }
    }

    private var dateRangeChips: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(EventSearchCriteria.QuickDateRange.allCases) { range in
                filterChip(
                    title: quickRangeTitle(range),
                    isSelected: viewModel.quickDateRange == range && viewModel.onDate == nil
                ) {
                    viewModel.setQuickDateRange(range)
                }
            }
        }
    }

    private var tagChips: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(EventTagPreset.allCases) { preset in
                filterChip(
                    title: EventEditorDisplayNames.title(for: preset),
                    isSelected: viewModel.selectedTagIDs.contains(preset.rawValue)
                ) {
                    viewModel.toggleTag(preset)
                }
            }
        }
    }

    private var priorityChips: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(EventPriority.allCases) { priority in
                filterChip(
                    title: EventEditorDisplayNames.title(for: priority),
                    isSelected: viewModel.selectedPriorities.contains(priority)
                ) {
                    viewModel.togglePriority(priority)
                }
            }
        }
    }

    private var colorChips: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(EventColor.allCases) { color in
                Button {
                    viewModel.toggleColor(color)
                } label: {
                    Circle()
                        .fill(ColorPalette.color(for: color))
                        .frame(width: LayoutConstants.eventColorDotSize, height: LayoutConstants.eventColorDotSize)
                        .overlay {
                            Circle()
                                .stroke(
                                    viewModel.selectedColors.contains(color)
                                        ? ColorPalette.onImagePrimary
                                        : Color.clear,
                                    lineWidth: Spacing.selectionStroke
                                )
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(EventEditorDisplayNames.title(for: color)))
                .accessibilityHint(Text(String(localized: "event_color_a11y_hint")))
                .accessibilityAddTraits(viewModel.selectedColors.contains(color) ? .isSelected : [])
                .accessibilityIdentifier("event_search_color_\(color.rawValue)")
            }
        }
    }

    private var facetChips: some View {
        HStack(spacing: Spacing.xs) {
            filterChip(
                title: triStateTitle(
                    String(localized: "event_field_all_day"),
                    value: viewModel.isAllDay
                ),
                isSelected: viewModel.isAllDay != nil
            ) {
                viewModel.cycleTriState(\.isAllDay)
            }

            filterChip(
                title: triStateTitle(
                    String(localized: "event_search_filter_multiday"),
                    value: viewModel.isMultiDay
                ),
                isSelected: viewModel.isMultiDay != nil
            ) {
                viewModel.cycleTriState(\.isMultiDay)
            }

            filterChip(
                title: triStateTitle(
                    String(localized: "event_search_filter_recurring"),
                    value: viewModel.isRecurring
                ),
                isSelected: viewModel.isRecurring != nil
            ) {
                viewModel.cycleTriState(\.isRecurring)
            }

            filterChip(
                title: triStateTitle(
                    String(localized: "event_search_filter_reminder"),
                    value: viewModel.hasReminder
                ),
                isSelected: viewModel.hasReminder != nil
            ) {
                viewModel.cycleTriState(\.hasReminder)
            }
        }
    }

    private func filterChip(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(Typography.caption)
                .foregroundStyle(
                    isSelected ? ColorPalette.onImagePrimary : ColorPalette.editorPlaceholder
                )
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background {
                    Capsule(style: .continuous)
                        .fill(
                            isSelected
                                ? ColorPalette.editorAccent.opacity(ColorPalette.glassStrokeSubtleOpacity)
                                : ColorPalette.editorTileFill
                        )
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
        .accessibilityHint(Text(String(localized: "event_search_filter_a11y_hint")))
        .accessibilityValue(
            Text(
                isSelected
                    ? String(localized: "calendar_day_selected_a11y")
                    : String(localized: "calendar_day_not_selected_a11y")
            )
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("event_search_filter_\(title)")
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsContent: some View {
        if viewModel.hasActiveFilters == false {
            Text(String(localized: "event_search_prompt"))
                .font(Typography.callout)
                .foregroundStyle(ColorPalette.editorPlaceholder)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .accessibilityLabel(Text(String(localized: "event_search_prompt")))
                .accessibilityIdentifier("event_search_prompt")
        } else if viewModel.isResultsEmpty {
            Text(String(localized: "event_search_empty"))
                .font(Typography.callout)
                .foregroundStyle(ColorPalette.editorPlaceholder)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .accessibilityLabel(Text(String(localized: "event_search_empty")))
                .accessibilityIdentifier("event_search_empty")
        } else {
            List {
                Section {
                    ForEach(viewModel.results) { event in
                        Button {
                            onSelectEvent?(event)
                        } label: {
                            EventColorTitleRow(
                                event: event,
                                subtitle: event.date.formatted(
                                    date: .abbreviated,
                                    time: event.isAllDay ? .omitted : .shortened
                                )
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            Text("\(event.title), \(event.date.formatted(date: .abbreviated, time: event.isAllDay ? .omitted : .shortened))")
                        )
                        .accessibilityHint(Text(String(localized: "event_search_result_a11y_hint")))
                        .accessibilityIdentifier("event_search_result_\(event.id.uuidString)")
                    }
                } header: {
                    Text(
                        String(
                            format: String(localized: "event_search_results_count_format"),
                            locale: .current,
                            viewModel.results.count
                        )
                    )
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.editorPlaceholder)
                    .textCase(nil)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect(.subtle, cornerRadius: Spacing.Radius.xl)
        }
    }

    // MARK: - Labels

    private func quickRangeTitle(_ range: EventSearchCriteria.QuickDateRange) -> String {
        switch range {
        case .any:
            String(localized: "event_search_range_any")
        case .today:
            String(localized: "event_search_range_today")
        case .thisWeek:
            String(localized: "event_search_range_week")
        case .thisMonth:
            String(localized: "event_search_range_month")
        }
    }

    private func triStateTitle(_ base: String, value: Bool?) -> String {
        switch value {
        case true:
            base
        case false:
            String(format: String(localized: "event_search_filter_not_format"), locale: .current, base)
        case nil:
            base
        }
    }
}
