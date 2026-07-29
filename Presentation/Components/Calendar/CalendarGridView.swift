//
//  CalendarGridView.swift
//  GalacticCalendar
//

import SwiftUI

/// Approved monthly calendar grid.
///
/// Presentation only: day annotations and selection live in ``CalendarGridViewModel``,
/// which reads the reactive ``EventPersistenceService`` catalog.
struct CalendarGridView: View {

    // MARK: - Environment

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Properties

    /// Grid presentation model (structure + reactive annotations).
    @Bindable var viewModel: CalendarGridViewModel

    /// Called after an in-month day is selected.
    private let onDaySelected: ((CalendarDay) -> Void)?

    // MARK: - Lifecycle

    /// Creates the grid bound to a ViewModel.
    /// - Parameters:
    ///   - viewModel: Calendar grid ViewModel.
    ///   - onDaySelected: Optional handler invoked with the tapped in-month day.
    init(
        viewModel: CalendarGridViewModel,
        onDaySelected: ((CalendarDay) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onDaySelected = onDaySelected
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
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("\(viewModel.displayedMonth)/\(viewModel.displayedYear)"))
    }

    // MARK: - Cells

    @ViewBuilder
    private func dayCell(for day: CalendarDay) -> some View {
        CalendarDayCell(day: day)
            .id(CalendarDayRefreshIdentity.token(for: day))
            .contentShape(Rectangle())
            .onTapGesture {
                guard viewModel.selectDay(day) else { return }
                onDaySelected?(day)
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
    .environment(persistence)
    .task {
        do {
            try await persistence.bootstrap()
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

    func fetchRecurring() async throws -> [Event] { [] }

    func update(_ event: Event) async throws {}

    func delete(_ event: Event) async throws {}

    func delete(id: UUID) async throws {}

    func duplicate(_ event: Event) async throws -> Event { event.duplicated() }
}
#endif
