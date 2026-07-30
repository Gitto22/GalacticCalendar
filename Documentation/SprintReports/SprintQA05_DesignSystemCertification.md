# Sprint QA-05 — Design System Certification

**Fecha:** 2026-07-30  
**Rol:** Lead Design System Engineer  
**Restricciones:** Sin cambio de UX / arquitectura / aspecto visual aprobado.

---

## Auditoría — comprobaciones

| Regla | Resultado |
|-------|-----------|
| Colores vía `ColorPalette` | **Cumple** (Presentation). `Color.clear` solo estructural (listas / overlays). |
| Sin `Font.system` fuera de DS | **Cumple** — tipografía vía `Typography` (Dynamic Type). |
| Espaciados vía `Spacing` | **Cumple** tras mover literales mágicos. |
| Corner radius consistente | **Cumple** — `Spacing.Radius` (+ `none` / `xxs`). |
| Sombras vía `Shadows` | **Cumple**. |
| Motion / Animations | **Cumple** — calendar → `Motion`; editor feedback → `Animations`; duración mes unificada a `Animations.regularDuration`. |
| Icons / Glass / Buttons / Cards | **Certificados** — `Icons`, `GlassEffect`, `GlassCircleButton`, `galacticGlassCard`. |

### Componentes certificados

ColorPalette · Typography · Spacing (+ Radius) · Glass · Motion · Animations · Shadows · Icons · GlassCircleButton · Calendar (grid/cells/indicators/highlight) · Universe (card/row/chips) · Events (row/editor/search/tags) · Agenda (summary/timeline/free-time)

---

## Tokens reutilizados / añadidos

| Token | Valor | Uso |
|-------|-------|-----|
| `Spacing.hairline` | 1 | micro padding, bordes, dash stroke |
| `Spacing.accentBarWidth` | 3 | barra free-time |
| `Spacing.selectionStroke` | 2 | anillo color search |
| `Spacing.Radius.none` | 0 | glass circular |
| `Spacing.Radius.xxs` | 2 | barra accent |
| `ColorPalette.tagChipFillOpacity` | 0.20 | chips de tags |
| `ColorPalette.onImagePrimaryMutedOpacity` | 0.85 | share Universe |
| Indicator colors | aliases | `universeAccent` / `eventColor*` / `onImageAccent` |

Opacidades `0.35` / `0.45` reutilizan `glassStrokeSubtleOpacity` / `glassStrokeRegularOpacity`.

---

## Valores eliminados (literales en Presentation)

- `cornerRadius: 2|0` → `Spacing.Radius.xxs|none`
- `frame(width: 3)`, `padding 4|1`, `lineWidth: 1|2`, `dash: [4,4]`
- Opacidades mágicas `0.2|0.35|0.45|0.85` → tokens palette
- RGB duplicados de indicadores → aliases de tokens existentes
- `Motion.calendarMonthChange` duration `0.28` hardcoded → `Animations.regularDuration`
- `LayoutConstants.dayCellBorderStroke = 1` → `Spacing.hairline`

**Aspecto visual:** sin cambio intencionado (mismos números).

---

## Consistencia alcanzada

- Un solo vocabulario de spacing/radius/stroke en pantallas tocadas.
- Colores de evento/indicador/universe deduplicados.
- Separación clara Motion (calendario) vs Animations (feedback genérico) con timing compartido donde coinciden.
- `Color.clear` permitido como no-color de layout (no es brand).

**Tests:** no requieren actualización (sin cambio de comportamiento).

---

## Preparación para QA-06

Candidatos naturales:

1. Lint / regla CI: ban `Color(red:` y `Font.system` en `Presentation/`.
2. Snapshot o checklist visual smoke post-DS (opcional).
3. Documentar `LayoutConstants` como extensión de Spacing (no segunda escala).
4. Revisar opacidades restantes en Glass modifiers si aparecen literales nuevos.
