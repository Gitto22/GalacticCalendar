# Galactic Calendar

Calendario profesional para **iPhone**, **iPad** y **macOS** (SwiftUI). Enfoque local: eventos, plantillas, agenda inteligente y mensajes del Universo — sin CloudKit, Widgets ni Apple Watch en el alcance de Private Beta.

## Objetivos

- Calendario mensual usable a diario (navegación, Today, indicadores de color).
- Eventos locales con SwiftData: CRUD, all-day, multi-día, repetición, recordatorios, plantillas, búsqueda y agenda.
- Universe Messages diarios (detalle, historial, favoritos).
- Accesibilidad base (Dynamic Type, VoiceOver, contraste sobre fondos mensuales).
- Persistencia segura: si el store no abre, la app no escribe en un almacén efímero silencioso.

## Arquitectura

**Clean Architecture + MVVM** con Composition Root único (`DependencyContainer`).

| Capa | Rol |
|------|-----|
| `App/` | Entry point, DI, navegación reservada |
| `Application/` | Design System + servicios de aplicación |
| `Presentation/` | Views, ViewModels, Components |
| `Domain/` | Modelos y protocolos |
| `Data/` | Repositorios SwiftData + mappers |
| `Infrastructure/` | Integraciones de sistema (mayoría scaffold) |
| `Config/` | Flags, constantes, configuración |

Detalle: [`Documentation/Architecture.md`](Documentation/Architecture.md).

## Tecnologías

| En uso (producto) | Scaffold / fuera de Private Beta |
|-------------------|----------------------------------|
| Swift 6, SwiftUI, SwiftData | CloudKit |
| Observation (`@Observable`) | WidgetKit / Widgets |
| UserNotifications | Apple Watch (`WatchApp/`) |
| XCTest (unit / integration / UI smoke) | StoreKit 2, EventKit, App Intents |

## Cómo abrir el proyecto

1. Clonar este repositorio.
2. Abrir el **proyecto Xcode local** de Galactic Calendar. El `.xcodeproj` / workspace puede vivir **fuera de este árbol git** (no está versionado aquí).
3. Seleccionar el scheme de la app y un simulador / dispositivo iOS (o destino macOS si el target está configurado).
4. Antes de archivar: confirmar que `Resources/ConfigFiles/PrivacyInfo.xcprivacy` está en el target (Copy Bundle Resources).

Punto de entrada del código: `App/GalacticCalendarApp.swift`.

## Cómo ejecutar los tests

| Suite | Fuentes | Notas |
|-------|---------|-------|
| Unit | `Tests/UnitTests/` | Target unitario con `@testable import GalacticCalendar` |
| Integration (SwiftData) | `Tests/IntegrationTests/Database/` | Ver `Tests/IntegrationTests/README.md` |
| UI Smoke | `Tests/UITests/` | Requiere UI Testing Bundle; ver `Tests/UITests/README.md` |

Guía completa: [`Documentation/TestingGuide.md`](Documentation/TestingGuide.md).

SwiftLint (scaffold): `.swiftlint.yml` en la raíz.

## Organización general

```
App/  Application/  Presentation/  Domain/  Data/  Infrastructure/
Config/  Assets/  Resources/  Shared/  Tests/  Documentation/
Legal/  Marketing/  Widgets/  WatchApp/
```

- Estructura de carpetas: [`Documentation/FolderStructure.md`](Documentation/FolderStructure.md)
- Roadmap: [`Documentation/Roadmap.md`](Documentation/Roadmap.md)
- Changelog: [`CHANGELOG.md`](CHANGELOG.md)
- Índice de guías: sección siguiente

## Documentación técnica (Quality Gate 5)

| Documento | Ruta |
|-----------|------|
| Architecture | `Documentation/Architecture.md` |
| Folder structure | `Documentation/FolderStructure.md` |
| Development guide | `Documentation/DevelopmentGuide.md` |
| Contributing | `Documentation/Contributing.md` |
| Coding standards | `Documentation/CodingStandards.md` |
| Testing guide | `Documentation/TestingGuide.md` |
| Release process | `Documentation/ReleaseProcess.md` |
| Data model | `Documentation/DataModel.md` |
| Roadmap | `Documentation/Roadmap.md` |
| Sprint reports | `Documentation/SprintReports/` |

## Private Beta (estado certificado)

🟢 **Apto para Beta privada** (auditoría PB-06 / certificación 2026-07-30).

**En alcance:** calendario local, eventos avanzados (plantillas, búsqueda, agenda, expansión de recurrencia), Universe Messages, a11y base, persistencia segura.

**Fuera de alcance (no envío):** CloudKit · Widgets · Apple Watch.

## Producto / legal

| Doc | Path |
|-----|------|
| Privacy | `Legal/PrivacyPolicy.md` |
| Terms | `Legal/TermsOfUse.md` |
| ASC copy | `Marketing/AppStore/` |
| Info / Privacy Manifest | `Resources/ConfigFiles/` |

## Localization

`en` + `es` — paridad de claves en `Resources/Localization/`.

## Bundle

Fallback Bundle ID: `com.albancal.GalacticCalendar` (`Config/Constants/AppConstants.swift`).
