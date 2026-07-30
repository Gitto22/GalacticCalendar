# Sprint QA-06 — Navigation Certification

**Fecha:** 2026-07-30  
**Rol:** Principal iOS Architect (SwiftUI Navigation)  
**Restricciones:** Sin features nuevas · sin cambio de UX/diseño/negocio.

---

## Análisis

### Qué existe

| Pieza | Uso real (Private Beta) |
|-------|-------------------------|
| `NavigationStack` (RootView) | Shell host de `HomeView` |
| `NavigationPath` + `NavigationManager` | **Reservado** — path siempre vacío; nadie hace `push` desde features |
| `AppRouter` / `Route` | **Reservado** — solo `.root`; nunca consumido por Presentation |
| `NavigationSplitView` | No existe |
| `NavigationLink` | No existe |
| Settings | No existe |
| `fullScreenCover` + `isPresenting*` | **Patrón de producto** (Home, DayEvents, Agenda, Universe, Templates, Editor) |
| `sheet` | Quick schedule (+ `NavigationStack` local de chrome) |
| `popover` | No existe |

### Hallazgo crítico

Había **dos sistemas aparentes**:

1. Shell push (`Route` / `AppRouter` / path) — scaffolding muerto para beta.  
2. Modales booleanas por pantalla — navegación real.

El `navigationDestination(for: Route.self)` en `RootView` era un **destino huérfano** (solo `.root`, nunca pusheado).

---

## Patrón de navegación certificado

```
RootView
  └─ NavigationStack (shell host only)
       └─ HomeView
            ├─ fullScreenCover × N  ← product navigation
            └─ child screens
                 ├─ fullScreenCover (editor / templates / …)
                 └─ sheet (quick schedule → local NavigationStack)
```

**Único patrón de producto:** ViewModel owns `isPresenting*` + `present*`/`dismiss*` + SwiftUI modal modifiers.

**Push stack:** reserved infrastructure for future deep links / Settings — not a parallel product router.

---

## Refactor realizado (solo navegación, sin UX)

| Cambio | Motivo |
|--------|--------|
| `RootView` sin `path` binding ni `navigationDestination` | Elimina destino huérfano; shell host limpio |
| Docs en `Route` / `NavigationManager` / `AppRouter` | Clarifica reserved vs product |
| `AppEnvironmentKeys` + `CalendarAppearanceManager` | Documentación alineada |

DI sigue inyectando NavigationManager/AppRouter (reserva futura). No se eliminan tipos.

**UI Tests:** no afectados (no usan `NavigationPath`).

---

## Componentes eliminados

- Destino push huérfano `Route.root` en `RootView.navigationDestination`
- Acoplamiento de `RootView` a `NavigationManager` (ya no lee el path)

## Componentes reutilizados

- `fullScreenCover` / `sheet` + flags en Home / DayEvents / SmartAgenda / Universe History / Templates / EventEditor
- `NavigationStack` local en `EventQuickScheduleSheet` (chrome de sheet)
- Shell `NavigationStack` como host

## Riesgos eliminados

| Riesgo | Mitigación |
|--------|------------|
| Doble patrón confuso (push vs modal) | Certificado: modal = producto; push = reserved |
| Destino inaccesible / ruta huérfana | Eliminado `navigationDestination` muerto |
| Navegación paralela innecesaria | No hay segundo router activo en features |
| Coordinadores innecesarios en producto | `AppRouter` no llamado por features |

Boolean flags de presentación: **intencionales** para modales de una sola pantalla (QA-04). No se migran a `Route` (sería cambio arquitectónico + riesgo UX).

---

## Certificación Navigation

| Check | Estado |
|-------|--------|
| Único patrón de producto | **Sí** — modal VM-owned |
| Sin navegación duplicada activa | **Sí** |
| Sin rutas huérfanas activas | **Sí** |
| Sin destinos inaccesibles | **Sí** |
| Sin NavigationSplitView / Link / popover / Settings | N/A |
| fullScreenCover / sheet / dismiss coherentes | **Sí** |

### Veredicto

**CERTIFICADO** para Private Beta.

Push infrastructure permanece en Composition Root como reserva documentada, no como segundo camino de producto.
