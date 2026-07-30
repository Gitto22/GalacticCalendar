# Changelog

All notable product and architecture milestones derived from sprint reports and the current codebase. Dates follow report stamps (2026).

Format: keep entries factual — no aspirational features.

## [Unreleased]

### Documentation

- QA-08 Documentation Certification: Architecture, FolderStructure, Development, Contributing, CodingStandards, Testing, Release, Roadmap, README, CHANGELOG.

## [Private Beta] — 2026-07-30

### Certified

- Private Beta certification audit: **apto** (score ~8.5).
- PB-06 production readiness; App Icon 1024 RGB wired.
- PB-05 architecture cleanup (ThemeManager / CalendarAppearance SRP; EventPersistence / ReminderCoordinator; bootstrap → `refresh()`; Repeat vs Recurrence dual stack kept).
- QA-01 UI smoke suite sources under `Tests/UITests/`.
- QA-02 SwiftData integration harness + cases.
- QA-03 catalog resilience (skip corrupt rows on list fetch).
- QA-04 ViewModel responsibility audit (no code change required).
- QA-05 Design System token certification.
- QA-06 Navigation certification (modal product pattern; push reserved).
- QA-07 Dependency Injection certification (Composition Root; Environment surface cleaned).

### In scope

- Local calendar, events (templates, search, agenda, recurrence expansion), Universe Messages, a11y base, safe persistence.

### Explicitly out of scope

- CloudKit, Widgets, Apple Watch.

## [Advanced Events] — Sprint 6.x

- 6.1 All-day · 6.2 Multi-day · 6.3 Recurrence expansion · 6.4 Tags/colors/priority  
- 6.5 Templates · 6.6 Quick operations · 6.7 Smart search · 6.8 Smart daily agenda  
- 6.9–6.10 Hardening / production hardening (module closed)

## [Calendar Experience] — Sprint 5.x

- Month navigation, pickers, Today, smart day selection, Observation via `eventsRevision`.

## [Universe Messages] — Sprint 4.x

- Daily message, detail, history, favorites via `UniverseMessageService` / engine.

## [Foundation]

- Clean Architecture + MVVM layout, Composition Root, Design System tokens, SwiftData events store, local notifications pipeline.

---

For field-level schema history see `Documentation/DataModel.md`.  
For narrative detail see `Documentation/SprintReports/`.
