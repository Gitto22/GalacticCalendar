# Sprint PB-05 — Architecture Cleanup

**Fecha:** 2026-07-30  
**Objetivo:** Reducir deuda técnica (muerto / duplicados / deps innecesarias) sin cambiar funcionalidad ni UX.

---

## Repeat vs Recurrence — decisión

**Se mantienen ambos stacks** (no es duplicación accidental):

| Stack | Rol |
|-------|-----|
| `RepeatRule` / `RepeatFrequency` | Persistencia SwiftData / CloudKit (`none`, `daily`, …) |
| `RecurrenceRule` / `RecurrenceEngine` | Expansión en memoria (`never` ≠ `none`) |
| `RepeatRule.asRecurrenceRule` | Único puente Domain → engine |
| `RecurrenceEndKind` | Solo Presentation (editor) |

Unificar tipos rompería tokens persistidos — **fuera de alcance**.

---

## Deuda técnica eliminada

### Repeat / Recurrence
| Eliminado | Dónde |
|-----------|--------|
| Presets muertos `RecurrenceRule.never/daily/…` | `RecurrenceRule.swift` |
| `fetchRecurring()` (0 call sites) | Protocolo + repos + stubs/tests/previews |
| `recurringEvents()` | `EventCatalogService`, `EventPersistenceService` |
| `events(in:)` sin callers | `EventCatalogService` |
| Wrappers `CalendarEngine.occurrences` / `eventOccurs(_:on:)` | `CalendarEngine.swift` (+ test → `RecurrenceEngine`) |
| Doc explícita dual-stack | `RepeatRule.swift` |

### ThemeManager
| Eliminado |
|-----------|
| `currentMonthNumber` (alias de `currentMonth()`) |
| `currentBackgroundAsset` / `currentMonthBackgroundName` / `monthBackgroundName` |
| `monthBackgroundImage` / `activeMonthBackgroundImage` |
| `useSystemAppearance` / `useLightAppearance` / `useDarkAppearance` |

API viva: `backgroundAssetName(for:)`, `activeMonthBackgroundName`, `activeMonthContrastProfile`, `prepareDisplayedMonth`, display helpers.

### EventPersistenceService
| Eliminado |
|-----------|
| `recurringEvents()` |

`bootstrap()` se **conserva** como alias de `refresh()` (mismos call sites; semántica “carga inicial”).

### DependencyContainer / ViewModelFactory
| Eliminado / ajustado |
|----------------------|
| `notificationService` → `private` (solo inyección interna) |
| Factories sin uso: SmartAgenda, EventEditor, DayEvents, Templates, TemplatePicker, UniverseHistory/Detail públicos |

Se mantienen: `makeHomeViewModel`, `makeUniverseMessageViewModel`, `makeCalendarGridViewModel`.

---

## Deuda que permanece (consciente)

| Ítem | Motivo |
|------|--------|
| Dual `Repeat*` / `Recurrence*` | Persistencia vs engine; tokens CloudKit |
| `RecurrenceEndKind` en Presentation | UI end-mode ≠ Domain `RecurrenceEndRule` |
| Theme packs (`ThemePack`, `selectThemePack`, flag `additionalThemes`) | Scaffolding futuro; flag cableado, sin UI |
| `ThemeManager` multi-rol (mes/fondo/appearance/packs) | Split SRP = refactor, no cleanup seguro |
| `EventPersistenceService` multi-rol (CRUD + validación + reminders + catálogo) | Split cambia DI; fuera de sprint |
| `bootstrap()` ≡ `refresh()` | Alias deliberado; unificar call sites = churn sin ganancia UX |
| Reserved `byWeekdays` / `excludedDates` / `customPayload` | Extension points documentados, aún no aplicados |
| `EventPersistenceError.templatesLoadFailed` en servicio de eventos | Usado por Home para templates; relocating = rename |

---

## UX / funcionalidad

Sin cambios de comportamiento ni de experiencia de usuario.

---

PB-05 Architecture Cleanup: **cerrado**.
