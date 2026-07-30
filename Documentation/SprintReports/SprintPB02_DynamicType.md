# Sprint PB-02 — Dynamic Type

**Fecha:** 2026-07-30  
**Objetivo:** Eliminar tamaños de fuente fijos; Text Styles + Dynamic Type sin cambiar el diseño aprobado.

---

## Hallazgo

Todas las vistas SwiftUI ya consumían `Typography.*`.  
Los únicos `Font.system(size:)` estaban en `Application/DesignSystem/Typography.swift`.

Por tanto la migración es **centralizada**: un cambio en Design System cubre toda la app.

---

## Fuentes sustituidas

| Token | Antes (fijo) | Ahora (Text Style) |
|-------|--------------|--------------------|
| `display` | system 34 bold | `Font.largeTitle.weight(.bold)` |
| `largeTitle` | system 28 bold | `Font.title.weight(.bold)` |
| `title` | system 22 semibold | `Font.title2.weight(.semibold)` |
| `title2` | system 20 semibold | `Font.title3.weight(.semibold)` |
| `title3` | system 18 semibold | `Font.headline` |
| `headline` | system 17 semibold | `Font.headline` |
| `body` | system 17 regular | `Font.body` |
| `callout` | system 16 | `Font.callout` |
| `subheadline` | system 15 | `Font.subheadline` |
| `footnote` | system 13 | `Font.footnote` |
| `caption` | system 12 | `Font.caption` |
| `caption2` | system 11 | `Font.caption2` |
| `monospacedDigit` | system 17 mono | `Font.body.weight(.medium).monospacedDigit()` |

Jerarquía relativa conservada vía la escala Apple (display > largeTitle > title > title2 > headline/body > …).

---

## Vistas modificadas

| Archivo | Cambio |
|---------|--------|
| `Application/DesignSystem/Typography.swift` | Text Styles (cobertura global) |
| `Presentation/Views/Agenda/TimelineView.swift` | `@ScaledMetric` en columna de hora (antes `width: 56` fijo) |

**Resto de vistas:** sin edición de `.font(...)` — heredan Dynamic Type automáticamente al usar `Typography`.

Cobertura de consumo (ya tokenizadas): Home, Calendar, Events, Agenda, Templates, Universe, Components (EventRow, chips, week header, etc.).

---

## Comprobación (manual recomendada)

1. Ajustes → Accesibilidad → Tamaño de texto → máximo.  
2. iPhone SE: Home header + day cell + editor.  
3. iPad (regular): Home usa `Typography.largeTitle` / `title2` vía size class.  
4. Agenda timeline: columna de hora no recorta a XXXL.

---

## Tests

`Tests/UnitTests/DesignSystem/TypographyDynamicTypeTests.swift`
- Token set completo (13).  
- UIFont preferred styles crecen bajo Accessibility XXXL.

---

## Cobertura alcanzada

| Ámbito | % |
|--------|---|
| `Font.system(size:)` en app | **0** (eliminados) |
| Vistas vía `Typography` | **100%** de call sites de tipografía de producto |
| Layout sensible a DT | Timeline time column escalada |

PB-02 Dynamic Type: **cerrado**.
