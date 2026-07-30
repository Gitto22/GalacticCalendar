# Sprint QA-01 — UI Smoke Tests

**Fecha:** 2026-07-30  
**Rol:** Lead iOS QA Engineer  
**Objetivo:** Suite mínima de flujos críticos. Sin batería exhaustiva.

---

## Tests creados (6)

| # | Clase / método | Flujo |
|---|----------------|-------|
| 1 | `LaunchSmokeUITests.testLaunchOpensHomeScreen` | Launch → Home visible |
| 2 | `CalendarSmokeUITests.testChangeMonthThenReturnToTodayAndSelectDay` | Mes next/prev → Today → seleccionar día |
| 3 | `DayEventsSmokeUITests.testOpenDayEventsListAndClose` | Abrir día → lista con filas → cerrar |
| 4 | `EventCRUDSmokeUITests.testCreateEditDeleteEventOnToday` | Crear → editar → eliminar |
| 5 | `SmartAgendaSmokeUITests.testOpenSmartAgendaLoadsAndCloses` | Agenda carga summary → cerrar |
| 6 | `UniverseSmokeUITests.testDailyUniverseMessageAppearsOnHome` | Mensaje diario en Home |

Soporte: `SmokeUITestCase`, `SmokeAccessibilityID`.

---

## Cobertura funcional alcanzada

| Área | Cubierto | No cubierto (intencional) |
|------|----------|---------------------------|
| Launch / Home | Sí | — |
| Calendar nav + día | Sí | Swipe mes, pickers mes/año |
| Day Events | Sí | Swipe-delete, templates, quick ops |
| Events CRUD | Sí | Recurrence, multi-day, reminders UI |
| Smart Agenda | Sí | Timeline deep, free-time cards |
| Universe | Card Home | History / Detail / Favorite / Share |
| CloudKit / Widgets / Watch | — | Fuera de alcance |

---

## Identificadores añadidos (solo críticos)

| ID | Dónde |
|----|-------|
| `calendar_day_today` / `calendar_day_N` | `CalendarGridView` / `CalendarDayCell` |
| `home_menu_history` / `search` / `agenda` | `HomeHeaderView` Menu |
| `day_events_screen` | `DayEventsView` |
| `smart_agenda_screen`, `agenda_close`, `agenda_add_event` | `SmartAgendaView` |
| `agenda_summary_header` / `agenda_summary_end` | `AgendaSummaryCard` |
| `event_editor_delete_confirm` | `EventEditorView` |

Reutilizados: `home_screen`, `calendar_grid`, `home_today`, `home_month_*`, `event_editor*`, `universe_message_card`, `event_row_*`, …

---

## Riesgos detectados

| Riesgo | Mitigación / nota |
|--------|-------------------|
| Estado persistente entre tests (SwiftData) | Títulos UUID; helpers toleran 0/1/2+ eventos |
| Menu items sin exponer ID en algunos OS | Fallback label `"Daily Agenda"` (locale `en`) |
| Confirmación delete como sheet | ID + fallback `"Delete"` |
| Select All al editar título | Helper `replaceText` con fallback press |
| Target UI no está en git (`.xcodeproj` externo) | README de cableado obligatorio |
| Universe vacío si seed falla | Test exige card; valor/label no ambos vacíos |

---

## Preparación para QA-02

QA-02 (SwiftData Integration) ya cubre store/CRUD/templates/corrupción a nivel Data.

Para encadenar QA:

1. Cablear target UITests en Xcode y ejecutar smoke en Simulator.
2. Mantener IDs de esta suite estables (no renombrar sin actualizar `SmokeAccessibilityID`).
3. Integration tests no sustituyen UI smoke: UI valida wiring Presentation ↔ Application; Integration valida repositorio/catálogo.
4. Tras fallos de persistencia/corrupción (QA-02/03), re-ejecutar al menos Launch + Events CRUD + Day Events.

---

## Fuera de alcance

CloudKit · Widgets · Watch · rendimiento · snapshots visuales · Universe History/Detail.
