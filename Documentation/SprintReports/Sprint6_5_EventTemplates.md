# Sprint 6.5 — Plantillas de eventos

## Resumen

Sistema completo de plantillas offline para Galactic Calendar: guardar un evento como plantilla, crear/editar/eliminar/duplicar plantillas, y rellenar el editor al crear un evento desde plantilla **sin copiar fecha, hora ni recordatorios disparados**.

Arquitectura intacta (SwiftUI + SwiftData + MVVM + Clean Architecture + Observation). El catálogo de eventos y el pipeline de recordatorios no se modifican en su contrato; las plantillas viven en un stack paralelo.

## Archivos creados

### Domain
- `Domain/Models/Templates/EventTemplate.swift`
- `Domain/Protocols/Repositories/EventTemplateRepositoryProtocol.swift`

### Data
- `Data/Database/SwiftData/EventTemplateEntity.swift`
- `Data/Database/Mappers/EventTemplateEntityMapper.swift`
- `Data/Repositories/EventTemplateRepository.swift`

### Application
- `Application/Services/EventTemplateService.swift`

### Presentation
- `Presentation/ViewModels/Templates/EventTemplatesViewModel.swift`
- `Presentation/ViewModels/Templates/EventTemplateEditorViewModel.swift`
- `Presentation/ViewModels/Templates/EventTemplatePickerViewModel.swift`
- `Presentation/Views/Templates/EventTemplatesView.swift`
- `Presentation/Views/Templates/EventTemplateEditorView.swift`
- `Presentation/Views/Templates/EventTemplatePickerView.swift`

### Tests
- `Tests/UnitTests/Support/InMemoryEventTemplateRepository.swift`
- `Tests/UnitTests/Application/EventTemplateServiceTests.swift`

### Documentación
- `Documentation/SprintReports/Sprint6_5_EventTemplates.md` (este informe)

## Archivos modificados (integración)

- Schema V6 + migración ligera: `SchemaVersioning.swift`, `ModelContainerFactory.swift`
- Composition Root: `DependencyContainer.swift`, `ViewModelFactory.swift`, `GalacticCalendarApp.swift`, `EnvironmentKeys.swift`
- Editor: `EventEditorViewModel.swift`, `EventEditorView.swift` (`prepareForCreation(from:on:)`, save-as-template, “Crear desde plantilla”)
- Día: `DayEventsViewModel.swift`, `DayEventsView.swift`
- Home: `HomeViewModel.swift` (bootstrap + inyección de `EventTemplateService`)
- Design System: `Icons.swift`
- Localización EN/ES: `Localizable.strings`
- Docs: `DataModel.md`, `Roadmap.md`, `README.md`

## Capacidades

| Acción | Dónde |
| --- | --- |
| Guardar evento como plantilla | Editor (modo edición) |
| Crear plantilla desde cero | Gestionar plantillas → Nueva plantilla |
| Editar / eliminar / duplicar | Lista de plantillas (tap / menú contextual / swipe) |
| Crear desde plantilla | Day Events + Editor (modo creación) |
| Auto-relleno | Título, descripción/notas, color, etiquetas, prioridad, duración, todo el día, recurrencia, status |
| No se copia | Fecha, hora absoluta, recordatorios ya disparados |

## Persistencia

- `EventTemplateEntity` en Schema **V6** (migración ligera V5 → V6).
- Campos alineados con el snapshot de contenido (incluye `durationSeconds`, `tagsRawValue`, `repeatRuleRawValue`).
- Offline-first vía SwiftData local; sin CloudKit ni red.

## Cobertura de tests

Suite: `EventTemplateServiceTests` (+ editor apply / save-as-template).

| Caso | Test |
| --- | --- |
| Creación | `testCreatePersistsTemplate`, `testSaveEventAsTemplateStripsScheduleAndReminders` |
| Edición | `testUpdatePersistsEdits` |
| Eliminación | `testDeleteRemovesTemplate` |
| Duplicado | `testDuplicateCreatesIndependentCopy` |
| Evento desde plantilla | `testScheduleBoundsDoNotCopyAbsoluteDates`, `testEditorApplyTemplateFillsContentWithoutReminderFireDate`, `testSaveCurrentAsTemplateFromEditor` |

**Cobertura funcional del sprint:** CRUD + apply + save-from-event cubiertos con repositorio in-memory. No se midió % de líneas con Xcode Coverage en este entorno; la suite es unitaria y determinista.

## Revisión SOLID / MVVM / duplicación

- **S:** `EventTemplateService` no toca recordatorios ni el catálogo de eventos.
- **O/D:** UI habla con servicios/protocolos; repositorio intercambiable (`InMemory` en tests).
- **MVVM:** Views sin lógica de persistencia; ViewModels `@Observable`.
- **Duplicación:** materialización compartida en `EventTemplate.from(event:)` / `scheduleBounds(on:)`; apply centralizado en `EventEditorViewModel.prepareForCreation(from:on:)`.

## Riesgos detectados

1. **Migración V6:** dispositivos con store V5 deben migrar en frío; si el store está corrupto, el Composition Root ya cae a in-memory (igual que eventos).
2. **Duración all-day:** plantillas all-day usan `durationSeconds` + `EventSchedule.normalizeAllDay`; spans multi-día complejos dependen de la duración guardada.
3. **Recurrencia avanzada:** el editor de plantillas ofrece presets de frecuencia; fin por conteo/fecha se conserva al aplicar desde un evento, pero el editor de plantilla no expone aún todos los controles de fin de recurrencia del editor de eventos.
4. **Acceso a gestión:** la gestión completa está en Day Events (icono) y en el picker (“Gestionar plantillas”); no hay entrada en el menú Home (a propósito, para no tocar Universe History).
5. **Xcode project:** el repo usa inclusión por carpeta / proyecto externo; hay que confirmar que los archivos nuevos están en el target de app y tests al abrir el `.xcodeproj` del monorepo.

## Preparación para Sprint 6.6

Candidatos naturales (alineados con Roadmap):

- Filtros / búsqueda por etiqueta, prioridad y color (plantillas y eventos).
- Atajos: duplicar plantilla → crear evento en un paso.
- Extender el editor de plantillas con los mismos controles de fin de recurrencia que el editor de eventos.
- (Si 6.6 es otro tema) dejar el stack de plantillas estable: no mezclar con EventKit / CloudKit todavía.

## Cómo verificar manualmente

1. Crear evento → Guardar → Abrir editor → **Guardar como plantilla**.
2. Day Events → **Crear desde plantilla** → comprobar campos rellenados y fecha del día actual.
3. Gestionar plantillas → editar / duplicar / eliminar.
4. Relanzar app offline → plantillas siguen presentes.
