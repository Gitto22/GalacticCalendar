# Sprint PB-05.3 — Bootstrap Cleanup

**Fecha:** 2026-07-30  
**Estado:** Implementado (sin cambio de comportamiento).

---

## Análisis

| Método | Dónde (antes) | Intención real |
|--------|---------------|----------------|
| `bootstrap()` | `EventPersistenceService` | Alias idéntico a `refresh()` |
| `bootstrap()` + `refresh()` privado | `EventTemplateService` | Dos caminos de reload duplicados |
| `bootstrap()` | Home / Templates / Agenda ViewModels | Arranque de pantalla / orquestación |
| `load()` | Universe History / Detail VMs | Carga de UI |
| `loadInitial()` | `UniverseMessageViewModel` | Primer mensaje del día |
| `initialize()` | — | **No existía** en el código |

### Intención canónica elegida

| Capa | Método definitivo | Motivo |
|------|-------------------|--------|
| **Application services** | **`refresh()`** | Recargar SSOT desde repositorio (primera carga y post-mutación) |
| **Home launch** | `bootstrap()` | Orquesta varios servicios al arrancar (no es alias de servicio) |
| **Universe** | `load()` / `loadInitial()` | Carga de UI / mensaje diario (no son alias de persistencia) |

---

## Métodos eliminados

1. `EventPersistenceService.bootstrap()` — alias de `refresh()`
2. `EventTemplateService.bootstrap()` — duplicado; quedó un solo `refresh()` público

## Método definitivo (servicios)

**`refresh()`** en `EventPersistenceService` y `EventTemplateService`.

Conservados (no son alias de servicio):
- `HomeViewModel.bootstrap()` (+ `bootstrapCatalog` / `bootstrapTemplates` → delegan a `refresh()`)
- `EventTemplatesViewModel` / picker / `SmartAgendaViewModel.bootstrap()`
- Universe `load()` / `loadInitial()`

---

## Archivos modificados

| Área | Archivos |
|------|----------|
| Servicios | `EventPersistenceService.swift`, `EventTemplateService.swift` |
| ViewModels (call sites) | `HomeViewModel`, `EventTemplatesViewModel`, `EventTemplatePickerViewModel`, `SmartAgendaViewModel` |
| Previews / vistas | `CalendarContainerView`, `DayEventsView`, `CalendarGridView`, … |
| Tests | Atomicity, quick ops, templates, calendario, domain, revision bump, storage, etc. |
| Docs | Este informe; comentarios de API en servicios / Home |

---

## Resultado

Una sola API de recarga en Application services: **`refresh()`**.  
Sin alias servicio↔servicio. Comportamiento de carga idéntico.
