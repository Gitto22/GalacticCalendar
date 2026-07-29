//
//  EventValidationServiceTests.swift
//  GalacticCalendar
//

import XCTest
@testable import GalacticCalendar

/// Unit tests for ``EventValidationService``.
final class EventValidationServiceTests: XCTestCase {

    // MARK: - Fixtures

    private let service = EventValidationService(
        maximumTitleLength: 10,
        maximumDescriptionLength: 20
    )

    private func validEvent(
        title: String = "Valid",
        description: String = "",
        date: Date = Date(timeIntervalSince1970: 1_800_000_000),
        reminder: Date? = nil,
        repeatRule: RepeatRule = .none
    ) -> Event {
        Event(
            title: title,
            description: description,
            date: date,
            reminder: reminder,
            repeatRule: repeatRule,
            color: .green
        )
    }

    // MARK: - Title

    func testEmptyTitleIsRequired() {
        let issues = service.validate(validEvent(title: "   "))
        XCTAssertTrue(issues.contains(.titleRequired))
    }

    func testTitleTooLong() {
        let issues = service.validate(validEvent(title: "12345678901"))
        XCTAssertTrue(issues.contains(.titleTooLong(maximum: 10)))
    }

    // MARK: - Description

    func testDescriptionTooLong() {
        let issues = service.validate(validEvent(description: String(repeating: "a", count: 21)))
        XCTAssertTrue(issues.contains(.descriptionTooLong(maximum: 20)))
    }

    // MARK: - Dates

    func testReminderAfterEventIsInvalid() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let issues = service.validate(
            validEvent(date: date, reminder: date.addingTimeInterval(60))
        )
        XCTAssertTrue(issues.contains(.invalidReminder))
    }

    func testReminderAtOrBeforeEventIsValid() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let issues = service.validate(
            validEvent(date: date, reminder: date.addingTimeInterval(-300))
        )
        XCTAssertFalse(issues.contains(.invalidReminder))
        XCTAssertTrue(service.isValid(validEvent(date: date, reminder: date)))
    }

    func testEndDateBeforeStartIsInvalid() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let event = Event(
            title: "Valid",
            date: start,
            endDate: start.addingTimeInterval(-60),
            color: .green
        )
        XCTAssertTrue(service.validate(event).contains(.invalidEndDate))
    }

    func testInvalidTimeZoneIdentifier() {
        let event = Event(
            title: "Valid",
            date: Date(timeIntervalSince1970: 1_800_000_000),
            timeZoneIdentifier: "Not/A_Zone",
            color: .green
        )
        XCTAssertTrue(service.validate(event).contains(.invalidTimeZone))
    }

    // MARK: - Repeat

    func testInvalidRepeatInterval() {
        let rule = RepeatRule(frequency: .daily, interval: 0)
        let issues = service.validate(validEvent(repeatRule: rule))
        XCTAssertTrue(issues.contains(.invalidRepeatInterval))
    }

    func testRepeatEndDateBeforeEventIsInvalid() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let rule = RepeatRule(
            frequency: .weekly,
            interval: 1,
            endDate: date.addingTimeInterval(-86_400)
        )
        let issues = service.validate(validEvent(date: date, repeatRule: rule))
        XCTAssertTrue(issues.contains(.invalidRepeatEndDate))
    }

    func testValidEventHasNoIssues() {
        XCTAssertTrue(service.isValid(validEvent()))
        XCTAssertTrue(service.validate(validEvent()).isEmpty)
    }
}
