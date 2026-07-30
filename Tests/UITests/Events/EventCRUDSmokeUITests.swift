//
//  EventCRUDSmokeUITests.swift
//  GalacticCalendarUITests
//
//  QA-01 — Create / Edit / Delete event.
//

import XCTest

final class EventCRUDSmokeUITests: SmokeUITestCase {

    func testCreateEditDeleteEventOnToday() {
        let createdTitle = uniqueTitle(prefix: "QA Create")
        let editedTitle = uniqueTitle(prefix: "QA Edit")

        openCreateEditorForToday()
        createEventFromOpenEditor(title: createdTitle)
        assertHomeReady()

        openEditEditorForToday()
        let titleField = element(SmokeAccessibilityID.eventEditorTitle)
        XCTAssertTrue(titleField.waitForExistence(timeout: defaultTimeout))
        replaceText(in: titleField, with: editedTitle)
        tap(SmokeAccessibilityID.eventEditorConfirm)
        XCTAssertTrue(
            element(SmokeAccessibilityID.eventEditor).waitForNonExistence(timeout: defaultTimeout)
        )
        assertHomeReady()

        openEditEditorForToday()
        deleteOpenEvent()
        assertHomeReady()
    }
}
