//
//  SmokeAccessibilityID.swift
//  GalacticCalendarUITests
//
//  Stable accessibility identifiers used by QA-01 smoke UI tests.
//  Must stay in sync with Presentation identifiers.
//

import Foundation

enum SmokeAccessibilityID {

    // MARK: - Home / Launch

    static let homeScreen = "home_screen"
    static let homeMenu = "home_menu"
    static let homeMenuAgenda = "home_menu_agenda"
    static let homeToday = "home_today"
    static let homeMonthTitle = "home_month_title"
    static let homeYearTitle = "home_year_title"
    static let homeMonthPrevious = "home_month_previous"
    static let homeMonthNext = "home_month_next"

    // MARK: - Calendar

    static let calendarGrid = "calendar_grid"
    static let calendarDayToday = "calendar_day_today"
    static let calendarWeekHeader = "calendar_week_header"

    // MARK: - Day Events

    static let dayEventsScreen = "day_events_screen"
    static let dayEventsTitle = "day_events_title"
    static let dayEventsNewEvent = "day_events_new_event"
    static let dayEventsClose = "day_events_close"
    static let eventRowPrefix = "event_row_"

    // MARK: - Event Editor

    static let eventEditor = "event_editor"
    static let eventEditorTitle = "event_editor_title"
    static let eventEditorConfirm = "event_editor_confirm"
    static let eventEditorClose = "event_editor_close"
    static let eventEditorDelete = "event_editor_delete"
    static let eventEditorDeleteConfirm = "event_editor_delete_confirm"

    // MARK: - Smart Agenda

    static let smartAgendaScreen = "smart_agenda_screen"
    static let agendaSummaryHeader = "agenda_summary_header"
    static let agendaAddEvent = "agenda_add_event"
    static let agendaClose = "agenda_close"

    // MARK: - Universe

    static let universeMessageCard = "universe_message_card"
}
