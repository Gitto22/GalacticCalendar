# Testing Guide

Suites presentes en `Tests/`. El `.xcodeproj` no está en este git tree: hay que añadir las fuentes a los targets de test en el workspace Xcode local.

## Mapa de suites

| Suite | Path | Propósito |
|-------|------|-----------|
| Unit | `Tests/UnitTests/` | Domain, Application, DesignSystem, Calendar, Universe, ViewModels |
| Integration | `Tests/IntegrationTests/Database/` | SwiftData real (in-memory / on-disk temp) |
| UI Smoke | `Tests/UITests/` | Flujos críticos Private Beta (XCUITest) |

Placeholders (sin tests): `IntegrationTests/{Backup,CloudKit,Notifications,StoreKit}`, `UnitTests/{Config,Intents,Managers}`.

## Unit Tests

Cobertura típica:

- Domain: schedule, multi-day, all-day, search criteria, organization, agenda builder, recurrence/repeat.
- Application: storage availability, persistence behaviors, catalog.
- Calendar: grid / pickers / Today / smart day / hardening.
- DesignSystem: ThemeManager, CalendarAppearance.
- Universe: engine / service / VMs.
- ViewModels: editor, home routing, events revision.

Patrón: dobles en memoria / repos fake; no dependen de UIKit XCUIApplication.

Ejecutar: scheme del Unit Test Bundle → ⌘U (o test concreto en el navigator).

## Integration Tests (SwiftData)

Ver `Tests/IntegrationTests/README.md` (QA-02) y resilience (QA-03).

| Área | Archivos |
|------|----------|
| Store open | `SwiftDataStoreOpenIntegrationTests` |
| CRUD eventos | `SwiftDataEventCRUDIntegrationTests` |
| Round-trip disco | `SwiftDataPersistenceRoundTripIntegrationTests` |
| Templates | `SwiftDataTemplateIntegrationTests` |
| Catálogo `refresh()` | `SwiftDataCatalogIntegrationTests` |
| Errores / unavailable | `SwiftDataErrorIntegrationTests` |
| Resilience | `ResilientEventCatalogIntegrationTests` |
| Harness | `SwiftDataIntegrationHarness` |

Aislamiento: nombre in-memory único o directorio temp on-disk; cleanup en `tearDown` / `defer`.

API canónica de servicios bajo test: `refresh()` (no asumir `bootstrap()` en Application services).

## UI Tests (Smoke)

Ver `Tests/UITests/README.md` (QA-01).

| Flujo | Clase |
|-------|-------|
| Launch / Home | `LaunchSmokeUITests` |
| Calendar | `CalendarSmokeUITests` |
| Day Events | `DayEventsSmokeUITests` |
| CRUD | `EventCRUDSmokeUITests` |
| Smart Agenda | `SmartAgendaSmokeUITests` |
| Universe | `UniverseSmokeUITests` |

Helpers: `SmokeUITestCase`, `SmokeAccessibilityID`. Locale forzada `en`. Sin sleeps fijos.

Target sugerido: UI Testing Bundle `GalacticCalendarUITests` con host = app.

## Cómo ejecutar la suite completa

1. Abrir el proyecto Xcode local.
2. Confirmar membership de:
   - `Tests/UnitTests/**/*.swift`
   - `Tests/IntegrationTests/Database/*.swift`
   - `Tests/UITests/**/*.swift` (target UI)
3. Unit + Integration: scheme de tests → **Test**.
4. UI: scheme UI Tests → simulador iOS → **Test**.
5. Opcional: SwiftLint CLI contra el árbol de fuentes (config `.swiftlint.yml`).

## Qué no cubrir aquí todavía

- CloudKit / Widgets / Watch / StoreKit (fuera de Private Beta).
- Snapshot / performance automatizados (no hay suite dedicada en el repo).
