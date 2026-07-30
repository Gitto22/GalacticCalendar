# Sprint QA-07 — Dependency Injection Certification

**Fecha:** 2026-07-30  
**Rol:** Principal iOS Architect  
**Restricciones:** Sin features nuevas · sin cambio de UX / navegación de producto / lógica de negocio · APIs públicas solo si imprescindible.

---

## Arquitectura DI certificada

### Composition Root

| Pieza | Veredicto |
|-------|-----------|
| `DependencyContainer` | **Único Composition Root** — creado una vez en `GalacticCalendarApp` |
| `ViewModelFactory` | Puerta de entrada para VMs de pantalla (`Home`, grid, Universe card) |
| `RootView` | Bootstrap: factory → VMs estables en `@State` |
| Environment | Contenedor + configuration + theme + calendar appearance + event/template façades |

```
GalacticCalendarApp
  └─ DependencyContainer (process-scoped)
        ├─ ModelContainer? / storageAvailability
        ├─ EventPersistenceService ← EventRepository + Catalog + Validation + NotificationService
        ├─ EventTemplateService ← EventTemplateRepository
        ├─ UniverseMessageRepository (protocol) + Engine + Service
        ├─ ThemeManager / CalendarAppearanceManager / AppConfiguration
        └─ NavigationManager / AppRouter (owned, not Environment-injected)
  └─ RootView
        └─ ViewModelFactory(container)
              ├─ HomeViewModel (+ child factories for Universe History/Detail)
              └─ CalendarGridViewModel
```

### Comprobaciones

| Criterio | Estado |
|----------|--------|
| Dependencias resueltas desde un único Composition Root | ✅ |
| Sin dependencias ocultas de Infrastructure en Views | ✅ (previews/tests excepted) |
| Singletons innecesarios | ✅ Solo `GalacticDefaultThemePack.shared` (pack inmutable) |
| Ciclo de vida correcto | ✅ App-scoped services; VMs de pantalla estables; modales por sesión de sheet |
| Protocolos correctos | ✅ Universe: Domain protocols; Events/Templates: Application façades |
| Concretos no filtrados a Presentation | ✅ Sin `EventRepository` / SwiftData en Presentation de producto |
| Creación de ViewModels consistente | ✅ Entry via factory; hijos vía screen coordinator (QA-04) |

### Hallazgos auditados (sin cambio de producto)

| Hallazgo | Decisión |
|----------|----------|
| `NavigationManager` / `AppRouter` en Environment sin consumidores | **Eliminado del Environment**; siguen en el container (reserva QA-06) |
| `EventValidationService` defaulted dentro de `EventPersistenceService` | **Cableado explícito** desde el Composition Root |
| Closures duplicados `storageAvailabilityProvider` | **Unificados** en un solo provider |
| Child VMs (`DayEvents`, `EventEditor`, Templates…) fuera de factory | **Certificado** — patrón screen coordinator; mismas façades |
| Universe History/Detail reciben `UniverseMessageRepositoryProtocol` | **Aceptado** — protocolo Domain, no concreto Infrastructure |
| Façades Application concretas en Environment | **Aceptado** — `@Observable` SSOT; protocolos extra sin beneficio |
| Tests / Previews construyen servicios locales | **Esperado** — no es Composition Root de producción |

---

## Cambios realizados

| Cambio | Motivo |
|--------|--------|
| Docs Composition Root en `DependencyContainer` | Certifica ownership, Environment surface, reserved nav |
| `EventValidationService` cableado en `init()` del container | Elimina dependencia “oculta” por default |
| Un solo `availabilityProvider` compartido | Evita duplicación de closures |
| Quitar `.environment(navigationManager/appRouter)` | Elimina inyección muerta; alinea QA-06 |
| Docs `ViewModelFactory` + `AppEnvironmentKeys` | Documenta entry vs child VMs y Environment real |
| Informe `SprintQA07_DependencyInjectionCertification.md` | Gate QA-07 |

**Tests:** no requieren actualización (ningún test aserta Environment de nav; `StorageAvailabilityTests` usa el container directamente).

**UX / navegación de producto / negocio:** sin cambios.

---

## Riesgos eliminados

1. **Environment falso** — Navigation/AppRouter ya no aparentan ser dependencias de producto.  
2. **Wiring incompleto del Composition Root** — validación de eventos es explícita en el grafo.  
3. **Duplicación de providers** — una sola closure de disponibilidad para Universe + Templates.  
4. **Ambigüedad documental** — queda claro qué va a Environment vs qué queda reserved en el container.

---

## Riesgos restantes

| Riesgo | Severidad | Notas |
|--------|-----------|-------|
| Push stack reserved aún construido al launch | Baja | Coste trivial; preparado para deep links / Settings |
| `universeMessageRepository` / `engine` públicos en el container | Baja | Acceso real vía factory; Views no los leen hoy |
| Child VMs no centralizados en factory | Baja | Intencional (QA-04); ampliar factory solo si proliferan grafos |
| Defaults en `EventPersistenceService.init` (catalog/validation) | Baja | Útiles para tests; producción ya pasa valores desde el root |
| `EventReminderCoordinator` creado dentro de EPS | Baja | Colaborador Application interno; notification llega desde el root |

---

## Preparación para Documentation Certification

Listo para el siguiente gate si se documenta:

1. **Diagrama Composition Root** (este informe + comentarios en `DependencyContainer`).  
2. **Tabla Environment vs reserved** (`AppEnvironmentKeys`).  
3. **Política de ViewModels**: entry = `ViewModelFactory`; children = parent coordinator.  
4. **Frontera capas**: Presentation → Application façades / Domain protocols; nunca Infrastructure concreta.  
5. Encadenar informes QA-01…QA-07 en el índice de certificación Road to 9.5.

**Veredicto QA-07:** 🟢 **Arquitectura DI certificada** (con limpiezas menores de superficie Environment + wiring explícito).
