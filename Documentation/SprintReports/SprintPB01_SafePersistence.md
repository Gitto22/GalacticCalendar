# Sprint PB-01 — Safe Persistence

**Fecha:** 2026-07-30  
**Equivalencia:** Cumple el mismo P0 que Sprint P0.2 (sin fallback in-memory de uso normal).  
**UI:** Solo el alert de error existente (`lastError` / `storeUnavailable`); sin banner nuevo.

---

## PASO 1 — Análisis

| Nombre en el brief | Pieza real en el repo |
|--------------------|------------------------|
| DependencyContainer | `App/CompositionRoot/DependencyContainer.swift` |
| SwiftDataContainer | `Data/Database/SwiftData/ModelContainerFactory.swift` |
| Persistence | `Application/Services/EventPersistenceService.swift` |
| RepositoryFactory | **No existe** — wiring en Composition Root |
| EventPersistenceService | Façade Application de writes + catalog |

## PASO 2 — Fallback localizado (antes)

```
disk ModelContainer fail
  → ModelContainerFactory.make(inMemory: true)   // PELIGRO
  → persistenceLaunchError = storeUnavailable
  → Home alert dismissable via clearLastError()  // usuario sigue escribiendo en RAM
```

## PASO 3 — Arquitectura actual

- Fallo de disco → `modelContainer = nil` (sin store temporal de uso normal).
- `storageAvailability`: `available` | `unavailable` | `recovering`.
- Writes gated con `ensureWritable()` → `EventPersistenceError.storeUnavailable`.
- Repos `Unavailable*` para lecturas vacías seguras.
- Error al usuario vía `lastError` + alert existente; `clearLastError` **no** borra `storeUnavailable`.
- Log: `PersistenceLog` (`os.Logger`).

## PASO 4 — Tests

`Tests/UnitTests/Application/StorageAvailabilityTests.swift`
- fallo / modo unavailable  
- bloqueo create/update/delete/duplicate  
- recovery (`recovering` → `available`)  
- propagación Home + no-clear  

---

## Informe final

### Archivos relevantes
DependencyContainer, GalacticCalendarApp, EventPersistenceService, EventTemplateService, UniverseMessageService, StorageAvailability, PersistenceLog, Unavailable* repositories, HomeViewModel/HomeView (alert only), StorageAvailabilityTests, localizations `event_error_store_unavailable`.

### Riesgos eliminados
| Riesgo | Resultado |
|--------|-----------|
| Escritura en store in-memory creyendo disco | Eliminado |
| Error dismissable que re-habilita writes | Eliminado |
| Fallback silencioso | Eliminado |

### Confirmación P0

**Sí — el P0 “Store fallback” queda resuelto.**
