# Sprint 6.10 — Production Hardening

**Fecha:** 2026-07-30  
**Alcance:** Cierre de producción del módulo Advanced Events (sin nuevas features)  
**UX / navegación / diseño:** sin cambios intencionados

---

## Veredicto

### ✅ MÓDULO ADVANCED EVENTS CERRADO

---

## 1. Arquitectura

| Cambio | Detalle |
|--------|---------|
| Domain → Config | Eliminada. `AgendaTimelineBuilder.Defaults` vive en Domain; `CalendarConstants` solo reexporta aliases de Presentation |
| Dualidad Repeat / Recurrence | Corregido `asRecurrenceRule` (propiedad). Eliminados `RecurrenceRule.editorSelectableRules` y `RepeatRule.init(recurrence:)` muertos. Bridge único: `RepeatRule.asRecurrenceRule` |
| Persistence façade | **No partido** — orquestación coherente (validate → write → reminder → refresh + quick ops). Cumple SRP como Application façade |
| Master resolve Home | Misma política que Day Events / Agenda al editar 1 evento desde el grid |

---

## 2. Calidad del código

- Extraído `EventColorTitleRow` (Search + Agenda) sin alterar chrome externo.
- Eliminados scaffolds muertos `MainCalendarView` / `MainCalendarViewModel` y caso `withGift`.
- Documentado SSOT de lectura = catálogo; Agenda no aplica filtros de búsqueda (excepción de producto documentada).

---

## 3. Seguridad / integridad

- Codecs `RepeatRule` / `EventTagCodec` **lanzan** ante corrupción (sin inventar `.none` / `[]`).
- Mappers rechazan enums desconocidos → `corruptData` / `dataCorruption` vía `lastError` + alertas existentes.
- Rollbacks de create/update **estrictos** (store + reminder + catalog); fallo → `rollbackFailed` visible.
- Bootstrap de plantillas ya no usa `try?`; error → `templatesLoadFailed` en Home.
- Quick schedule resetea `isSaving` con `defer` tras éxito o fallo.

---

## 4. Accesibilidad

- `EventEditorView` envuelto en `ScrollView` (Dynamic Type / pantallas pequeñas).
- Labels localizados de color (editor + search); hints en Search/Agenda/rows.
- `accessibilityIdentifier` en editor, filas, búsqueda, agenda, quick schedule.

---

## 5. Testing

Añadidos / actualizados:

- `HomeViewModelDayRoutingTests` — routing 0/1/2+ eventos, outside-month, master resolve en recurrencia.
- `RepeatRuleTests` — throws en decode corrupto; bridge `asRecurrenceRule`.
- Mapper / organization / recurrence tests adaptados a codecs throwing.

---

## 6. Rendimiento

Sin cambios estructurales. Observation + catálogo in-memory siguen siendo adecuados a escala personal. No se aplicaron micro-optimizaciones innecesarias.

---

## 7. Documentación

- `DataModel.md` — corregidos § multi-day / recurrence / search / agenda / 6.10.
- `Roadmap.md` — 6.9 review + 6.10 shipped.
- Este informe.

---

## 8. Cobertura (Events)

Dominio / Application / routing Home cubiertos para los caminos críticos de producción. Gaps conscientes no bloqueantes: UI snapshot, Search `onSelectEvent` (no cableado a propósito — no se cambia navegación en este sprint).

---

## 9. Riesgos residuales (no bloqueantes)

| Riesgo | Mitigación / nota |
|--------|-------------------|
| `@Attribute(.unique)` + CloudKit futuro | Fuera de alcance; documentado |
| Repo `fetch(on/in:)` start-only | No usado por UI; documentado |
| Agenda vs search filters | Excepción documentada |
| Search tap sin callback | Sin cambio de UX en 6.10 |

---

## 10. Nota del módulo

Advanced Events queda listo para producción **offline local**: all-day, multi-día, recurrencia, organización, plantillas, ops rápidas, búsqueda, agenda, con arquitectura Clean + MVVM + Observation endurecida.

---

## Respuesta única

### ✅ MÓDULO ADVANCED EVENTS CERRADO
