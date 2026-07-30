# Sprint 6.8 — Smart Daily Agenda

## Resumen

Nueva pantalla pilar **Smart Daily Agenda**: resumen del día, Mensaje del Universo, timeline cronológico, bloque todo el día, huecos de tiempo libre, próximo evento y cierre del día. Lógica de gaps/métricas en Domain (`AgendaTimelineBuilder`); Presentation solo orquesta y muestra.

**Nota:** no existe `EventSearchService` (Sprint 6.7 usó `EventSearchCriteria` + catálogo). Este sprint reutiliza `EventCatalogService` / `EventPersistenceService`, `UniverseMessageEngine`, `CalendarEngine` (navegación de día vía `Calendar`), y el pipeline de notificaciones existente no se toca (los recordatorios siguen en `NotificationService` vía persistencia de eventos).

## Archivos creados

### Domain
- `Domain/Models/Agenda/AgendaModels.swift`
- `Domain/Models/Agenda/AgendaTimelineBuilder.swift`

### Presentation
- `Presentation/ViewModels/Agenda/SmartAgendaViewModel.swift`
- `Presentation/Views/Agenda/SmartAgendaView.swift`
- `Presentation/Views/Agenda/TimelineView.swift` (`AgendaTimelineView` — evita choque con SwiftUI.`TimelineView`)
- `Presentation/Views/Agenda/FreeTimeCard.swift`
- `Presentation/Views/Agenda/AgendaSummaryCard.swift`

### Tests / docs
- `Tests/UnitTests/Domain/AgendaTimelineBuilderTests.swift`
- Este informe

## Archivos modificados

- `Config/Constants/CalendarConstants.swift` — ventana 08:00–20:00
- `Application/DesignSystem/Icons.swift` — `Icons.Home.agenda`
- `Presentation/ViewModels/Home/HomeViewModel.swift` — presenta Agenda
- `Presentation/Views/Home/HomeView.swift` / `HomeHeaderView.swift` — menú Agenda
- `App/CompositionRoot/ViewModelFactory.swift`
- Localización EN/ES
- `Documentation/DataModel.md`, `Architecture.md`, `Roadmap.md`, `README.md`

## Servicios reutilizados

| Servicio | Uso |
| --- | --- |
| `EventPersistenceService` / `EventCatalogService` | `events(on:)` + Observation |
| `UniverseMessageEngine` | Mensaje del día en Agenda |
| `UniverseMessageService` | Sin cambios (favoritos); no selecciona el mensaje diario |
| `CalendarEngine` | No requerido para ±1 día; se usa `Calendar` (mismo patrón que Day Events) |
| `NotificationService` | Intacta; recordatorios al editar eventos desde Agenda |
| `EventSearchCriteria` | No inventamos `EventSearchService` |

## Componentes nuevos (justificación)

| Componente | Justificación |
| --- | --- |
| `AgendaTimelineBuilder` | Math pura Domain (testable, SRP); **no** Application service |
| `SmartAgendaViewModel` | Orquestación Observation / día / Universe |
| Views Agenda | Superficie UI dedicada (pilar del producto) |
| **Application AgendaService** | **No creado** — sería pass-through |

## Cobertura de tests

Suite `AgendaTimelineBuilderTests`:

| Requisito | Tests |
| --- | --- |
| Timeline / ordenación | `testTimelineOrders…`, `testTimedEventsSortedByStart` |
| Tiempo libre | `testFreeTimeDetectsGap…`, `testOverlappingEventsMerge…` |
| Todo el día | `testAllDayEventsExcludedFromTimelineBusyGeometry` |
| Próximo evento | `testNextEventIsFirstAfterNowOnToday`, `testNextEventNil…` |
| Sin eventos | `testEmptyDayHasFullFreeWindow…` |
| VM | `testSmartAgendaViewModelObservesCatalog` |

## Calidad

- **MVVM / Observation:** snapshot derivado toca `eventsRevision`.
- **SOLID:** builder Domain; VM sin SwiftData; views sin negocio.
- **Rendimiento:** un build por lectura de `snapshot`; merge O(n log n) por ordenación.
- **A11y:** labels en cards / timeline / free time.

## Riesgos

1. Ventana fija 08:00–20:00 — no configurable aún.
2. Eventos sin `endDate` usan 1h por defecto en gaps.
3. “Próximo evento” solo mira el día enfocado (no el resto de la semana).
4. All-day no resta del tiempo libre timed (intencional).

## Preparación para Sprint 6.9

Candidatos:

- Personalizar horario laboral / zona.
- Agenda semanal / strip de días (`CalendarEngine.generateWeek`).
- Atajos desde indicadores del grid → Agenda del día.
- Widgets de “próximo evento” / tiempo libre (scaffolding).
- IA / productividad (explícitamente fuera de 6.8).
