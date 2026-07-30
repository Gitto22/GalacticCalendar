//
//  YearPickerView.swift
//  GalacticCalendar
//

import SwiftUI

/// Scrollable year selector for Galactic Calendar.
///
/// Opened from the Home year label. Selecting a year notifies the caller
/// so Home can update the grid, header, background, and events while keeping the month.
struct YearPickerView: View {

    // MARK: - Properties

    /// Observable picker state.
    @Bindable var viewModel: YearPickerViewModel

    /// Called after a valid year is chosen (Home applies + dismisses).
    private let onYearSelected: (Int) -> Void

    /// Dismiss without changing the visible year.
    private let onDismiss: () -> Void

    // MARK: - Lifecycle

    /// Creates the year picker screen.
    /// - Parameters:
    ///   - viewModel: Bound picker ViewModel.
    ///   - onYearSelected: Invoked with the chosen year.
    ///   - onDismiss: Close without selection.
    init(
        viewModel: YearPickerViewModel,
        onYearSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onYearSelected = onYearSelected
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            MonthBackgroundView()

            VStack(spacing: Spacing.stackLoose) {
                header
                yearList
            }
            .padding(.horizontal, Spacing.pageHorizontal)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.pageVertical)
        }
    }

    // MARK: - Header

    /// Title and close control.
    private var header: some View {
        HStack(spacing: Spacing.sm) {
            Text(String(localized: "calendar_year_picker_title"))
                .font(Typography.title2)
                .foregroundStyle(ColorPalette.onImagePrimary)
                .lineLimit(1)
                .minimumScaleFactor(LayoutConstants.singleLineMinimumScale)

            Spacer(minLength: Spacing.xs)

            GlassCircleButton(
                systemImage: Icons.Navigation.close,
                font: Typography.title3,
                foreground: ColorPalette.onImagePrimary,
                showsGlow: false
            ) {
                onDismiss()
            }
            .accessibilityLabel(String(localized: "event_editor_close"))
            .accessibilityIdentifier("year_picker_close")
        }
    }

    // MARK: - List

    /// Scrollable year rows; opens near the current selection.
    private var yearList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(viewModel.years) { item in
                        yearRow(item)
                            .id(item.year)
                    }
                }
            }
            .task {
                proxy.scrollTo(viewModel.selectedYear, anchor: .center)
            }
        }
    }

    /// Single year row.
    private func yearRow(_ item: YearPickerItem) -> some View {
        let isSelected = viewModel.isSelected(item.year)

        return Button {
            guard viewModel.selectYear(item.year) else {
                return
            }
            onYearSelected(item.year)
        } label: {
            HStack(spacing: Spacing.sm) {
                Text(item.title)
                    .font(Typography.callout)
                    .foregroundStyle(ColorPalette.onImagePrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Image(systemName: Icons.Status.success)
                        .font(Typography.subheadline)
                        .foregroundStyle(ColorPalette.universeAccent)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .galacticGlassCard(
                isSelected ? .regular : .subtle,
                cornerRadius: Spacing.Radius.lg
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityHint(String(localized: "calendar_year_picker_row_a11y_hint"))
        .accessibilityValue(
            isSelected
                ? String(localized: "calendar_day_selected_a11y")
                : String(localized: "calendar_day_not_selected_a11y")
        )
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("year_picker_\(item.year)")
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Year Picker") {
    YearPickerView(
        viewModel: YearPickerViewModel(selectedYear: 2026, month: 7),
        onYearSelected: { _ in },
        onDismiss: {}
    )
    .environment(ThemeManager())
    .environment(CalendarAppearanceManager())
}
#endif
