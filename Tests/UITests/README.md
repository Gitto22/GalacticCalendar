# QA-01 — UI Smoke Tests

Suite mínima XCUITest de flujos críticos (Private Beta).

## Target Xcode

1. File → New → Target → **UI Testing Bundle** → `GalacticCalendarUITests`
2. Host Application = Galactic Calendar
3. Add sources:
   - `Tests/UITests/Support/*.swift`
   - `Tests/UITests/Calendar/*.swift`
   - `Tests/UITests/Events/*.swift`
   - `Tests/UITests/Universe/*.swift`
4. Run on iOS Simulator (launch args force `en`)

## Cases

| # | Flujo | Test |
|---|-------|------|
| 1 | Launch / Home | `LaunchSmokeUITests.testLaunchOpensHomeScreen` |
| 2 | Calendar | `CalendarSmokeUITests.testChangeMonthThenReturnToTodayAndSelectDay` |
| 3 | Day Events | `DayEventsSmokeUITests.testOpenDayEventsListAndClose` |
| 4 | Events CRUD | `EventCRUDSmokeUITests.testCreateEditDeleteEventOnToday` |
| 5 | Smart Agenda | `SmartAgendaSmokeUITests.testOpenSmartAgendaLoadsAndCloses` |
| 6 | Universe | `UniverseSmokeUITests.testDailyUniverseMessageAppearsOnHome` |

## Anti-fragilidad

- Accessibility IDs (no coordenadas)
- Locale `en` forzada
- Launch fresco por test
- Helpers toleran 0 / 1 / 2+ eventos en el día
- Sin `sleep` fijos
