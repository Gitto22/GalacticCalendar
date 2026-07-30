# Sprint 6.7 — Smart Search Engine

## Resumen

Motor de búsqueda/filtrado incremental sobre el catálogo en memoria. **No** se creó `EventSearchService`: la lógica vive en Domain (`EventSearchCriteria`) + `EventCatalogService` (pipeline de un solo paso), con Observation en `EventSearchViewModel`.

## 1. Archivos modificados / creados

### Creados
- `Domain/Models/Events/EventSearchCriteria.swift`
- `Presentation/ViewModels/Events/EventSearchViewModel.swift`
- `Presentation/Views/Events/EventSearchView.swift`
- `Tests/UnitTests/Domain/EventSearchCriteriaTests.swift`
- Este informe

### Modificados
- `Application/Services/EventCatalogService.swift` — `events(matching:)`, `events(on:matching:)`, `eventsGroupedByDay(in:matching:)`
- `Application/Services/EventPersistenceService.swift` — forwards de búsqueda
- `Domain/Protocols/Repositories/EventRepositoryProtocol.swift` — `fetch(matching:)` + default
- `Data/Repositories/EventRepository.swift` — `fetch(matching:)`
- `Tests/UnitTests/Support/InMemoryEventRepository.swift`
- `Presentation/ViewModels/Calendar/CalendarGridViewModel.swift` — `bindSearch` / anotaciones filtradas
- `Presentation/ViewModels/Events/DayEventsViewModel.swift` — lista filtrada
- `Presentation/ViewModels/Home/HomeViewModel.swift` — presenta búsqueda + comparte VM
- `Presentation/Views/Home/HomeView.swift` / `HomeHeaderView.swift` — menú Historial + Buscar
- `App/CompositionRoot/ViewModelFactory.swift`
- Localización EN/ES, `DataModel.md`, `Architecture.md`, `Roadmap.md`, `README.md`

## 2. Servicios reutilizados

| Servicio | Uso |
| --- | --- |
| `EventCatalogService` | SSOT de lectura + pipeline único de filtrado |
| `EventPersistenceService` | Façade Observation para VMs |
| `EventRepository` | `fetch(matching:)` offline/tooling (sin expansión de recurrencia) |
| `RecurrenceEngine` | Date facets en el catálogo |
| UI History search field | Patrón de campo glass reutilizado |

## 3. Componentes nuevos (justificación)

| Componente | ¿Por qué? |
| --- | --- |
| `EventSearchCriteria` | Value type de Domain; SRP y tests puros |
| `EventSearchViewModel` | Evita sobrecargar `HomeViewModel`; Observation incremental |
| `EventSearchView` | Presentación; sin lógica de negocio |
| **`EventSearchService`** | **No creado** — sería un pass-through sobre el catálogo |

## 4. Cobertura de tests

Suite `EventSearchCriteriaTests`:

| Requisito | Tests |
| --- | --- |
| Texto | `testTextSearchMatchesTitleDescriptionAndTags` |
| Etiquetas | `testTagFilterRequiresAllSelectedTags` |
| Intervalos | `testDateIntervalFilterViaCatalog`, `testQuickRangeThisWeekBuildsInterval` |
| Prioridad | `testPriorityFilter` |
| Combinación | `testCombinedFiltersWorkAndHighAndColor`, facets |
| Vacío | `testEmptyCriteriaReturnsAll`, `testEmptyResultsWhenNothingMatches` |
| Rendimiento | `testFilterSinglePassPerformance` (2k eventos) |
| Integración | persistence + repository + ViewModel incremental |

## 5. Riesgos

1. Filtros de fecha en **repositorio** no expanden recurrencia (documentado; UI usa catálogo).
2. Tags en AND; prioridades/colores en OR — documentar UX si se confunde.
3. Criterios activos siguen aplicando al grid tras cerrar la búsqueda (`appliesToCalendar`); Clear limpia.
4. Menú Home ahora combina Historial + Buscar (cambio de interacción mínimo).

## 6. Preparación para Sprint 6.8

Candidatos naturales:

- Exclusiones de fechas / weekday filters / RRULE custom (Roadmap).
- Ranking / orden por relevancia del texto.
- Guardar “vistas” de filtros favoritas.
- Debounce tipográfico si el catálogo crece mucho.
- (Fuera de alcance aún) Spotlight / widgets / CloudKit.
