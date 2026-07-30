//
//  MonthPickerView.swift
//  GalacticCalendar
//

import SwiftUI

/// Quick month selector (January…December) for Galactic Calendar.
///
/// Opened from the Home month title. Selecting a month notifies the caller
/// so Home can update the grid, background, title, and events while keeping the year.
struct MonthPickerView: View {

    // MARK: - Properties

    /// Observable picker state.
    @Bindable var viewModel: MonthPickerViewModel

    /// Called after a valid month is chosen (Home applies + dismisses).
    private let onMonthSelected: (Int) -> Void

    /// Dismiss without changing the visible month.
    private let onDismiss: () -> Void

    // MARK: - Lifecycle

    /// Creates the month picker screen.
    /// - Parameters:
    ///   - viewModel: Bound picker ViewModel.
    ///   - onMonthSelected: Invoked with the chosen month number (`1...12`).
    ///   - onDismiss: Close without selection.
    init(
        viewModel: MonthPickerViewModel,
        onMonthSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onMonthSelected = onMonthSelected
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            MonthBackgroundView()

            VStack(spacing: Spacing.stackLoose) {
                header
                monthList
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
            Text(String(localized: "calendar_month_picker_title"))
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
            .accessibilityIdentifier("month_picker_close")
        }
    }

    // MARK: - List

    /// Scrollable January…December rows.
    private var monthList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(viewModel.months) { item in
                    monthRow(item)
                }
            }
        }
    }

    /// Single month row.
    private func monthRow(_ item: MonthPickerItem) -> some View {
        let isSelected = viewModel.isSelected(item.month)

        return Button {
            guard viewModel.selectMonth(item.month) else {
                return
            }
            onMonthSelected(item.month)
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
        .accessibilityHint(String(localized: "calendar_month_picker_row_a11y_hint"))
        .accessibilityValue(
            isSelected
                ? String(localized: "calendar_day_selected_a11y")
                : String(localized: "calendar_day_not_selected_a11y")
        )
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("month_picker_\(item.month)")
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Month Picker") {
    MonthPickerView(
        viewModel: MonthPickerViewModel(selectedMonth: 7, year: 2026),
        onMonthSelected: { _ in },
        onDismiss: {}
    )
    .environment(ThemeManager())
    .environment(CalendarAppearanceManager())
}
#endif
