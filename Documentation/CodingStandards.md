# Coding Standards

Estándares derivados del código existente, `.swiftlint.yml` y guías de sprints (PB-05, QA-04…07). Sustituye el listado genérico anterior de `CodingGuidelines.md`.

## Swift style

- Swift 6; SwiftUI para UI; SwiftData solo en `Data/` (+ Composition Root / tests).
- `@MainActor` en tipos que tocan UI o servicios observados por UI.
- `@Observable` para estado reactivo de producto (VMs, fachadas Application, managers de apariencia).
- Evitar `force unwrap` / IUO (reglas opt-in en SwiftLint).
- Línea: warning 120 / error 200; archivo: warning 400 / error 800 (SwiftLint scaffold).

## Naming

| Elemento | Convención | Ejemplo |
|----------|------------|---------|
| Tipos | UpperCamelCase | `EventPersistenceService` |
| Protocolos | Sufijo `Protocol` en repos | `EventRepositoryProtocol` |
| ViewModels | Sufijo `ViewModel` | `HomeViewModel` |
| Unavailable stand-ins | Prefijo `Unavailable` | `UnavailableEventRepository` |
| Flags de modal | `isPresenting…` | `isPresentingDayEvents` |
| Accessibility IDs | snake / tokens estables | ver `SmokeAccessibilityID` |

## SRP / SOLID

- Un tipo, una razón de cambio (Theme vs Calendar appearance; persistencia vs reminder coordinator).
- Depender de protocolos Domain en fronteras de persistencia; fachadas Application para Observation UI.
- Composition Root es el único lugar que conoce grafos concretos largos.
- No añadir UseCase Domain vacío “por ceremonial” — los UseCases actuales son placeholders; la orquestación vive en Application services hasta que un UseCase aporte valor real.

## Organización de archivos

- Una idea principal por archivo; enums auxiliares de UI pueden vivir junto al VM (`RecurrenceEndKind`).
- Carpetas por feature dentro de Views/ViewModels/Components.
- Previews y dobles de preview en `Presentation/Previews/` o al final del archivo de View con tipos `private`.

## MARK

Organizar tipos con `// MARK: -` coherente, p.ej.:

```swift
// MARK: - Properties
// MARK: - Lifecycle
// MARK: - Derived
// MARK: - Intents
```

## Comentarios

- `///` en APIs públicas y tipos de capa (servicios, repos, VMs).
- Explicar **por qué** / contratos (SSOT, reserved, unavailable), no narrar el código línea a línea.
- No documentar features scaffold como enviadas.

## Design System

- Espaciado / color / motion vía tokens (`Spacing`, `ColorPalette`, `Animations` / `Motion`).
- Colores de evento solo vía `EventColor` + palette — no hex sueltos en Views de producto.
- Fondos de mes solo desde asset catalog `Months`.

## Persistencia

- Escrituras de eventos → `EventPersistenceService`.
- Lecturas de UI → catálogo (`events` / `eventsRevision`), no queries de repo por día para presentación.
- Fallo de store → `Unavailable*` + `StorageAvailability`; nunca fingir éxito con memoria efímera en producto.

## Navegación

- Producto: modales en ViewModels.
- No acoplar features a `AppRouter` / `NavigationManager` hasta que el push stack sea producto.

## Tests

- Nombres `test…` descriptivos; harness de integration aislado por test.
- No sleeps fijos en UITests; preferir expectations / IDs.
