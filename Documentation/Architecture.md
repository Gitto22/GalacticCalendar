# Galactic Calendar — Architecture

Documento derivado del código y de los sprint reports de certificación (PB-05…QA-07). No describe módulos scaffold como si estuvieran en producción.

## Visión

Calendario local multiplataforma (iPhone, iPad, macOS) con **Clean Architecture** y **MVVM** (SwiftUI + `@Observable`). Un único **Composition Root** (`DependencyContainer`) cablea Infrastructure → Application → Presentation.

## Capas

| Capa | Path | Responsabilidad real |
|------|------|----------------------|
| App | `App/` | `@main`, Composition Root, factory de ViewModels, navegación **reservada** |
| Config | `Config/` | `AppConfiguration`, feature flags, constantes |
| Application | `Application/` | Design System + servicios de aplicación (catálogo, persistencia, engines) |
| Presentation | `Presentation/` | Views, ViewModels, Components |
| Domain | `Domain/` | Modelos + protocolos de repositorio; UseCases mayormente placeholders |
| Data | `Data/` | Repositorios SwiftData, entidades, mappers, decode resiliente |
| Infrastructure | `Infrastructure/` | Managers de sistema (CloudKit/Widgets/StoreKit/… **stubs**); App Intents scaffold |
| Shared | `Shared/` | Extensiones / utilidades (placeholders) |
| Widgets / WatchApp | `Widgets/`, `WatchApp/` | Estructura reservada — **fuera de Private Beta** |

### Regla de dependencia

```
Presentation → Application / Domain
Data / Infrastructure → Domain
App (Composition Root) → todo lo concreto
```

Presentation **no** importa SwiftData ni tipos concretos de repositorio de eventos. Universe History/Detail reciben `UniverseMessageRepositoryProtocol` (Domain) vía factory.

## MVVM

- Views: SwiftUI, estado de presentación mínimo; sheets/covers ligados a flags del ViewModel.
- ViewModels: `@MainActor` + `@Observable`; coordinan pantallas y llaman a Application.
- Entry VMs (`HomeViewModel`, `CalendarGridViewModel`, Universe card) → `ViewModelFactory`.
- Child / modal VMs (`DayEvents`, `EventEditor`, Templates, Agenda, pickers) → creados por el screen coordinator padre (certificado QA-04 / QA-07).

## Dependency Injection

- **Único root:** `App/CompositionRoot/DependencyContainer.swift` (una instancia en `GalacticCalendarApp`).
- **Factory:** `ViewModelFactory` — Home, grid, Universe card + closures History/Detail.
- **Environment (producto):** container, `AppConfiguration`, `ThemeManager`, `CalendarAppearanceManager`, `EventPersistenceService`, `EventTemplateService`.
- **Owned pero no Environment:** `NavigationManager`, `AppRouter` (reserva push; QA-06 / QA-07).
- **Privado en container:** `NotificationService` (inyectado en persistencia).

Detalle: `Documentation/SprintReports/SprintQA07_DependencyInjectionCertification.md`.

## SwiftData

- Apertura: `ModelContainerFactory` desde el Composition Root.
- Éxito → `modelContainer` + repos reales; fallo → `Unavailable*Repository` + `StorageAvailability.unavailable` (sin store in-memory silencioso en producto).
- Entidades / schema: `Data/Database/` (`EventEntity`, `EventTemplateEntity`, Universe, versionado).
- Modelo de campos: `Documentation/DataModel.md`.
- Catálogo resiliente: filas corruptas omitidas en listados (QA-03).

## Event Catalog y persistencia

```
ViewModel
  → EventPersistenceService   (writes: validate → repository → reminders → catalog refresh)
  → EventCatalogService       (in-memory SSOT de lectura)
  ← events / eventsRevision   (Observation)
```

| Pieza | Rol |
|-------|-----|
| `EventPersistenceService` | Fachada de escritura / espejo de catálogo |
| `EventCatalogService` | Catálogo reactivo en memoria; expansión de recurrencia para UI |
| `EventValidationService` | Validación pre-persistencia |
| `EventReminderCoordinator` | Efectos de recordatorio local |
| `EventTemplateService` | CRUD plantillas (sin pipeline de reminders) |
| `NotificationService` | Schedule/cancel vía `NotificationRepository` |

Lecturas de presentación (grid, día, search, agenda) usan el **catálogo**, no `repository.fetch(on:)` (filtra solo `entity.date`).

## Design System

`Application/DesignSystem/`:

| Tipo | Archivos |
|------|----------|
| Tokens | `Spacing`, `ColorPalette`, `Typography`, `Animations`, `Motion`, `Shadows`, `GlassEffect`, `Icons` |
| Appearance | `ThemeManager`, `CalendarAppearanceManager` |
| Mes | `MonthBackgroundAsset`, `MonthContrastProfile` |

Certificación tokens: QA-05. Fondos mensuales solo en `Assets/Assets.xcassets/Months`.

### ThemeManager

Preferencias de apariencia / theme packs (`GalacticDefaultThemePack`). No posee lógica de fondos mensuales (SRP PB-05.1).

### CalendarAppearanceManager

Títulos de mes e imagery mensual; contraste sobre fondos. Separado de `ThemeManager`.

## Navigation

| Pieza | Estado |
|-------|--------|
| Producto | `fullScreenCover` / `sheet` + `isPresenting*` en ViewModels |
| Shell | `NavigationStack` en `RootView` (host) |
| `Route` / `NavigationManager` / `AppRouter` | **Reservados** — no usados por flujos de producto |

Certificación: `SprintQA06_NavigationCertification.md`.

## Universe Messages

| Pieza | Rol |
|-------|-----|
| `UniverseMessageEngine` | Día → mensaje determinista |
| `UniverseMessageService` | Favoritos / metadatos de categoría |
| `UniverseMessageRepository` (+ Unavailable) | Persistencia catálogo / historial |
| VMs | Card (`UniverseMessageViewModel`), History, Detail |

## Repeat vs Recurrence (decisión arquitectónica)

**Se mantienen separados a propósito** (análisis PB-05.4; sin unificación forzada).

| Stack | Ubicación | Contrato |
|-------|-----------|----------|
| **Repeat\*** | `Domain/Models/Events/RepeatRule.swift` | Persistencia / producto (`repeatRuleRawValue`; token `none`) |
| **Recurrence\*** | `Domain/Models/Recurrence/` + `RecurrenceEngine` | Expansión a ocurrencias virtuales (token `never`) |
| UI | `RecurrenceEndKind` | Modos de fin en el editor; no se persiste como tipo de motor |
| Puente | `RepeatRule.asRecurrenceRule` | Anti-corruption: store ≠ engine |

Motivo: codecs estables y presets de producto no deben contaminar el álgebra del motor (ni viceversa). Extensiones futuras de motor (`byWeekdays`, exclusiones) viven en Recurrence sin alterar el wire format.

## Managers

| Manager | Capa | Estado |
|---------|------|--------|
| `ThemeManager` | Application | Producto |
| `CalendarAppearanceManager` | Application | Producto |
| `NavigationManager` | App | Reservado |
| `CloudKitManager`, `WidgetDataManager`, `StoreKitManager`, `EventKitManager`, `BackupManager`, `SharingManager` | Infrastructure | Stub / futuro |
| `NotificationManager` | Infrastructure | Presente; scheduling de producto pasa por `NotificationService` + repository |

## Servicios de Application (inventario)

`CalendarEngine`, `EventCatalogService`, `EventPersistenceService`, `EventReminderCoordinator`, `EventTemplateService`, `EventValidationService`, `NotificationService`, `PersistenceLog`, `RecurrenceEngine`, `StorageAvailability`, `UniverseMessageEngine`, `UniverseMessageService`.

## ViewModels (inventario)

Home · Universe card · Calendar grid / month / year pickers · DayEvents · EventEditor · EventSearch · SmartAgenda · Templates (list / editor / picker) · Universe History / Detail.

## Fuera de alcance documentado como producto

CloudKit sync, Widgets, Watch, StoreKit, EventKit sharing, Settings module, UseCases Domain (placeholders), repos scaffold (`SettingsRepository`, `BackupRepository`, …).
