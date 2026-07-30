# Sprint 6.9 — Hardening Final · Revisión arquitectónica

**Fecha:** 2026-07-30  
**Alcance:** Módulo Advanced Events (Sprints 6.1–6.8)  
**Modo:** Solo auditoría — **sin cambios de código** en este entregable.

---

## Veredicto

### 🟡 APTO CON CAMBIOS

El módulo es **funcionalmente completo en diseño** (all-day, multi-día, recurrencia, organización, plantillas, ops rápidas, búsqueda, agenda) y la arquitectura Clean + MVVM + Observation es **mayormente coherente**.  
**No** se declara cerrado para producción hasta corregir un **bloqueo de compilación**, alinear lectura repo vs catálogo, cerrar huecos de tests de presentación y un puñado de inconsistencias de producto (ocurrencias, búsqueda ↔ agenda, a11y del editor).

---

## 1. Arquitectura

### Cumple
- Capas claras: Domain (Foundation), Data (SwiftData + mappers), Application (façades), Presentation (MVVM + Observation).
- Composition Root (`DependencyContainer` / `ViewModelFactory`) inyecta persistencia, plantillas y notificaciones.
- Lectura UI vía `EventCatalogService` (expansión de recurrencia + multi-día); escritura vía `EventPersistenceService` (validación → repo → reminders → refresh).
- Plantillas en stack paralelo (sin pipeline de recordatorios) — decisión correcta.
- Búsqueda sin `EventSearchService` (criteria Domain + catálogo) — alineado con SRP.
- Agenda con `AgendaTimelineBuilder` en Domain — correcto.

### Deuda / desviaciones
| Severidad | Hallazgo |
|-----------|----------|
| **Crítica** | `RecurrenceEngine` llama `event.repeatRule.asRecurrenceRule()` (método); es **propiedad** `var asRecurrenceRule` → **error de compilación** |
| Alta | `EventRepository.fetch(on/in:)` filtra solo `entity.date` — sin multi-día ni recurrencia; peligroso si alguien lo usa fuera del catálogo |
| Media | Domain → `CalendarConstants` (Config) desde `AgendaTimelineBuilder` — fuga de pureza |
| Media | Dualidad `RepeatRule` ↔ `RecurrenceRule` + codecs de persistencia en Domain |
| Media | `EventPersistenceService` concentra validación + CRUD + reminders + rollback + mirror de queries |
| Baja | `Domain/UseCases/Events/` vacío; casos de uso viven como Application services |
| Baja | Presets de editor / `EventReminderOption` en Domain (olor a Presentation) |

### DI
- Bien: `EventPersistenceService`, `EventTemplateService`, `NotificationService`, `UniverseMessageEngine`.
- Internos (aceptable): `EventCatalogService`, `RecurrenceEngine`, `EventValidationService` por defecto.
- No exponer catálogo al environment no es un defecto; complica solo tests aislados.

---

## 2. Calidad del código

### Fortalezas
- Sin `TODO` / `FIXME` / `try!` / `fatalError` en rutas Events de Presentation/Tests.
- Mappers Domain ↔ Entity consistentes; Schema V1→V6 con migraciones ligeras documentadas.
- Observación reactiva con `eventsRevision` / `templatesRevision` en DayEvents, Grid, Search, Agenda, Templates.
- Ops rápidas y plantillas respetan master vs ocurrencia en DayEvents/Agenda (resolver por id).

### Problemas
| Área | Detalle |
|------|---------|
| ViewModels grandes | `EventEditorViewModel` ~678 líneas; `HomeViewModel` ~414 (orquestación modal densa) |
| UI duplicada | Filas evento reinventadas en Search / Agenda vs `EventRow` |
| Inconsistencia producto | Agenda **no** aplica `EventSearchCriteria`; DayEvents/Grid sí |
| Home 1 evento | `presentEventEditorForEditing` **no** resuelve master (riesgo editar fechas de ocurrencia) |
| Search | `onSelectEvent` no cableado desde Home; `appliesToCalendar` sin UI |
| QuickSchedule | `isSaving` puede quedar en `true` si falla la mutación |
| Código muerto | `MainCalendarViewModel` scaffold; `CalendarDayCellState.withGift` |
| Doc drift | `DataModel.md` §6.4 aún dice “Filters/search not implemented” pese a 6.7 |

### SOLID / SRP (resumen)
- **S:** catálogo / validación / notificaciones / agenda builder bien separados en intención.
- **O/D:** protocolos de repo + in-memory tests.
- **I:** `EventRepositoryProtocol` hinchado (queries que la UI no usa).
- **SRP presión:** Persistence façade + Editor VM + Home VM.

---

## 3. Rendimiento

| Aspecto | Evaluación |
|---------|------------|
| Catálogo en memoria | Adecuado offline; `replaceAll` + sort en cada mutación — OK a escala personal |
| Búsqueda | Un pase `filter` sobre masters; fechas expanden solo candidatos — bien |
| Grid | `annotatedDays` regenera agrupación al observar; `presentedDays` remapea — coste O(días×eventos) aceptable en mes |
| Day list | `allDayEvents` + `timedEvents` recalculan `events` dos veces por body — micro-optimizable |
| Agenda | Snapshot derivado por acceso; merge de intervalos O(n log n) — bien |
| Repo | Sin índices SwiftData; queries por `date` incompletas — no usar como SSOT de lectura |
| Observation | Hooks de search a veces redundantes pero correctos |

**Conclusión rendimiento:** suficiente para producción local; no hay cuellos graves documentados. Evitar crecer el catálogo sin paginación/índices si el usuario acumula miles de masters.

---

## 4. Seguridad / integridad de datos

| Riesgo | Detalle |
|--------|---------|
| Contenedor | Fallo de disco → fallback in-memory + `storeUnavailable` (efímero) — UX debe seguir avisando |
| Abort | `preconditionFailure` si disk+memory fallan — aceptable en App |
| Rollback | Catch “best-effort” en cancel reminder / refresh tras rollback — puede dejar reminder huérfano en edge cases |
| Codecs | `EventTagCodec` / `RepeatRule` decode con fallback silencioso → posible pérdida semántica en filas corruptas |
| Templates bootstrap | `try?` en Home — fallo silencioso de plantillas |
| CloudKit | `@Attribute(.unique)` documentado como riesgo futuro — **no implementar sync ahora** |
| Auth notificaciones | Pipeline denegado hace rollback de create — correcto |

No se encontraron `try!` en el módulo Events. Errores silenciosos son el principal olor (no crashes).

---

## 5. Cobertura de tests

### Bien cubierto
All-day, multi-día, recurrencia/RepeatRule, organización (tags/prioridad/color), búsqueda (criteria + smoke VM), quick ops, plantillas (service), agenda builder, atomicidad persistencia, validación, mapper, revision catalog.

### Huecos relevantes (añadir solo si se endurece el cierre)
| Gap | Prioridad |
|-----|-----------|
| Compilar/ejecutar suite tras fix `asRecurrenceRule` | Crítica |
| `HomeViewModel.selectDay` (0/1/2+) + master resolve | Alta |
| `DayEventsViewModel` quick schedule / nested flows | Media |
| VMs Templates / Search facets | Media |
| Integración search → grid annotations | Baja |

No se recomienda una explosión de tests de UI/snapshot para este cierre; sí tests de routing Home y del fix de recurrencia.

---

## 6. Accesibilidad

| Cumple | Gap |
|--------|-----|
| Labels en filas DayEvents, resumen Agenda, free-time, muchos botones close/nav | Editor **sin ScrollView** → riesgo Dynamic Type / pantallas pequeñas |
| Reduce Motion en grid/header | Colores con `rawValue` en VO (Search/Editor) |
| `minimumScaleFactor` en títulos | Filas Search/Agenda más pobres que `EventRow` |
| Day cell combina conteo de eventos | Menú Home genérico (History+Search+Agenda) sin hint de acciones |
| | Contraste glass/cosmic no medido (WCAG) |

---

## 7. Preparación para producción (local / offline)

### Checklist mínimo antes de “cerrado”
1. **Corregir** `asRecurrenceRule()` → propiedad (y verificar build + `RecurrenceEngineTests`).
2. **Resolver master** en edición Home (igual que DayEvents/Agenda).
3. **Documentar** que el SSOT de lectura es el catálogo; no usar repo day/interval para UI.
4. Actualizar frase obsoleta en `DataModel.md` §6.4.
5. Scroll en `EventEditorView` + reset `isSaving` en QuickSchedule.
6. Decisión producto: Agenda respeta filtros de búsqueda o se documenta la excepción.
7. Smoke manual: crear/editar/borrar, all-day, multi-día, serie recurrente, plantilla, move/copy, search, agenda, recordatorio auth denied.

### Fuera de alcance (correcto no implementar)
CloudKit · Widgets · IA · Sincronización · Spotlight.

---

## 8. Nota del módulo

Advanced Events (6.1–6.8) entrega un **calendario personal offline serio**: organización visual, recurrencia expandida, plantillas, operaciones rápidas, búsqueda combinable y agenda diaria con tiempo libre. La base Clean Architecture + Observation es sólida y el Composition Root está ordenado.

La deuda no es “falta de features”, sino **endurecimiento**: un bug de API que impide confiar en el build, asimetrías de presentación, ViewModels densos y tests de orquestación incompletos. Con un sprint corto de fixes puntuales (sin nuevas features) el módulo puede pasar a **cerrado**.

---

## 9. Respuesta única

### 🟡 APTO CON CAMBIOS
