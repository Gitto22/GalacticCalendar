# Folder Structure

Inventario de carpetas del repositorio `GalacticCalendar`. Toda carpeta top-level y subcarpeta relevante está listada. Los `.gitkeep` indican **reserva estructural** (sin implementación de producto).

## Raíz

| Path | Contenido |
|------|-----------|
| `README.md` | Visión, stack, apertura, tests, índice docs |
| `CHANGELOG.md` | Historial de entregas derivadas de sprints |
| `.gitignore` | Ignorados de git |
| `.swiftlint.yml` | Scaffold SwiftLint |

## `App/` — Composition Root y shell

| Path | Contenido |
|------|-----------|
| `GalacticCalendarApp.swift` | `@main`; instancia `DependencyContainer`; Environment de producto |
| `CompositionRoot/DependencyContainer.swift` | Composition Root |
| `CompositionRoot/ViewModelFactory.swift` | Factory de VMs de entrada |
| `CompositionRoot/EnvironmentKeys.swift` | Lista documentada de dependencias Environment |
| `Navigation/Route.swift` | Enum reservado (`root`) |
| `Navigation/NavigationManager.swift` | `NavigationPath` reservado |
| `Navigation/AppRouter.swift` | Router tipado reservado |

## `Application/` — Servicios y Design System

| Path | Contenido |
|------|-----------|
| `DesignSystem/` | Tokens (`Spacing`, `ColorPalette`, `Typography`, `Animations`, `Motion`, `Shadows`, `GlassEffect`, `Icons`), `ThemeManager`, `CalendarAppearanceManager`, `MonthBackgroundAsset`, `MonthContrastProfile` |
| `Services/` | Persistencia, catálogo, validación, reminders, templates, calendar engine, recurrence, notifications, logging, storage availability |
| `Services/Universe/` | `UniverseMessageEngine`, `UniverseMessageService` |
| `Managers/` | Vacía (managers de producto viven en DesignSystem) |

## `Presentation/` — UI

| Path | Contenido |
|------|-----------|
| `Views/Home/` | Home, header, calendar container, month background, Universe card |
| `Views/Events/` | Day events, editor, search |
| `Views/Agenda/` | Smart agenda + cards de timeline / free time / summary |
| `Views/Universe/` | History / detail views |
| `Views/Templates/` | List / editor / picker de plantillas |
| `Views/Calendar/` | Month / year pickers |
| `Views/Shared/` | `RootView` (shell `NavigationStack`) |
| `ViewModels/Home/` | `HomeViewModel`, `UniverseMessageViewModel` |
| `ViewModels/Calendar/` | Grid, month picker, year picker |
| `ViewModels/Events/` | DayEvents, EventEditor, EventSearch (+ enums auxiliares) |
| `ViewModels/Agenda/` | `SmartAgendaViewModel` |
| `ViewModels/Templates/` | Templates list / editor / picker VMs |
| `ViewModels/Universe/` | History, Detail |
| `Components/Buttons/` | p.ej. `GlassCircleButton` |
| `Components/Calendar/` | Grid, day cell, week header, indicators, highlight |
| `Components/Events/` | Rows, tag picker, etc. |
| `Components/Universe/` | Message row |
| `Previews/` | Repositorios / helpers de preview |
| `Utilities/` | Utilidades de presentación |

## `Domain/` — Modelos y contratos

| Path | Contenido |
|------|-----------|
| `Models/Events/` | `Event`, schedule, tags, colors, priority, status, category, `RepeatRule`, codecs, search criteria, reminder options |
| `Models/Recurrence/` | `RecurrenceRule`, frequency, end rule, `EventOccurrence` |
| `Models/Calendar/` | Day, month navigation, smart day selection, event indicators |
| `Models/Agenda/` | Modelos de agenda + `AgendaTimelineBuilder` |
| `Models/Templates/` | `EventTemplate` |
| `Models/Universe/` | Message, category, history entry |
| `Models/Common|Event|Statistics|Subscription|Theme|UniverseMessage/` | Placeholders (`.gitkeep`) |
| `Protocols/Repositories/` | Event, EventTemplate, Universe, Notification (+ errores Event) |
| `Protocols/Services/` | `CalendarGenerating` (+ placeholders) |
| `Protocols/Managers/` | Placeholder |
| `UseCases/*/` | Placeholders por dominio (Events, Calendar, Sync, …) — **sin casos de uso implementados** |

## `Data/` — Persistencia

| Path | Contenido |
|------|-----------|
| `Repositories/` | `EventRepository`, `EventTemplateRepository`, `UniverseMessageRepository`, `NotificationRepository`; `Unavailable*`; scaffolds `Backup|Calendar|Settings|Statistics|SubscriptionRepository` |
| `Database/` | Entidades SwiftData, `ModelContainerFactory`, schema versioning, mappers, `CatalogResilientDecoder` |
| `Services/` | Scaffold vacío / reserva |

## `Infrastructure/` — Sistema

| Path | Contenido |
|------|-----------|
| `Managers/` | Stubs: CloudKit, Widget, StoreKit, EventKit, Backup, Sharing; `NotificationManager` |
| `Intents/` | `AppShortcutsProvider` + placeholders Entities/Intents |
| `Platform/iOS|macOS/` | Placeholders |

## `Config/`

| Path | Contenido |
|------|-----------|
| `AppConfiguration/` | App / platform / bundle configuration |
| `FeatureFlags/` | `FeatureFlag`, catalog, provider |
| `Constants/` | App, Calendar, Layout, CloudKit, Widget, StoreKit constants |
| `Environment/` | App environment, secrets policy / placeholders |

## `Assets/`

| Path | Contenido |
|------|-----------|
| `Assets.xcassets/Months/` | Fondos mensuales Jan–Dec (**única** ubicación de imagery mensual) |
| `Assets.xcassets/AppIcon.appiconset/` | Icono de app (incl. 1024 RGB para iOS) |
| `Assets.xcassets/Colors|Symbols/` | Colores / símbolos del asset catalog |
| Preview Content | Assets de preview |

## `Resources/`

| Path | Contenido |
|------|-----------|
| `Localization/` | `en` + `es` |
| `ConfigFiles/` | Info / Privacy Manifest (`PrivacyInfo.xcprivacy`) |
| `Fonts/` | Placeholder |

## `Shared/`

| Path | Contenido |
|------|-----------|
| Extensions / Utilities | Placeholders estructurales |

## `Tests/`

| Path | Contenido |
|------|-----------|
| `UnitTests/Application|Calendar|Data|DesignSystem|Domain|Universe|ViewModels|Support/` | Suites unitarias |
| `UnitTests/Config|Intents|Managers/` | Placeholders |
| `IntegrationTests/Database/` | SwiftData integration + harness + resilience |
| `IntegrationTests/Backup|CloudKit|Notifications|StoreKit/` | Placeholders |
| `UITests/Support|Calendar|Events|Universe/` | Smoke UI (QA-01) |
| `*/README.md` | Cómo añadir targets en Xcode |

## `Documentation/`

| Path | Contenido |
|------|-----------|
| Guías certificadas QA-08 | Architecture, FolderStructure, Development, Contributing, CodingStandards, Testing, Release, Roadmap, DataModel |
| `SprintReports/` | Informes PB / QA / hardening |
| `CodingGuidelines.md` | Puntero legacy → `CodingStandards.md` |

## `Legal/` · `Marketing/`

| Path | Contenido |
|------|-----------|
| `Legal/` | Privacy, Terms, Licenses |
| `Marketing/` | App Store copy, brand guidelines |

## `Widgets/` · `WatchApp/`

| Path | Contenido |
|------|-----------|
| `Widgets/` | Scaffold WidgetKit (no producto Private Beta) |
| `WatchApp/` | README de reserva Apple Watch |

## Reglas de ubicación

1. Fondos de mes → solo `Assets/Assets.xcassets/Months`.
2. Nuevos servicios de aplicación → `Application/Services/` (Universe bajo `Services/Universe/`).
3. Nuevos repos → protocolo en `Domain/Protocols/Repositories/`, implementación en `Data/Repositories/`, wire en `DependencyContainer`.
4. No crear segundo Composition Root en Views.
