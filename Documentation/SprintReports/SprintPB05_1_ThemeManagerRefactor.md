# Sprint PB-05.1 — ThemeManager SRP

**Fecha:** 2026-07-30  
**Rol:** Principal iOS Architect  
**Estado:** Implementado (sin cambio de comportamiento / UI / navegación).

---

## 1. Análisis previo — responsabilidades originales de `ThemeManager`

| # | Responsabilidad | Clasificación |
|---|-----------------|---------------|
| 1 | `preferredColorScheme` (light / dark / system) | **Theming** |
| 2 | Theme packs (`ThemePack`, `selectThemePack`, flag `additionalThemes`) | **Theming** |
| 3 | Autoridad conceptual sobre tokens DS (`ColorPalette`, `Typography`, `Spacing`, `Shadows`, `GlassEffect`) — ya estáticos, no estado de la clase | **Theming** |
| 4 | `displayedMonthOverride` / `displayedYearOverride` / `activeMonthNumber` / `activeYear` | **Estado del calendario** |
| 5 | `prepareDisplayedMonth`, títulos localizados (`displayedMonthName` / `displayedYearText`) | **Estado del calendario** |
| 6 | `MonthBackgroundAsset`, `backgroundAssetName`, `activeMonthBackgroundName` | **Recursos visuales** |
| 7 | `activeMonthContrastProfile` (scrim/gradiente por mes) | **Recursos visuales** |
| 8 | Formatters de mes/año (`DateFormatter`) | **Utilidades** |
| 9 | `currentMonth()` / `currentYear()` vía `Calendar.current` | **Utilidades** (al servicio del estado de calendario) |

**Diagnóstico:** `ThemeManager` mezclaba theming con estado de calendario y recursos de fondo → incumplía SRP.

---

## 2. Implementación

| Destino | Qué conserva / recibe |
|---------|----------------------|
| **`ThemeManager`** | Solo theming runtime: color scheme + packs. Gobierna (sin poseer instancia de) colores, tipografía, espaciados, sombras, glass. |
| **`CalendarAppearanceManager`** | Mes/año visible, títulos, assets de fondo, contraste. |
| **`MonthBackgroundAsset`** | Enum de imágenes mensuales (extraído). |
| **`MonthBackgroundView` + `Motion`** | Transición/crossfade entre fondos (sin cambio). |

DI: `DependencyContainer` + `GalacticCalendarApp` inyectan ambos (imprescindible).

---

## 3. Responsabilidades finales

### `ThemeManager`
- Light / dark / system  
- Theme packs  
- Autoridad de theming sobre `ColorPalette` · `Typography` · `Spacing` · `Shadows` · `GlassEffect`

### `CalendarAppearanceManager`
- Mes/año activo  
- Fondo mensual + contraste  
- Títulos localizados para Home chrome  
- Utilidades de formateo asociadas

---

## 4. Archivos modificados / creados

| Archivo | Acción |
|---------|--------|
| `Application/DesignSystem/ThemeManager.swift` | Reducido a theming |
| `Application/DesignSystem/CalendarAppearanceManager.swift` | **Nuevo** |
| `Application/DesignSystem/MonthBackgroundAsset.swift` | **Nuevo** (enum extraído) |
| `App/CompositionRoot/DependencyContainer.swift` | + `calendarAppearanceManager` |
| `App/GalacticCalendarApp.swift` | Environment dual |
| `Presentation/.../HomeView`, `HomeHeaderView`, `MonthBackgroundView`, `HomeViewModel` | Consumen `CalendarAppearanceManager` |
| Previews Home/Calendar/Events/Universe | Environment dual |
| `Tests/.../ThemeManagerTests.swift` | **Nuevo** |
| `Tests/.../CalendarAppearanceManagerTests.swift` | **Nuevo** |
| Tests de calendario / contraste | Migrados al nuevo manager |

---

## 5. ¿`ThemeManager` cumple SRP?

**Sí.**

Una sola razón de cambio: **theming** (esquema de color + packs + autoridad sobre tokens DS).  
Estado de calendario y recursos mensuales están fuera.

Nota arquitectónica: colores/tipografía/espaciados/sombras/glass **no** eran propiedades mutables de `ThemeManager` antes ni ahora; son superficies estáticas del Design System. Conservarlas “bajo ThemeManager” significa autoridad de theming, no ownership de estado.

---

## 6. Restricciones

Comportamiento · UI · navegación: **sin cambios intencionados.**
