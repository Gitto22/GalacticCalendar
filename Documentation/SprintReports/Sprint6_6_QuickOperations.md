# Sprint 6.6 — Operaciones rápidas

## Resumen

Operaciones rápidas sobre eventos reutilizando ``EventPersistenceService`` (sin servicios nuevos): duplicar, mover/reprogramar, copiar a otra fecha, con menú contextual en la lista del día.

## Archivos modificados

### Domain
- `Domain/Models/Events/Event.swift` — `duplicated(on:)` (status `.pending`, reminder relativo); `rescheduled(to:)`
- `Domain/Models/Events/EventSchedule.swift` — `start(onDay:…)`, `shiftedBounds(…)`

### Application
- `Application/Services/EventPersistenceService.swift` — `duplicate(_:onto:)`, `move(_:to:)`, `copy(_:to:)`, resolve master
- `Application/DesignSystem/Icons.swift` — `move`, `copy`

### Presentation
- `Presentation/ViewModels/Events/EventQuickDateOperation.swift` (**nuevo**)
- `Presentation/ViewModels/Events/DayEventsViewModel.swift` — sheet move/copy; duplicate onto day
- `Presentation/Views/Events/EventQuickScheduleSheet.swift` (**nuevo**)
- `Presentation/Views/Events/DayEventsView.swift` — sheet + wiring
- `Presentation/Components/Events/EventRow.swift` — menú Edit / Duplicate / Move / Copy / Delete

### Tests
- `Tests/UnitTests/Application/EventQuickOperationsTests.swift` (**nuevo**)

### Docs / i18n
- `Resources/Localization/{en,es}.lproj/Localizable.strings`
- `Documentation/DataModel.md`, `Architecture.md`, `Roadmap.md`, `README.md`
- Este informe

## Comportamiento

| Acción | Persistencia | Identidad | Estado | Recordatorio |
| --- | --- | --- | --- | --- |
| Duplicar (lista del día) | `duplicate(_:onto:)` → `create` | Nueva | `.pending` | Offset relativo |
| Mover / Reprogramar | `move(_:to:)` → `update` | Misma | Conservado | Offset relativo + sync |
| Copiar a otra fecha | `copy(_:to:)` → `create` | Nueva | `.pending` | Offset relativo |
| Eliminar | existente | — | — | cancel primero |

- Recurrencias: se resuelve el **master** antes de mutar; move desplaza la serie por delta de días respecto a la ocurrencia tocada.
- Multidía / todo el día: duración vía `shiftedBounds` + `normalizedBounds`.
- Notificaciones: pipeline existente create/update (sin romper atomicidad).

## Cobertura de tests

Suite `EventQuickOperationsTests`:

| Requisito | Tests |
| --- | --- |
| Duplicado | `testDuplicatedResetsStatusAndIdentity`, `testDuplicatedOntoDate…`, `testDuplicatePersists…`, `testDuplicateSchedulesReminder…` |
| Movimiento | `testRescheduledKeepsIdentity…`, `testMoveUpdatesSameIdentity`, `testMovePreservesMultiDayDuration`, `testMoveReschedulesReminder…` |
| Copiado | `testCopyCreatesIndependentEvent…`, `testCopySchedulesReminderIndependently` |
| Persistencia | create/update paths vía service + catalog count/id |
| Notificaciones | schedule en duplicate/move/copy |

## Calidad

- **SOLID / SRP:** lógica de schedule en Domain; writes + reminders en `EventPersistenceService`; UI solo presenta.
- **MVVM:** sheet + `DayEventsViewModel`; sin lógica de negocio en Views.
- **Sin duplicar:** un sheet + `EventQuickDateOperation`; no hay Application service nuevo.
- **A11y:** hint en `EventRow`; labels en menú/sheet.

## Riesgos

1. Move sobre serie recurrente desplaza el **master** (no hay edición de una sola ocurrencia todavía).
2. Reminder con offset no estándar cae al fallback de `EventReminderOption` (p. ej. 15 min).
3. Duplicate en el mismo día crea un segundo evento con la misma hora (intencional).

## Preparación para Sprint 6.7

Candidatos naturales (Roadmap):

- Filtros / búsqueda por etiqueta, prioridad y color.
- Edición de una sola ocurrencia vs serie completa.
- Undo rápido tras move/copy.
- Atajo plantilla → evento (si 6.7 amplía organización).
