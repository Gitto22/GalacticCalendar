# Roadmap

Estado real del producto y de la estructura del repositorio (julio 2026). Los ítems “estructura only” existen como carpetas/stubs, no como features enviadas.

---

## FASE 1 — Foundation · Home · Calendar · Events · Beta Privada

### COMPLETADA

- Foundation + Composition Root + Design System base
- Home + calendario mensual (navegación, pickers, Today, swipe, indicadores)
- Eventos locales SwiftData (CRUD, all-day, multi-día, repeat/recurrence, reminders)
- Advanced Events: templates, quick ops, search, smart daily agenda, hardening
- Universe Messages: card, detalle, historial, favoritos
- Road to Private Beta: assets, safe persistence, Dynamic Type, VoiceOver, contraste, architecture cleanup, production readiness
- Quality gates QA-01…QA-07 (smoke UI, SwiftData integration, catalog resilience, VM audit, design system, navigation, DI)
- Certificación: 🟢 **Apto para Beta privada**

---

## FASE 2 — Settings · Universe+ · Productivity

### EN DESARROLLO

Alcance típico de esta fase (producto / estructura parcial; **no** cerrado):

| Área | Estado real en repo |
|------|---------------------|
| **Settings** | Sin módulo de pantalla; `SettingsRepository` scaffold |
| **Universe+** | Base enviada en FASE 1; pendientes reservados: share-as-image, categorías custom, sync/online/AI (no implementados) |
| **Productivity** | Agenda + search + templates ya en FASE 1; extensiones productivas adicionales aún no certificadas como fase cerrada |

Trabajo activo de calidad: documentación (QA-08), preparación de Beta pública / RC según `ReleaseProcess.md`.

---

## FASE 3 — Widgets · CloudKit · Apple Watch

### PLANIFICADA

| Área | Evidencia en repo | Producto |
|------|-------------------|----------|
| **Widgets** | `Widgets/` scaffold, `WidgetDataManager` stub, flags/constants | No shipping |
| **CloudKit** | `CloudKitManager` stub, flag `cloudKitSync` off, notas en DataModel | No shipping |
| **Apple Watch** | `WatchApp/README` reserva | No shipping |

También planificados / scaffold: EventKit, StoreKit 2, backups, statistics, themes adicionales, App Intents amplios.

---

## Fuera de fase (backlog explícito)

- Combined month+year picker, haptics de calendario
- Recurrence avanzada (weekdays, exclusions, RRULE custom)
- Invitations / shared calendars
- Universe widgets / CloudKit sync / share image

Detalle histórico: sprint reports en `Documentation/SprintReports/`.
