# Galactic Calendar — Architecture

Clean Architecture + MVVM for iPhone, iPad, and macOS.

## Layers

- **App / Config** — Composition Root, environment, feature flags, constants
- **Application** — Design System (ThemeManager, tokens) and application services
- **Presentation** — Views, ViewModels, Components (including Home)
- **Domain** — Models, UseCases, Protocols
- **Data** — Repositories, Database (SwiftData), Services
- **Infrastructure** — System integrations, App Intents, Platform adapters
- **Shared** — Extensions, Utilities
- **Widgets** — WidgetKit target
- **WatchApp** — Reserved for future Apple Watch support

## Dependency rule

Presentation → Domain ← Data / Infrastructure

Only `App` wires concrete implementations.
