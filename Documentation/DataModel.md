# Data Model

Local SwiftData schema for Galactic Calendar events. CloudKit mirroring is **not** enabled.

## Entity: `EventEntity`

Maps 1:1 to the Domain `Event` model via `EventEntityMapper`.

| Field | Type | Notes |
| --- | --- | --- |
| `id` | `UUID` | `@Attribute(.unique)` — must be reconsidered before CloudKit |
| `title` | `String` | Required |
| `eventDescription` | `String` | Named to avoid `CustomStringConvertible` clash |
| `date` | `Date` | Start instant (`Event.startDate` alias; start-of-day when all-day) |
| `endDate` | `Date?` | Optional end (end-of-day when all-day; later day ⇒ multi-day) |
| `isAllDay` | `Bool` | All-day flag (default `false`; Schema V4) |
| — | — | `Event.isMultiDay` is **derived** (no extra column; CloudKit-safe) |
| `timeZoneIdentifier` | `String?` | IANA id; `nil` = legacy / device current on read |
| `reminder` | `Date?` | Absolute fire date for local notifications |
| `repeatRuleRawValue` | `String` | Encoded `RepeatRule` (plain frequency or JSON v2 with interval / endDate / occurrenceCount) |
| `categoryRawValue` | `String` | `EventCategory` |
| `priorityRawValue` | `String` | `EventPriority` (`low`/`normal`/`high`/`urgent`; legacy `medium`/`critical` accepted) |
| `statusRawValue` | `String` | `EventStatus` |
| `colorRawValue` | `String` | `EventColor` (Design System palette only) |
| `tagsRawValue` | `String` | JSON `[EventTag]` (Schema V5; `[]` default) |
| `createdAt` | `Date` | Creation timestamp |
| `updatedAt` | `Date` | Last update timestamp |

## Relationships

None. Events are independent records.

## Persistence flow

1. ViewModels call `EventPersistenceService` (writes).
2. Service validates, writes through `EventRepository`, synchronizes reminders, then refreshes `EventCatalogService`.
3. UI observes the catalog via the persistence service mirror (`events` / `eventsRevision`).

## CloudKit readiness (not implemented)

- Prefer removing `@Attribute(.unique)` or using a CloudKit-compatible uniqueness strategy before enabling sync.
- Reminder identifiers are local (`UserNotifications`); remote devices need a reconcile strategy.
- Feature flag `cloudKitSync` exists in configuration but remains off.

## Universe Messages (Sprint 4.7)

Detail screen (`UniverseMessageDetailView` / `UniverseMessageDetailViewModel`) shows full message, date, category, favorite, and share. Opened via `fullScreenCover` from Home (card tap) and History (row content tap). Favorite mutations go through `UniverseMessageService`; day selection remains in `UniverseMessageEngine`.

## Calendar Experience (Sprint 5.8)

Epic closed. Navigation stack:

- Month step (chevrons / swipe intents) → ``CalendarGridViewModel.navigateMonth`` → ``showMonth``
- Month / year pickers → ``HomeViewModel.apply*PickerSelection`` (honors ``showMonth`` return; dismisses always)
- Go to Today → no-op when already on today
- Smart day selection → ``CalendarEngine.resolveSelectedDay`` / ``SmartDaySelection``

Observation contract: always touch ``EventPersistenceService.eventsRevision`` inside ``annotatedDays``; ``selectedDay`` / ``isShowingToday`` read ``baseDays`` only (no full grid rebuild). Same-period ``showMonth`` and same-ID ``selectDay`` skip unnecessary invalidations.

## Advanced Events — All Day (Sprint 6.1)

``Event.isAllDay`` / ``EventEntity.isAllDay`` (Schema V4, lightweight migration). Same-day all-day bounds via ``EventSchedule``. Editor toggle hides time pickers. ``DayEventsView`` lists all-day first in a separate section. Calendar grid indicators unchanged (still presence + color). Multi-day overlap queries deferred; ``Event.spansMultipleCalendarDays`` is the Sprint 6.2 hook.

## Advanced Events — Multi Day (Sprint 6.2)

``Event.startDate`` aliases persisted ``date``; ``Event.isMultiDay`` is derived from start/end calendar days (no new SwiftData field). ``EventSchedule.occurs`` / ``dayStarts`` + ``CalendarEngine.dayStarts`` drive catalog day queries and ``eventsGroupedByDay`` so the month grid shows indicators on every day of the span. Editor exposes start/end **date** pickers (end never before start). Recurrence occurrence expansion reuses these helpers via ``RecurrenceEngine`` / ``EventCatalogService``.

## Advanced Events — Recurrence (Sprint 6.3)

Canonical models live under `Domain/Models/Recurrence/` (`RecurrenceFrequency`, `RecurrenceEndRule`, `RecurrenceRule`, `EventOccurrence`). ``RecurrenceEngine`` expands masters into virtual occurrences (no SwiftData copies). ``RepeatRule`` remains the persisted bridge (`repeatRuleRawValue`, envelope v2 + `occurrenceCount`, `biweekly`); convert to the engine with ``RepeatRule/asRecurrenceRule``. ``EventCatalogService`` is the **read SSOT** for UI (grid, day list, search, agenda). Repository `fetch(on:)` / `fetch(in:)` filter only `entity.date` and must not be used for presentation queries.

## Advanced Events — Tags, Colors, Priorities (Sprint 6.4)

``Event.color`` / ``Event.priority`` / ``Event.tags`` organize events visually. Colors are Design System tokens only (`ColorPalette.color(for:)`). Priorities: low / normal / high / urgent. Tags: multi-select presets (+ ``EventTag.custom`` reserved). Schema V5 adds ``tagsRawValue``. Grid keeps color dots via ``CalendarEventIndicator`` (priority reserved for later). Combinable search / filters: see Sprint 6.7.

## Advanced Events — Templates (Sprint 6.5)

Offline blueprints via ``EventTemplate`` / ``EventTemplateEntity`` (Schema V6, lightweight migration). Content snapshot only: title, description/notes, color, tags, priority, duration, all-day, recurrence, status — **not** absolute date/time or reminder fire dates. ``EventTemplateService`` + ``EventTemplateRepository`` sit beside the event catalog (no reminder pipeline). UI: manage list, editor, picker; Day Events / Event Editor expose “Create from template” and “Save as template”.

### Entity: `EventTemplateEntity`

| Field | Type | Notes |
| --- | --- | --- |
| `id` | `UUID` | `@Attribute(.unique)` |
| `name` | `String` | Template list label |
| `title` | `String` | Event title snapshot |
| `eventDescription` | `String` | Notes / description |
| `isAllDay` | `Bool` | All-day flag |
| `durationSeconds` | `Double` | Timed length or all-day span hint |
| `repeatRuleRawValue` | `String` | Encoded `RepeatRule` |
| `categoryRawValue` | `String` | Legacy category |
| `tagsRawValue` | `String` | JSON tags |
| `priorityRawValue` | `String` | Priority |
| `statusRawValue` | `String` | Status |
| `colorRawValue` | `String` | Color token |
| `timeZoneIdentifier` | `String?` | Optional preference |
| `createdAt` / `updatedAt` | `Date` | Audit timestamps |

## Advanced Events — Quick Operations (Sprint 6.6)

No schema change. ``Event.duplicated(on:)`` resets status and recomputes relative reminders; ``Event.rescheduled(to:)`` keeps identity. ``EventPersistenceService`` exposes ``duplicate(_:onto:)``, ``move(_:to:)``, ``copy(_:to:)`` (resolve master before mutating so recurrence occurrences are not persisted as rows). Day list context menu: Edit / Duplicate / Move / Copy / Delete.

## Advanced Events — Smart Search (Sprint 6.7)

``EventSearchCriteria`` + single-pass ``EventCatalogService.events(matching:)`` (masters filtered before recurrence expansion). Text: title / description(notes) / tags. Facets: priority, color, category, all-day, multi-day, recurring, reminder, date / interval. ``EventSearchViewModel`` owns incremental query state; grid and day list honor ``calendarCriteria``. No Spotlight / AI / CloudKit.

## Advanced Events — Smart Daily Agenda (Sprint 6.8)

`AgendaTimelineBuilder` (Domain) builds day summary, free-time gaps (08:00–20:00), chronological timeline, and next event from `EventPersistenceService.events(on:)`. UI: `SmartAgendaView` + summary / timeline / free-time cards. Universe Message via existing `UniverseMessageEngine`. Agenda intentionally uses the full day catalog (does not apply active `EventSearchCriteria`; grid / day list do). No IA / widgets / CloudKit.

## Advanced Events — Production Hardening (Sprint 6.10)

Codecs and mappers throw on corrupt payloads (no silent invent-defaults). Persistence rollbacks are strict (store + reminder + catalog). Home single-event edit resolves the recurrence master. Domain owns agenda defaults (`AgendaTimelineBuilder.Defaults`).
