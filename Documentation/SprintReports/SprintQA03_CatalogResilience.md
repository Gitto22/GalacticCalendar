# Sprint QA-03 — Resilient Event Catalog

**Fecha:** 2026-07-30  
**Roles:** Principal iOS Architect · Senior QA Engineer  
**Restricciones:** Sin cambio de arquitectura / ViewModels / UI. Repos solo en el punto de decode de listados.

---

## Análisis previo (antes de tocar código)

| Componente | Rol | Hallazgo |
|------------|-----|----------|
| `EventCatalogService` | SSOT in-memory + expansión | Correcto que **no** decode entidades; recibe masters ya válidos vía `replaceAll` |
| `EventRepository.fetchAll` / `fetch(in:)` | I/O SwiftData → Domain | Punto correcto para aislar corrupción (SRP: catalog service no hace I/O) |
| `EventEntityMapper.makeDomain` | Decode estricto | Lanza `corruptData` / codec errors — **no inventa** valores |
| `EventPersistenceService.refresh` | fetchAll → `catalog.replaceAll` → publish | Fallaba el catálogo entero solo si `fetchAll` lanzaba; tras decoder, ya no |
| `PersistenceLog` | Telemetría | `corruptEntitySkipped(entityType:id:error:)` — errores **no ocultos** |
| `CatalogResilientDecoder` | Helper Data (QA-03 previo) | Contrato: log → isolate → continue → never abort list load |

**Decisión:** Mantener decode resiliente en el repositorio (imprescindible). No mover lógica a ViewModels ni al `EventCatalogService` (evitar contaminar SRP).

---

## Implementación (estado)

Flujo de carga:

```
SwiftData EventEntity[]
    → CatalogResilientDecoder.decodeAll + EventEntityMapper.makeDomain
         ├─ OK  → Event
         └─ catch → PersistenceLog.corruptEntitySkipped → skip
    → [Event] healthy only
    → EventPersistenceService.refresh → EventCatalogService.replaceAll
```

| Requisito | Cumplido |
|-----------|----------|
| Registrar error | Sí (`PersistenceLog`) |
| Aislar solo esa entidad | Sí (skip; fila on-disk intacta) |
| Continuar carga | Sí |
| Actualizar catálogo | Sí (`replaceAll` + revision) |
| No ocultar errores | Sí (log con error) |
| No tumbar catálogo por 1 fila | **Sí** |

---

## Archivos modificados / relevantes

| Archivo | Cambio |
|---------|--------|
| `Data/Database/CatalogResilientDecoder.swift` | Contrato resiliente (existente, canónico) |
| `Data/Repositories/EventRepository.swift` | `fetchAll` / `fetch(in:)` vía decoder |
| `Data/Repositories/EventTemplateRepository.swift` | Mismo patrón en `fetchAll` |
| `Application/Services/PersistenceLog.swift` | Log con error |
| `Application/Services/EventCatalogService.swift` | Doc: no ownership de corrupción |
| `Application/Services/EventPersistenceService.swift` | Doc: refresh no falla por fila corrupt |
| `Tests/UnitTests/Data/CatalogResilienceTests.swift` | Decoder unitario |
| `Tests/IntegrationTests/Database/ResilientEventCatalogIntegrationTests.swift` | **Matriz integration QA-03** |
| ~~`SwiftDataCatalogCorruptionIntegrationTests.swift`~~ | Eliminado (duplicado → matriz unificada) |

ViewModels / UI / modelo SwiftData: **sin cambios**.

---

## Riesgos eliminados

| Antes | Ahora |
|-------|--------|
| Una fila corrupt → `fetchAll` lanza → `refresh` → `catalogLoadFailed` → UI sin eventos | Fila aislada + log; catálogo publica el resto |
| Mezcla válida/inválida indetectable o todo-o-nada | Skip selectivo; healthy visibles |
| Catálogo “all corrupt” = error de carga | Catálogo vacío válido + revision avanzado + log de cada fila |

---

## Cobertura alcanzada (integration)

| Escenario | Test |
|-----------|------|
| Catálogo vacío | `testEmptyCatalogRefreshSucceeds` |
| Completamente válido | `testFullyValidCatalogLoadsAllEvents` |
| Una entidad corrupta | `testSingleCorruptEntityIsIsolatedAndCatalogUpdates` |
| Varias corruptas | `testMultipleCorruptEntitiesDoNotAbortCatalogLoad` |
| Mezcla válida + inválida | `testMixedValidAndInvalidEntitiesLoadOnlyValid` |
| Todas corruptas | `testAllCorruptCatalogRefreshYieldsEmptyWithoutFailing` |

Unit decoder: `CatalogResilienceTests` (orden, isolate mid-list, all-corrupt, empty).

---

## Confirmación

**El Event Catalog ya no puede caer por una única entidad corrupta.**  
`refresh()` publica masters healthy; errores quedan en `PersistenceLog`; `fetch(by:)` de una fila concreta sigue reportando `corruptData` (no es carga de catálogo).

---

## SOLID / complejidad

- **SRP:** decode/aislamiento en Data; catálogo solo publica; log en Persistence.
- **OCP:** `CatalogResilientDecoder` genérico reutilizable (events/templates).
- **Rendimiento:** O(n) una pasada; `reserveCapacity`; sin I/O extra.
- **Duplicación:** suite corruption QA-02 absorbida en esta matriz.

---

## Preparación para QA-04

Candidatos naturales (Road to 9.5):

1. ViewModel unit tests pendientes (Agenda / Search / Templates / DayEvents).
2. Surface opcional de `skippedCount` en telemetría in-app (sin UX nueva obligatoria).
3. Smoke UI (QA-01) post-corrupción: Launch + CRUD tras seed mixto.
4. Documentar runbook: cómo inspeccionar logs de `corruptEntitySkipped` en dispositivo.
