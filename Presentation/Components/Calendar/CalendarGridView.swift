//
//  CalendarGridView.swift
//  GalacticCalendar
//

import SwiftUI

/// Approved monthly calendar grid.
///
/// Presentation only: day annotations and selection live in
/// ``CalendarGridViewModel``. Month swipes emit ``CalendarMonthNavigationIntent``
/// to Home (no navigation logic in the view). Layout is unchanged.
struct CalendarGridView: View {

    // MARK: - Environment

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Honors system Reduce Motion for period transitions.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Properties

    /// Grid presentation model (structure + reactive annotations).
    @Bindable var viewModel: CalendarGridViewModel

    /// Called after an in-month day is selected.
    private let onDaySelected: ((CalendarDay) -> Void)?

    /// Called when a horizontal swipe commits a month change.
    private let onMonthNavigate: ((CalendarMonthNavigationIntent) -> Void)?

    // MARK: - Lifecycle

    /// Creates the grid bound to a ViewModel.
    /// - Parameters:
    ///   - viewModel: Calendar grid ViewModel.
    ///   - onDaySelected: Optional handler invoked with the tapped in-month day.
    ///   - onMonthNavigate: Optional swipe / month-navigation handler.
    init(
        viewModel: CalendarGridViewModel,
        onDaySelected: ((CalendarDay) -> Void)? = nil,
        onMonthNavigate: ((CalendarMonthNavigationIntent) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onDaySelected = onDaySelected
        self.onMonthNavigate = onMonthNavigate
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: gridSpacing) {
            WeekHeaderView()

            LazyVGrid(columns: Self.columns, spacing: gridSpacing) {
                ForEach(viewModel.presentedDays) { day in
                    dayCell(for: day)
                }
            }
            .frame(maxWidth: .infinity)
            .animation(
                Motion.resolved(Motion.calendarMonthChange, reduceMotion: reduceMotion),
                value: periodToken
            )
        }
        .contentShape(Rectangle())
        .simultaneousGesture(monthSwipeGesture)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(periodAccessibilityLabel))
        .accessibilityHint(Text(String(localized: "calendar_month_swipe_a11y_hint")))
        .accessibilityIdentifier("calendar_grid")
    }

    // MARK: - Cells

    @ViewBuilder
    private func dayCell(for day: CalendarDay) -> some View {
        Button {
            guard viewModel.selectDay(day) else { return }
            onDaySelected?(day)
        } label: {
            CalendarDayCell(day: day)
        }
        .buttonStyle(.plain)
        .disabled(day.isCurrentMonth == false)
        .accessibilityIdentifier(Self.dayAccessibilityIdentifier(for: day))
        .id(CalendarDayRefreshIdentity.token(for: day))
    }

    /// Stable UI-test identifier for an in-month day (`calendar_day_today` / `calendar_day_N`).
    private static func dayAccessibilityIdentifier(for day: CalendarDay) -> String {
        guard day.isCurrentMonth else {
            return "calendar_day_outside"
        }
        if day.isToday {
            return "calendar_day_today"
        }
        return "calendar_day_\(day.dayNumber)"
    }

    // MARK: - Period

    /// Stable identity for the displayed month/year (drives discreet grid animation).
    private var periodToken: String {
        "\(viewModel.displayedYear)-\(viewModel.displayedMonth)"
    }

    /// Localized month + year for VoiceOver on the grid container.
    private var periodAccessibilityLabel: String {
        var components = DateComponents()
        components.year = viewModel.displayedYear
        components.month = viewModel.displayedMonth
        components.day = 1
        guard let date = Calendar.current.date(from: components) else {
            return "\(viewModel.displayedMonth)/\(viewModel.displayedYear)"
        }
        return date.formatted(.dateTime.month(.wide).year())
    }

    // MARK: - Swipe

    /// Horizontal swipe → month intent (left = next, right = previous).
    ///
    /// Commits once on gesture end so rapid consecutive swipes each apply a
    /// full ``showMonth`` transition (no intermediate inconsistent month).
    private var monthSwipeGesture: some Gesture {
        DragGesture(
            minimumDistance: CalendarConstants.monthSwipeMinimumDistance,
            coordinateSpace: .local
        )
        .onEnded { value in
            guard let onMonthNavigate else {
                return
            }
            guard let intent = Self.monthNavigationIntent(for: value) else {
                return
            }
            onMonthNavigate(intent)
        }
    }

    /// Maps a finished drag to a navigation intent, if the swipe qualifies.
    private static func monthNavigationIntent(
        for value: DragGesture.Value
    ) -> CalendarMonthNavigationIntent? {
        let horizontal = value.translation.width
        let vertical = value.translation.height
        let minimum = CalendarConstants.monthSwipeMinimumDistance

        guard abs(horizontal) >= minimum else {
            return nil
        }
        guard abs(horizontal) >= abs(vertical) * CalendarConstants.monthSwipeHorizontalDominance else {
            return nil
        }

        let stepCount = Self.stepCount(
            forHorizontalTranslation: horizontal,
            predicted: value.predictedEndTranslation.width
        )

        if horizontal < 0 {
            return CalendarMonthNavigationIntent(
                direction: .next,
                stepCount: stepCount,
                prefersAnimation: true
            )
        }
        return CalendarMonthNavigationIntent(
            direction: .previous,
            stepCount: stepCount,
            prefersAnimation: true
        )
    }

    /// Derives how many months a flick should skip (1…3).
    private static func stepCount(
        forHorizontalTranslation translation: CGFloat,
        predicted: CGFloat
    ) -> Int {
        let distance = max(abs(translation), abs(predicted))
        switch distance {
        case 180...:
            return 3
        case 120..<180:
            return 2
        default:
            return 1
        }
    }

    // MARK: - Grid

    private static let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: Spacing.xxs),
        count: CalendarConstants.columnCount
    )

    private var gridSpacing: CGFloat {
        horizontalSizeClass == .regular ? Spacing.xs : Spacing.xxs
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Calendar Grid — Current Month") {
    let persistence = EventPersistenceService(
        repository: PreviewGridEventRepository()
    )

    ZStack {
        MonthBackgroundView()
        CalendarGridView(
            viewModel: CalendarGridViewModel(persistenceService: persistence)
        )
        .padding(.horizontal, Spacing.pageHorizontal)
    }
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

@MainActor
private final class PreviewGridEventRepository: EventRepositoryProtocol {

    func create(_ event: Event) async throws {}

    func fetchAll() async throws -> [Event] { [] }

    func fetch(by id: UUID) async throws -> Event? { nil }

    func fetch(on date: Date) async throws -> [Event] { [] }

    func fetch(in interval: DateInterval) async throws -> [Event] { [] }

    func fetchGroupedByDay(in interval: DateInterval) async throws -> [Date: [Event]] { [:] }

    func update(_ event: Event) async throws {}

    func delete(_ event: Event) async throws {}

    func delete(id: UUID) async throws {}

    func duplicate(_ event: Event) async throws -> Event { event.duplicated() }
}
#endif
