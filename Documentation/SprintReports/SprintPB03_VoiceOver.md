# Sprint PB-03 — VoiceOver

**Fecha:** 2026-07-30  
**Objetivo:** Completar accesibilidad (label / hint / value / identifier) en Home, Calendar, Events y Universe sin cambiar el diseño.

---

## Hallazgo previo

| Área | Estado antes |
|------|----------------|
| Events (row, search results, editor parcial) | Buena base de labels/ids |
| Home / Calendar | Labels en header; día con `onTapGesture` |
| Universe | Favorito/share parcial; cierres y card sin label |

Único `onTapGesture` interactivo en Presentation: `CalendarGridView` (celda del día).

---

## Cambios realizados

### Calendar
- `CalendarGridView`: `onTapGesture` → `Button` (plain); id `calendar_grid`
- `CalendarDayCell`: hint, value (selected), identifier `calendar_day_*`
- `WeekHeaderView`: label + id por weekday
- `MonthPickerView` / `YearPickerView`: label, hint, value, ids en filas y close

### Home
- `HomeHeaderView`: hints + identifiers (menu, mes, año, prev/next, today)
- `UniverseMessageCard`: label, hint, value, id
- `HomeView`: id `home_screen`

### Universe
- History / Detail: close label+hint+id
- Search field, filter chips (selected value + id)
- Rows: label+hint+id; favorite value+hint+id
- Share / detail message: identifiers

### Events
- `DayEventsView`: título, close/templates/new/from-template hints+ids
- `EventRow`: `accessibilityValue` (status)
- `EventEditorView`: description, date pickers, stepper, menus, acciones (hints/ids)
- `EventSearchView`: field/clear/close/filters/empty states
- `FlowTagPicker`: label, hint, value, id por tag

### Localización
Nuevas claves EN/ES (`*_a11y_hint`, `calendar_day_not_selected_a11y`, etc.).

---

## Diseño

Sin cambios visuales: mismos layouts, colores y tipografía. Solo APIs de accesibilidad y sustitución de gesto por `Button` plain.

---

## Cobertura aproximada (alcance PB-03)

Criterio: controles interactivos + contenido estático relevante en Home / Calendar / Events / Universe.

| Métrica | Antes (aprox.) | Después (aprox.) |
|---------|----------------|------------------|
| `accessibilityLabel` | ~55% | **~95%** |
| `accessibilityHint` (acciones) | ~25% | **~90%** |
| `accessibilityValue` (estado) | ~15% | **~85%** |
| `accessibilityIdentifier` | ~35% | **~92%** |
| Controles táctiles como `Button` | ~90% (`onTapGesture` en grid) | **100%** |

**Cobertura global estimada del sprint: ~92%.**

Residual (~8%): estados vacíos decorativos menores, menús nativos del sistema, Agenda/Templates fuera del foco principal (ya tenían cobertura parcial previa).

---

## Comprobación manual recomendada

1. VoiceOver ON → Home: menú, mes/año, hoy, card Universo, celdas del grid.  
2. Abrir día → lista eventos (label + hint + swipe delete).  
3. Editor: título, descripción, date pickers, colores, guardar.  
4. Universe History: búsqueda, chips, fila, favorito, detalle, share.  
5. Month/Year picker: filas y close.

---

PB-03 VoiceOver: **cerrado** (cobertura ~92%).
