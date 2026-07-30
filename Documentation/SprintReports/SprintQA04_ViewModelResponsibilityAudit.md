# Sprint QA-04 — ViewModel Responsibility Audit

**Fecha:** 2026-07-30  
**Rol:** Principal iOS Architect  
**Alcance:** Auditoría profunda. Sin cambios de código en este sprint.  
**Restricciones:** No UX · no rediseño arquitectónico · no ViewModels nuevos sin justificación · no dividir solo por tamaño.

---

## Criterio de decisión

Se recomienda extracción **solo** si el beneficio es demostrable (consistencia / testabilidad / riesgo de regresión reducible) **y** no es merament “archivo grande”.

En Private Beta, un ViewModel que **coordina sheets de una pantalla** es un patrón MVVM/SwiftUI aceptable. Dividirlo en coordinadores sin cambio de contrato aumenta superficie y riesgo sin valor de usuario.

---

## 1. `HomeViewModel` (~520 líneas)

| Pregunta | Respuesta |
|----------|-----------|
| **Responsabilidad principal** | Coordinador de la pantalla Home: bootstrap, day-tap routing, sync mes ↔ apariencia, ownership de sheets hijas. |
| **Secundarias** | Bootstrap catálogo/templates; routing 0/1/2+ eventos; nav mes/pickers/today; Universe/Search/Agenda presentation; error de store. |
| **¿SRP?** | **Parcial** — varias destinos de presentación, una sola “pantalla Home”. |
| **¿Acoplado?** | Sí, a muchos child VMs + `EventPersistenceService` + appearance/grid por parámetro. Acoplamiento de **orquestación**, no de Data. |
| **¿Application?** | Política `selectDay` y `resolveMasterSnapshot` podrían ser use-case compartido (hoy estable y local). |
| **¿Services?** | Ya delega persistencia/templates. Poco más que mover. |
| **¿Navegación?** | **Sí, intensa** (`isPresenting*` × 8). |
| **¿Estado?** | Sí — flags UI + `selectedDate` + `lastError`. |

**Extracción ahora:** No. Un `HomePresentationCoordinator` solo reetiqueta el mismo grafo.

---

## 2. `EventEditorViewModel` (~798 líneas)

| Pregunta | Respuesta |
|----------|-----------|
| **Principal** | Formulario create/edit: campos, draft → `Event`, validación, persistencia. |
| **Secundarias** | Side-effects de schedule (all-day/timed); composición recurrence UI; tags↔category; templates save/picker; auth notificaciones. |
| **¿SRP?** | **Parcial** — un feature “editor”, varios ejes de cambio (schedule / CRUD / templates). |
| **¿Acoplado?** | A `EventPersistenceService`, `EventValidationService`, template service opcional. Correcto. |
| **¿Application?** | `makeDraftEvent` / recurrence compose / all-day policy → candidato a `EventDraftComposer` **post-beta**. |
| **¿Services?** | Validate/CRUD ya en services. |
| **¿Navegación?** | Ligera (template picker). |
| **¿Estado?** | Form state + feedback async — apropiado. |

**Extracción ahora:** No. Composer aporta testabilidad, no valor Private Beta; riesgo de drift de schedule/UX.

---

## 3. `DayEventsViewModel` (~367 líneas)

| Pregunta | Respuesta |
|----------|-----------|
| **Principal** | Lista de eventos del día + filtros via search binding. |
| **Secundarias** | Editor / template picker / templates manager / quick schedule; CRUD wrappers; master resolve. |
| **¿SRP?** | **No estricto** — lista + hub de 4 sheets. |
| **¿Acoplado?** | Persistence + templates + search + 3 child VMs. |
| **¿Application?** | `resolveMasterSnapshot` duplicado (Home/Agenda). |
| **¿Services?** | Mutaciones ya en persistence. |
| **¿Navegación?** | **Sí, pesada.** |
| **¿Estado?** | `date`, secciones, quick-schedule draft, errors. |

**Extracción ahora:** No obligatoria. Peor SRP del set, pero sheets están acotadas a esta pantalla; coordinador sin cambio de producto = refactor cosmético.

---

## 4. `SmartAgendaViewModel` (~225 líneas)

| Pregunta | Respuesta |
|----------|-----------|
| **Principal** | Snapshot de agenda del día (`AgendaTimelineBuilder`) + Universe del día. |
| **Secundarias** | Paginación de día; formateo localizado; editor embebido. |
| **¿SRP?** | **Parcial.** |
| **¿Acoplado?** | Persistence + Universe engine + builder Domain — sano. |
| **¿Application?** | Timeline ya en Domain. |
| **¿Services?** | No pendiente. |
| **¿Navegación?** | Day paging + 1 editor. |
| **¿Estado?** | `day` + derivados — bueno. |

**Extracción ahora:** No. Formateadores a helpers Presentation = nice-to-have.

---

## 5. `EventSearchViewModel` (~166 líneas)

| Pregunta | Respuesta |
|----------|-----------|
| **Principal** | Estado de criterios de búsqueda/filtro y `results` derivados. |
| **Secundarias** | Toggles de facetas; quick range; `calendarCriteria`. |
| **¿SRP?** | **Sí.** |
| **¿Acoplado?** | Solo lectura a persistence + Domain criteria. |
| **¿Application/Services?** | No. |
| **¿Navegación?** | No (Home presenta el sheet). |
| **¿Estado?** | Solo estado de query — ideal. |

**Extracción:** Ninguna.

---

## 6. Templates (`EventTemplatesViewModel` / `EventTemplateEditorViewModel` / `EventTemplatePickerViewModel`)

No existe `TemplatesViewModel` único; el stack son **tres** VMs cohesivos.

| VM | Principal | SRP | Nav | Extracción |
|----|-----------|-----|-----|------------|
| **List** (~120) | Gestión CRUD lista + editor sheet | Parcial | Editor | No |
| **Editor** (~186) | Formulario plantilla | **Sí** | No | Validation service opcional post-beta |
| **Picker** (~81) | Elegir plantilla + abrir manager | Parcial | Manager | No |

Acoplamiento solo a `EventTemplateService`. Duplicación menor `bootstrap`/`errorAlertMessage` list↔picker — no justifica tipos nuevos.

---

## Resumen comparativo

| ViewModel | SRP | Nav | ¿Problema bloqueante? |
|-----------|-----|-----|------------------------|
| Home | Parcial | Alta | No — coordinador de pantalla |
| EventEditor | Parcial | Baja | No — fat form intencional |
| DayEvents | No estricto | Alta | No — hub de sheets acotado |
| SmartAgenda | Parcial | Media | No |
| EventSearch | Sí | No | No |
| Templates (×3) | Sí / parcial | Baja | No |

### Duplicación real (no crítica)

`resolveMasterSnapshot` / equivalente en Home · DayEvents · SmartAgenda.  
**Beneficio de unificar:** bajo-medio (consistencia). **Coste ahora:** toca tres call sites + posible tipo Application → cambio arquitectónico ligero sin UX.

### Lo que NO se recomienda

- Dividir Home/Editor/DayEvents “porque son largos”.
- Nuevos ViewModels espejo.
- Coordinators que solo mueven `isPresenting*` sin simplificar contratos.

---

## Backlog opcional (post–Private Beta, no este gate)

1. `EventMasterResolver` (Application) — unificar master snapshot.  
2. `EventDraftComposer` — extraer composición schedule/recurrence del editor.  
3. `DayEventsFlowCoordinator` — si el hub de sheets sigue creciendo.

Ninguno es necesario para mantener calidad / nota Road to 9.5 en el estado actual.

---

## Veredicto del Quality Gate

# NO CAMBIOS NECESARIOS

Los ViewModels cumplen su rol de **estado + orquestación de pantalla**. La lógica de negocio pesada ya está en Domain/Application (`EventPersistenceService`, `EventValidationService`, `AgendaTimelineBuilder`, `EventSchedule`). Extraer coordinadores ahora no aporta beneficio demostrable de producto y sí riesgo de regresión sin cambio de UX.
