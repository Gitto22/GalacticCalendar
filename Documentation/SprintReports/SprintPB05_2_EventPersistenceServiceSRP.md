# Sprint PB-05.2 — Event Persistence SRP

**Fecha:** 2026-07-30  
**Rol:** Principal iOS Architect  
**Estado:** Implementado (API pública intacta; ViewModels / Repositories sin tocar).

---

## 1. Análisis previo — `EventPersistenceService`

| Responsabilidad | Clasificación | ¿Persistencia? | Decisión |
|-----------------|---------------|----------------|---------|
| Gate `storageAvailability` / `isWritable` | Persistencia (orquestación) | Sí | **Se queda** |
| CRUD + rollback atómico (persist → reminders → refresh) | Persistencia | Sí | **Se queda** |
| Validación pre-write vía `EventValidationService` | Validación (precondición) | Límite | **Se queda** (ya delegada; no es lógica propia) |
| Mirror Observation `events` / `eventsRevision` + queries sync | Sincronización del catálogo (fachada) | Fachada Application | **Se queda** (contrato VM; no nuevo servicio) |
| Sync / cancel / auth de recordatorios | Recordatorios | No | **Extraído** → `EventReminderCoordinator` |
| Math occurrence→master (`resolvedMasterStart`) | Dominio schedule | No | **Extraído** → `EventSchedule` |
| Quick ops `duplicate` / `move` / `copy` | Orquestación sobre persistencia | Sí (API) | **Se queda** (math fuera) |
| `PersistenceLog` en gate/recovery | Logging | Incidental | **Se queda** (no justifica servicio) |
| Mapeo errores → `EventPersistenceError` | Persistencia (boundary) | Sí | **Se queda** |

**Criterio de extracción:** solo lo que **claramente** no es persistencia. No se inventaron servicios extra.

---

## 2. Responsabilidades eliminadas (del cuerpo de EPS)

1. **Recordatorios** → `EventReminderCoordinator`  
   - `requestAuthorizationIfNeeded`  
   - `synchronize(for:)`  
   - `cancel(for:)`  
   - EPS conserva la misma API pública y el init `notificationService:` (fachada → coordinador).

2. **Schedule math** → `EventSchedule.resolvedMasterStart(master:presented:targetStart:)`  
   - `move(_:to:)` solo orquesta: resolve master → schedule → `update`.

---

## 3. Responsabilidades restantes

- Disponibilidad de store + `lastError`
- `refresh` + mirror Observation del catálogo
- Queries reactivas (`events(on:)`, `events(matching:)`, …)
- Pipeline **validate → persist → reminders → refresh** con rollback
- Quick mutations como orquestación
- Mapeo de errores repo / reminder

**Rol SRP práctico:** fachada Application de **mutación + publicación de catálogo**. No implementa math de fechas ni llama a `NotificationService` directamente.

---

## 4. Tamaño final del servicio

| Artefacto | Líneas (~) |
|-----------|------------|
| `EventPersistenceService.swift` (enum error + clase) | **~545** |
| `EventReminderCoordinator.swift` (extraído) | **~58** |
| Math en `EventSchedule.resolvedMasterStart` | Dominio (fuera de EPS) |

---

## 5. Restricciones

| Restricción | Cumplida |
|-------------|----------|
| Mantener API pública | Sí |
| No modificar ViewModels | Sí |
| No modificar Repositories | Sí |
| Mínimo de servicios nuevos | Sí (1: `EventReminderCoordinator`; math a tipo Domain existente) |
| Tests actualizados | Sí (`EventReminderCoordinatorTests`, `EventScheduleResolvedMasterStartTests`; existentes intactos por API) |

---

## 6. ¿Cumple SRP?

**Sí, a nivel Application façade — de forma deliberada.**

Una razón de cambio: **orquestar persistencia de eventos y publicar el catálogo reactivo**.  
Lo que no pertenecía (recordatorios + schedule math) quedó fuera.  
Validación y logging permanecen como precondiciones/telemetría del pipeline, no como lógica de negocio embebida.

Informe canónico: este documento.
