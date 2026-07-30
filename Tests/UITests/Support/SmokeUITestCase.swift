//
//  SmokeUITestCase.swift
//  GalacticCalendarUITests
//
//  Shared XCUITest helpers for QA-01 smoke flows.
//  Prefer accessibility identifiers over localized labels / coordinates.
//

import XCTest

/// Base case for Private Beta UI smoke tests.
///
/// Each test launches a fresh app instance (independent / repeatable).
class SmokeUITestCase: XCTestCase {

    // MARK: - Properties

    var app: XCUIApplication!

    /// Default wait for screen transitions after bootstrap / sheets.
    let defaultTimeout: TimeInterval = 8

    /// Short poll for optional branch detection (editor vs day list).
    let branchTimeout: TimeInterval = 3

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-ui-testing"
        ]
        app.launch()
        dismissBlockingAlertIfNeeded()
        assertHomeReady()
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - Home

    /// Waits until Home chrome and calendar are interactive.
    func assertHomeReady() {
        XCTAssertTrue(
            element(SmokeAccessibilityID.homeScreen).waitForExistence(timeout: defaultTimeout),
            "Home screen did not appear"
        )
        XCTAssertTrue(
            element(SmokeAccessibilityID.calendarGrid).waitForExistence(timeout: defaultTimeout),
            "Calendar grid did not appear"
        )
    }

    /// Current month title accessibility label (English launch locale).
    func monthTitleLabel() -> String {
        let title = element(SmokeAccessibilityID.homeMonthTitle)
        XCTAssertTrue(title.waitForExistence(timeout: defaultTimeout))
        return title.label
    }

    /// Jumps to today via the header control.
    func goToToday() {
        tap(SmokeAccessibilityID.homeToday)
        XCTAssertTrue(
            element(SmokeAccessibilityID.calendarDayToday).waitForExistence(timeout: defaultTimeout),
            "Today cell missing after Go To Today"
        )
    }

    // MARK: - Calendar / Day routing

    /// Opens the create editor for today, tolerating 0 / 1 / 2+ existing events.
    func openCreateEditorForToday() {
        goToToday()
        tap(SmokeAccessibilityID.calendarDayToday)

        if element(SmokeAccessibilityID.dayEventsScreen).waitForExistence(timeout: branchTimeout) {
            tap(SmokeAccessibilityID.dayEventsNewEvent)
        } else if element(SmokeAccessibilityID.eventEditor).waitForExistence(timeout: branchTimeout) {
            if element(SmokeAccessibilityID.eventEditorDelete).exists {
                tap(SmokeAccessibilityID.eventEditorClose)
                openSmartAgenda()
                tap(SmokeAccessibilityID.agendaAddEvent)
            }
        }

        XCTAssertTrue(
            element(SmokeAccessibilityID.eventEditor).waitForExistence(timeout: defaultTimeout),
            "Event editor did not open for create"
        )
    }

    /// Opens today's day-events list, seeding a second event when required.
    func openDayEventsForToday() {
        goToToday()
        tap(SmokeAccessibilityID.calendarDayToday)

        if element(SmokeAccessibilityID.dayEventsScreen).waitForExistence(timeout: branchTimeout) {
            return
        }

        if element(SmokeAccessibilityID.eventEditor).waitForExistence(timeout: branchTimeout) {
            if element(SmokeAccessibilityID.eventEditorDelete).exists {
                tap(SmokeAccessibilityID.eventEditorClose)
                openSmartAgenda()
                createEventFromOpenEditor(title: uniqueTitle(prefix: "QA DayList"))
                tap(SmokeAccessibilityID.agendaClose)
                assertHomeReady()
                tap(SmokeAccessibilityID.calendarDayToday)
            } else {
                createEventFromOpenEditor(title: uniqueTitle(prefix: "QA Seed"))
                assertHomeReady()
                openSmartAgenda()
                tap(SmokeAccessibilityID.agendaAddEvent)
                createEventFromOpenEditor(title: uniqueTitle(prefix: "QA DayList"))
                tap(SmokeAccessibilityID.agendaClose)
                assertHomeReady()
                tap(SmokeAccessibilityID.calendarDayToday)
            }
        }

        XCTAssertTrue(
            element(SmokeAccessibilityID.dayEventsScreen).waitForExistence(timeout: defaultTimeout),
            "Day events screen did not appear"
        )
    }

    /// First event row on the day-events list (`event_row_*`).
    func firstEventRow() -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", SmokeAccessibilityID.eventRowPrefix))
            .firstMatch
    }

    // MARK: - Event editor

    /// Fills title and confirms; waits for editor dismissal.
    func createEventFromOpenEditor(title: String) {
        let titleField = element(SmokeAccessibilityID.eventEditorTitle)
        XCTAssertTrue(titleField.waitForExistence(timeout: defaultTimeout))
        replaceText(in: titleField, with: title)
        tap(SmokeAccessibilityID.eventEditorConfirm)
        XCTAssertTrue(
            element(SmokeAccessibilityID.eventEditor).waitForNonExistence(timeout: defaultTimeout),
            "Event editor did not dismiss after save"
        )
    }

    /// Opens edit for today (direct editor or via day-list first row).
    func openEditEditorForToday() {
        goToToday()
        tap(SmokeAccessibilityID.calendarDayToday)

        if element(SmokeAccessibilityID.dayEventsScreen).waitForExistence(timeout: branchTimeout) {
            let row = firstEventRow()
            XCTAssertTrue(row.waitForExistence(timeout: defaultTimeout), "No event row to edit")
            row.tap()
        }

        XCTAssertTrue(
            element(SmokeAccessibilityID.eventEditor).waitForExistence(timeout: defaultTimeout),
            "Edit editor did not open"
        )
        XCTAssertTrue(
            element(SmokeAccessibilityID.eventEditorDelete).exists,
            "Expected edit mode (delete control missing)"
        )
    }

    /// Deletes the open event via editor confirmation dialog.
    func deleteOpenEvent() {
        tap(SmokeAccessibilityID.eventEditorDelete)
        let confirm = element(SmokeAccessibilityID.eventEditorDeleteConfirm)
        if confirm.waitForExistence(timeout: branchTimeout) {
            confirm.tap()
        } else {
            let delete = app.sheets.buttons["Delete"].firstMatch
            XCTAssertTrue(delete.waitForExistence(timeout: branchTimeout), "Delete confirmation missing")
            delete.tap()
        }
        XCTAssertTrue(
            element(SmokeAccessibilityID.eventEditor).waitForNonExistence(timeout: defaultTimeout),
            "Editor did not dismiss after delete"
        )
    }

    // MARK: - Agenda

    func openSmartAgenda() {
        tap(SmokeAccessibilityID.homeMenu)
        let agendaItem = element(SmokeAccessibilityID.homeMenuAgenda)
        if agendaItem.waitForExistence(timeout: branchTimeout) {
            agendaItem.tap()
        } else {
            app.buttons["Daily Agenda"].firstMatch.tap()
        }
        XCTAssertTrue(
            element(SmokeAccessibilityID.smartAgendaScreen).waitForExistence(timeout: defaultTimeout),
            "Smart Agenda did not open"
        )
    }

    // MARK: - Utilities

    func uniqueTitle(prefix: String) -> String {
        "\(prefix) \(UUID().uuidString.prefix(8))"
    }

    func element(_ id: String) -> XCUIElement {
        app.descendants(matching: .any)[id]
    }

    func tap(_ id: String) {
        let target = element(id)
        XCTAssertTrue(target.waitForExistence(timeout: defaultTimeout), "Missing element: \(id)")
        target.tap()
    }

    /// Replaces field contents without relying on fragile clear sequences.
    func replaceText(in field: XCUIElement, with value: String) {
        field.tap()
        if app.menuItems["Select All"].waitForExistence(timeout: 1) {
            app.menuItems["Select All"].tap()
        } else {
            field.press(forDuration: 1.0)
            if app.menuItems["Select All"].waitForExistence(timeout: 1) {
                app.menuItems["Select All"].tap()
            }
        }
        field.typeText(value)
    }

    /// Dismisses storage / catalog alerts that can block first frame.
    func dismissBlockingAlertIfNeeded() {
        let alert = app.alerts.firstMatch
        guard alert.waitForExistence(timeout: 2) else { return }
        if alert.buttons["OK"].exists {
            alert.buttons["OK"].tap()
        } else if alert.buttons["Dismiss"].exists {
            alert.buttons["Dismiss"].tap()
        } else {
            alert.buttons.firstMatch.tap()
        }
    }
}

// MARK: - XCUIElement

extension XCUIElement {

    /// Waits until the element no longer exists.
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
