# Sprint P0.1 — Real Assets

**Fecha:** 2026-07-30  
**Objetivo:** Eliminar el bloqueo P0 “Assets de meses vacíos”  
**Alcance:** Cablear las 12 imágenes aprobadas ya presentes en disco al Asset Catalog  
**Sin cambios:** Diseño · Arquitectura · Navegación · `MonthBackgroundView` / `ThemeManager` / `ColorPalette`

---

## Análisis previo

| Pieza | Hallazgo |
|-------|----------|
| `Assets/Months/*.imageset/*.png` | **Ya existían** las 12 PNG aprobadas (~26 MB) y estaban en git |
| `Contents.json` | **No referenciaban** `filename` → el catalog las trataba como vacías |
| `MonthBackgroundView` | `Image` + `resizable` + `scaledToFill` + `clipped` + crossfade — correcto |
| `ThemeManager` / `MonthBackgroundAsset` | Nombres `January`…`December` alineados con imagesets |
| `ColorPalette.overlay` | Definido pero no aplicado (queda para **P0.2** contraste) |
| Lazy loading | Solo el mes activo se resuelve; no se precargan los 12 |

---

## Implementación

### Cambios realizados
1. Actualizar los 12 `Contents.json` para enlazar `{Month}.png` en slot **universal 2x**.
2. `template-rendering-intent: original` (no se tiñen como template).
3. `compression-type: automatic` (compresión del catalog en build).
4. README de cada imageset actualizado (ya no piden “place asset”).

### No modificado
- `MonthBackgroundView.swift`
- `ThemeManager.swift`
- `ColorPalette.swift`
- Navegación / layout / UX

---

## Archivos modificados

```
Assets/Assets.xcassets/Months/January.imageset/Contents.json
Assets/Assets.xcassets/Months/January.imageset/README.md
Assets/Assets.xcassets/Months/February.imageset/Contents.json
Assets/Assets.xcassets/Months/February.imageset/README.md
Assets/Assets.xcassets/Months/March.imageset/Contents.json
Assets/Assets.xcassets/Months/March.imageset/README.md
Assets/Assets.xcassets/Months/April.imageset/Contents.json
Assets/Assets.xcassets/Months/April.imageset/README.md
Assets/Assets.xcassets/Months/May.imageset/Contents.json
Assets/Assets.xcassets/Months/May.imageset/README.md
Assets/Assets.xcassets/Months/June.imageset/Contents.json
Assets/Assets.xcassets/Months/June.imageset/README.md
Assets/Assets.xcassets/Months/July.imageset/Contents.json
Assets/Assets.xcassets/Months/July.imageset/README.md
Assets/Assets.xcassets/Months/August.imageset/Contents.json
Assets/Assets.xcassets/Months/August.imageset/README.md
Assets/Assets.xcassets/Months/September.imageset/Contents.json
Assets/Assets.xcassets/Months/September.imageset/README.md
Assets/Assets.xcassets/Months/October.imageset/Contents.json
Assets/Assets.xcassets/Months/October.imageset/README.md
Assets/Assets.xcassets/Months/November.imageset/Contents.json
Assets/Assets.xcassets/Months/November.imageset/README.md
Assets/Assets.xcassets/Months/December.imageset/Contents.json
Assets/Assets.xcassets/Months/December.imageset/README.md
```

PNG: sin cambios de píxeles (ya versionadas).

---

## Resolución / escalado / memoria

| Mes | Resolución | On-disk | RGBA decodificado (est.) |
|-----|------------|---------|---------------------------|
| January–May | 1024×1536 | ~1.9–2.5 MB | ~6.0 MB |
| June–July | 1023×1537 | ~2.4–2.7 MB | ~6.0 MB |
| August–October | 941×1672 | ~1.5–2.2 MB | ~6.0 MB |
| November | 957×1644 | ~2.1 MB | ~6.0 MB |
| December | 925×1700 | ~2.1 MB | ~6.0 MB |
| **Total disco** | | **≈ 25.8 MB** | |
| **Pico runtime** | 1 mes activo (+1 breve en crossfade) | | **≈ 6–12 MB** |

### Escalado / dispositivos
- `scaledToFill` + `clipped` + `GeometryReader` → llena cualquier tamaño sin distorsión (crop, no stretch).
- Slot catalog **2x** único: densidades 1x/3x las escala el runtime (aceptable a esta resolución base).
- Orientación portrait; en landscape habrá crop lateral (comportamiento ya previsto por el diseño).

### Dark Mode
- Imágenes cósmicas oscuras; UI `onImagePrimary` blanca — coherente en Light/Dark.
- Sin variantes `Appearances` separadas (no requeridas; no se cambia el diseño).

### Lazy loading / rendimiento
- Carga bajo demanda vía `Image(assetName)`.
- Cambio de mes: `.id(assetName)` + `Motion.calendarBackground` (respeta Reduce Motion).
- No hay precarga de los 12 meses.

---

## Problemas detectados (no bloquean P0.1)

| Problema | Severidad | Notas |
|----------|-----------|-------|
| Resoluciones no uniformes entre meses | Baja | `scaledToFill` lo absorbe |
| Sin @3x nativo (~1242–1290 de ancho) | Baja | En Pro Max puede verse ligeramente soft; no bloquea beta |
| `ColorPalette.overlay` no aplicado | **P0.2** | Contraste sobre zonas brillantes (Vía Láctea, planetas) |
| Bundle +26 MB | Info | Normal para 12 full-bleed; comprimir HEIC/JPEG sería sprint aparte |

---

## Verificación recomendada (manual)

1. Arrancar Home → fondo del mes actual visible.  
2. Swipe / chevron mes a mes → 12 fondos distintos, crossfade.  
3. Abrir Day Events / Editor / Search / Agenda / Universe → mismo fondo.  
4. iPhone SE + Pro Max + iPad (si aplica) → sin letterboxing raro, sin stretch.  
5. Light + Dark appearance → legibilidad básica (detalle contraste = P0.2).

---

## Preparación para Sprint P0.2

**P0.2 esperado (auditoría):** contraste / Dynamic Type / scrim.

Con fondos reales activos, P0.2 puede:

1. Aplicar `ColorPalette.overlay` (o equivalente) bajo chrome on-image **sin** rediseñar layout.  
2. Validar contraste texto blanco vs zonas claras de cada mes (sobre todo Jul–Sep galaxia).  
3. No tocar assets de mes salvo que un mes concreto falle WCAG tras el scrim.

**P0.1 cerrado:** el bloqueo “Assets de meses vacíos” queda resuelto.
