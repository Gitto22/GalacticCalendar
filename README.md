# Galactic Calendar

Professional calendar application for iPhone, iPad, and macOS.

## Stack

Swift 6 · SwiftUI · SwiftData · UserNotifications  
(CloudKit · WidgetKit · StoreKit 2 · App Intents — scaffolded, **not** enabled)

## Architecture

Clean Architecture + MVVM. See `Documentation/Architecture.md`.

## Private Beta status (PB-06)

**In scope for Private Beta:** local calendar, events (templates, search, agenda, recurrence expansion), Universe Messages, VoiceOver, Dynamic Type, contrast scrims, safe persistence.

**Out of scope (explicitly not shipping):** CloudKit · Widgets · Apple Watch.

See `Documentation/SprintReports/SprintPB06_ProductionReadiness.md` for blockers and risks.

## Product docs

| Doc | Path |
|-----|------|
| Privacy | `Legal/PrivacyPolicy.md` |
| Terms | `Legal/TermsOfUse.md` |
| ASC copy | `Marketing/AppStore/` |
| Info / Privacy Manifest | `Resources/ConfigFiles/` |

## Localization

`en` + `es` — full key parity (`Resources/Localization/`).

## Notes

- Bundle ID fallback: `com.albancal.GalacticCalendar` (`AppConstants`).  
- Open / sign the Xcode project from your local workspace (project file may live outside this git tree).  
- Ensure `PrivacyInfo.xcprivacy` is a member of the app target before archive.
