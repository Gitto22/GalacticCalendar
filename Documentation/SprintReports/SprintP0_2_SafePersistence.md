# Sprint P0.2 — Safe Persistence

**Fecha:** 2026-07-30  
**Objetivo:** Eliminar el riesgo P0 de pérdida de datos por fallback in-memory silencioso  
**Sin:** CloudKit · Backup · Recovery automático · nuevas features de producto

---

## Análisis (pre-implementación)

| Pieza auditada | Realidad en el repo |
|----------------|---------------------|
| PersistenceFacade / RepositoryFactory | **No existen** — roles cubiertos por `DependencyContainer` + `EventPersistenceService` + `ModelContainerFactory` |
| Fallback anterior | Disco falla → `ModelContainerFactory.make(inMemory: true)` + alerta dismissable (`clearLastError`) |
| Logging | No había façade; se introduce `PersistenceLog` (`os.Logger`) |

---

## Flujo de error (nuevo)

```
App launch
  └─ ModelContainerFactory.make(disk)
        ├─ OK → storageAvailability = .available
        │         modelContainer attached
        │         repos SwiftData reales
        └─ FAIL → PersistenceLog.storeOpenFailed
                  storageAvailability = .unavailable
                  modelContainer = nil (sin store efímero de uso normal)
                  Unavailable*Repository (lecturas vacías; writes throw)
                  EventPersistenceService.isWritable = false
                  Home: banner persistente + alert que NO limpia storeUnavailable
                  create/update/delete/duplicate/move/copy → storeUnavailable
```

Estados: `available` | `unavailable` | `recovering` (writes bloqueados salvo `available`).

---

## Archivos modificados / añadidos

**Nuevos**
- `Application/Services/StorageAvailability.swift`
- `Application/Services/PersistenceLog.swift`
- `Data/Repositories/UnavailableEventRepository.swift`
- `Data/Repositories/UnavailableEventTemplateRepository.swift`
- `Data/Repositories/UnavailableUniverseMessageRepository.swift`
- `Tests/UnitTests/Application/StorageAvailabilityTests.swift`
- `Documentation/SprintReports/SprintP0_2_SafePersistence.md`

**Actualizados**
- `App/CompositionRoot/DependencyContainer.swift`
- `App/GalacticCalendarApp.swift`
- `Application/Services/EventPersistenceService.swift`
- `Application/Services/EventTemplateService.swift`
- `Application/Services/Universe/UniverseMessageService.swift`
- `Presentation/ViewModels/Home/HomeViewModel.swift`
- `Presentation/Views/Home/HomeView.swift`
- `Presentation/ViewModels/Events/DayEventsViewModel.swift`
- `Presentation/ViewModels/Agenda/SmartAgendaViewModel.swift`
- `Resources/Localization/en.lproj/Localizable.strings`
- `Resources/Localization/es.lproj/Localizable.strings`

---

## Riesgos eliminados

| Riesgo | Estado |
|--------|--------|
| Usuario escribe en store in-memory creyendo que es disco | **Eliminado** — no hay fallback in-memory de uso normal |
| Alert dismissable que “limpia” el error y permite seguir | **Eliminado** — `clearLastError` no borra `storeUnavailable`; banner permanente |
| Writes silenciosos / best-effort | **Bloqueados** en Persistence / Templates / Universe favorites |
| `preconditionFailure` tras fallar memoria | **N/A** — ya no se intenta memoria como plan B |

---

## Cobertura de tests

`StorageAvailabilityTests`:
1. Fallo / modo unavailable → create lanza `storeUnavailable`; refresh vacío seguro  
2. Update / delete / duplicate bloqueados  
3. `recovering` → bloquea; `available` → re-habilita writes  
4. Home propaga error y no lo limpia; `selectDay` 0 eventos no abre editor  
5. `DependencyContainer.applyStorageAvailability` refleja el gate  

---

## Confirmación P0

### ✅ P0 “Store fallback” queda **completamente resuelto**

No se crea almacenamiento temporal para uso normal. Las escrituras están bloqueadas y el usuario ve un mensaje claro mientras el store no esté disponible.
