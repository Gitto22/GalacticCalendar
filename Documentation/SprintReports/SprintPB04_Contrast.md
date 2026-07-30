# Sprint PB-04 — Contrast

**Fecha:** 2026-07-30  
**Objetivo:** Garantizar contraste suficiente sobre fondos mensuales con scrim/gradiente dinámico, sin alterar el diseño aprobado.

---

## Hallazgo

- `ColorPalette.overlay` (negro 28%) existía pero **no se aplicaba**.
- Textos/iconos on-image (`onImagePrimary` / accent) y chrome de Header / week labels se dibujan sobre la foto a pantalla completa.
- Medición de luminancia (p99) de los PNG de mes:
  - Picos altos en **Jan, Mar, Jun, Aug, Oct, Dec** (y Julio elevado).
  - **Feb, Sep, Nov** más oscuros → tratamiento ligero.

Las superficies aprobadas (glass cards, day cells) ya aportan fill oscuro; el gap era el fondo bajo Header / calendario / Universe.

---

## Enfoque (centralizado)

Un único punto de aplicación: **`MonthBackgroundView`**.  
Header, Calendar, tarjetas y Universe **heredan** el contraste porque todas montan ese fondo. Sin cambios de layout ni de tipografía/colores de chrome.

| Perfil | Meses | Scrim base | Gradiente |
|--------|-------|------------|-----------|
| `standard` | Feb, Sep, Nov | 0.28 | top suave + mid leve |
| `elevated` | Apr, May, Jul | 0.40 | top/mid medios |
| `strong` | Jan, Mar, Jun, Aug, Oct, Dec | 0.52 | top/mid más densos |

Apilado: **imagen → scrim uniforme → gradiente vertical** (header → banda de calendario → fondo).

---

## Componentes adaptados

| Componente | Cambio |
|------------|--------|
| `Application/DesignSystem/MonthContrastProfile.swift` | **Nuevo** — perfiles + mapping por `MonthBackgroundAsset` |
| `Application/DesignSystem/ColorPalette.swift` | `overlay(for:)`, `readabilityGradient(for:)`; `overlay` alineado a `standard` |
| `Application/DesignSystem/ThemeManager.swift` | `activeMonthContrastProfile` |
| `Presentation/Views/Home/MonthBackgroundView.swift` | Aplica scrim + gradiente dinámicos |

### Cubiertos por herencia (sin editar vistas)

| Zona | Cómo se beneficia |
|------|-------------------|
| **Header** | Gradiente superior + scrim bajo `HomeHeaderView` |
| **Calendario** | Scrim/mid-gradiente bajo `WeekHeaderView` / `CalendarGridView` / day cells |
| **Tarjetas** | Mismo fondo bajo glass (`UniverseMessageCard`, EventRow, editor tiles) |
| **Universe** | History / Detail / share usan `MonthBackgroundView` |

No se modificaron opacidades de `cardFill`, `dayCellFill`, ni colores on-image (estética aprobada intacta).

---

## Tests

`Tests/UnitTests/DesignSystem/MonthContrastProfileTests.swift`
- Mapping mes → perfil  
- Intensidades monótonas (standard < elevated < strong)  
- `ThemeManager.activeMonthContrastProfile`

---

## Comprobación manual

1. Recorrer Jan→Dec con VoiceOver off; verificar mes/año y celdas legibles.  
2. Especial atención: **March, October, June** (picos altos).  
3. Abrir Universe History + card Home sobre esos meses.  
4. Reduce Motion: crossfade de fondo sigue respetándose.

---

PB-04 Contrast: **cerrado** (scrim dinámico centralizado en `MonthBackgroundView`).
