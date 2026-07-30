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

## Calendar Experience

Month structure and smart day selection live in ``CalendarEngine``. The grid ViewModel owns period + selection; Home coordinates theme sync and day-events retargeting. Presentation owns swipe/animation only. Observation tracks the event catalog via ``eventsRevision`` on annotated grid reads.

## Advanced Events

``Event.isAllDay`` is persisted through SwiftData Schema V4. Multi-day uses ``date``/``endDate``. Recurrence expands via ``RecurrenceEngine``. Organization (Sprint 6.4): ``Event.tags``, ``Event.priority`` (normal/urgent), ``Event.color`` via Design System palette; Schema V5 stores ``tagsRawValue``. Grid indicators remain color dots, prepared through ``CalendarEventIndicator``. Templates (Sprint 6.5): ``EventTemplate`` / Schema V6 offline blueprints via ``EventTemplateService`` (parallel to the event catalog; no reminder pipeline). Quick ops (Sprint 6.6): ``EventPersistenceService.duplicate/move/copy`` + day-list context menu (no new Application service). Search (Sprint 6.7): ``EventSearchCriteria`` + catalog single-pass filter; ``EventSearchViewModel`` for Observation (no ``EventSearchService``). Agenda (Sprint 6.8): ``AgendaTimelineBuilder`` + ``SmartAgendaViewModel``; reuses catalog + ``UniverseMessageEngine``.
