# Sprint QA-02 — SwiftData Integration Tests

**Fecha:** 2026-07-30  
**Rol:** Senior iOS QA Engineer  
**Alcance:** Solo Integration Tests (no unit, no UI). Sin cambios de arquitectura / ViewModels / UI.

---

## Tests añadidos

| Caso | Tests |
|------|--------|
| **1. Store** | `testTemporaryInMemoryStoreInitializes`, `testTemporaryOnDiskStoreInitializes`, `testProductionFactoryInMemoryOpens` |
| **2. CRUD** | `testCreateReadUpdateDeleteEvent` |
| **3. Persistencia** | `testEventSurvivesStoreCloseAndReopen`, `testTemplateSurvivesStoreCloseAndReopen` |
| **4. Templates** | `testTemplateCreateEditDelete`, `testCreateEventFromTemplatePersistsExpectedFields` |
| **5. Catálogo** | `testRefreshPublishesCatalogAndAdvancesRevision`, `testCreateThroughPersistenceUpdatesCatalogCoherently` |
| **6. Errores** | `testUnavailableStoreBlocksWritesAndExposesStoreUnavailable`, `testUnavailableRepositoryWriteFails`, `testUnavailableTemplateRepositoryWriteFails`, `testCorruptSingleRowReadFailsWhileCatalogLoadContinues` |

**Nota `bootstrap()`:** eliminado en PB-05.3. La API canónica de recarga es **`refresh()`** (`EventPersistenceService` / `EventTemplateService`). Los tests validan coherencia vía `refresh()` + mutaciones de la fachada.

Harness: `SwiftDataIntegrationHarness` (in-memory + on-disk temp + corrupt fixtures + `makeEvent(from:)`).

---

## Cobertura funcional

| Área | Cubierto |
|------|----------|
| `ModelContainer` / schema producción | Sí |
| `EventRepository` CRUD | Sí |
| Persistencia on-disk reopen | Sí |
| `EventTemplateRepository` CRUD | Sí |
| Evento materializado desde plantilla | Sí (Domain `scheduleBounds`, sin ViewModel) |
| `EventPersistenceService` + catálogo | Sí (`refresh`, create/delete façade) |
| Store unavailable / writes blocked | Sí |
| Lectura corrupt vs catálogo | Sí |

No cubre: CloudKit, migraciones legacy on-device, Universe seed (fuera de este sprint).

---

## Riesgos detectados

| Riesgo | Nota |
|--------|------|
| Reopen on-disk depende de release del primer `ModelContainer` | Tests nil-ean el container antes de reopen; en CI vigilar file locks |
| `Unavailable*` simula open/write fallidos, no un SQLite corrupto real | Suficiente para contrato Application de Private Beta |
| Mutación directa al repo no publica catálogo | Documentado; `refresh()` / façade `create` sí publican |
| Duplicación residual con tests QA-03 de corrupción | Suite corrupción se mantiene como puente; errores QA-02 incluyen el caso lectura |

---

## Preparación para QA-03

QA-03 (Catalog Resilience) formaliza **nunca cancelar** la carga ante filas corruptas (`CatalogResilientDecoder`).

Tras QA-02:

1. Ejecutar esta suite + `CatalogResilienceTests` / corrupción integration.
2. Cualquier nuevo `fetchAll` de catálogo debe usar el decoder resiliente.
3. No añadir invento de valores en mappers; skip + log únicamente.

---

## Restricciones cumplidas

Arquitectura · ViewModels · UI: **sin modificar**.  
Reutilizado: `ModelContainerFactory`, repos reales, `EventPersistenceService`, `Unavailable*Repository`, schema V6.
