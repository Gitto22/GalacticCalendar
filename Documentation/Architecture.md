# Galactic Calendar — Architecture

Clean Architecture + MVVM for iPhone, iPad, and macOS.

## Layers

- **App / Config** — Composition Root, environment, feature flags, constants
- **Presentation** — Views, ViewModels, Components
- **Domain** — Models, UseCases, Protocols
- **Data** — Repositories, Database (SwiftData), Services
- **Infrastructure** — Managers, App Intents, Platform adapters
- **Shared** — Extensions, Utilities
- **Widgets** — WidgetKit target
- **WatchApp** — Reserved for future Apple Watch support

## Dependency rule

Presentation → Domain ← Data / Infrastructure

Only `App` wires concrete implementations.
