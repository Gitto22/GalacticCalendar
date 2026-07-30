# Sprint PB-05.4 — Repeat vs Recurrence

**Fecha:** 2026-07-30  
**Rol:** Principal iOS Architect  
**Alcance:** Análisis arquitectónico únicamente. **Sin modificación de código.**

---

## Mapa del dual stack (estado actual)

```
Presentation          Domain (producto)           Domain / Application (motor)
─────────────         ─────────────────           ────────────────────────────
RecurrenceEndKind  →  RepeatRule               →  RecurrenceRule
(editor UI)           RepeatFrequency             RecurrenceFrequency
                      (Event / EventTemplate)     RecurrenceEndRule
                      repeatRuleRawValue          RecurrenceEngine
                      encode/decode               EventOccurrence
                              │
                              └── asRecurrenceRule ──┘
```

| Tipo | Capa | Rol |
|------|------|-----|
| `RepeatRule` / `RepeatFrequency` | Domain · persistencia / producto | Dato almacenado en `Event` / templates; codec SwiftData (`repeatRuleRawValue`); presets de editor |
| `RecurrenceRule` / `RecurrenceFrequency` / `RecurrenceEndRule` | Domain · cálculo | Entrada canónica de `RecurrenceEngine`; fin de serie algebraico; extensiones reservadas |
| `RecurrenceEngine` | Application | Expansión a ocurrencias virtuales (sin filas físicas) |
| `RecurrenceEndKind` | Presentation | Modos de UI del editor; no se persiste ni alimenta al motor directamente |

---

## 1. ¿Por qué existen Repeat y Recurrence?

Porque resuelven **dos contratos distintos** en el ciclo de vida del evento:

### `Repeat*` — contrato de **persistencia y producto**
- Vive en el modelo de dominio persistible (`Event`, `EventTemplate`).
- Codec estable hacia SwiftData / futuro CloudKit: strings planos (`none`, `daily`, …) o JSON versionado (interval, fin, custom).
- Incluye presets de producto (`editorSelectableRules`) y envelope futuro (`RepeatCustomConfiguration`).
- Token de “no repite”: **`none`** (legado / wire format).

### `Recurrence*` — contrato de **expansión / cálculo**
- Entrada del motor que genera ocurrencias virtuales en una ventana de consulta.
- Fin de serie como enum: `.never` / `.after(count:)` / `.onDate(_:)`.
- Reserva semántica de motor (`byWeekdays`, `excludedDates`, `customPayload`) **sin** contaminar el esquema persistido.
- Token de “no repite”: **`never`** (semántica de series, no de columna legacy).

El puente intencional es **`RepeatRule.asRecurrenceRule`**, que traduce frecuencias y fines sin que el store conozca el engine ni el engine conozca el codec.

---

## 2. ¿Representan capas distintas?

**Sí — bounded contexts distintos, no sinónimos.**

| Bounded context | Preocupaciones |
|-----------------|----------------|
| **Almacenamiento / producto** (`RepeatRule`) | Forma serializable, compatibilidad hacia atrás, raw values CloudKit-friendly, presets de UI ligados al dato guardado |
| **Cálculo / expansión** (`RecurrenceRule` + engine) | Generación de fechas, ventana de query, fin de serie explícito, extensiones de motor aún no aplicadas |
| **Presentación** (`RecurrenceEndKind`) | UX del editor (never / afterCount / onDate) rehidratada hacia campos de `RepeatRule` |

Mezclarlos en un solo tipo forzaría a que el motor conozca el codec de persistencia, o a que el store cargue semántica de expansión (`byWeekdays`, etc.) antes de existir en el wire format.

---

## 3. ¿Existe duplicación real?

**Hay solapamiento superficial de vocabulario; no hay duplicación accidental de verdad de dominio.**

| Aspecto | ¿Duplicado? | Notas |
|---------|-------------|--------|
| Frecuencias `daily…yearly` | Solapamiento de nombres | Mismos periodos; tokens de “no repite” **distintos a propósito** (`none` vs `never`) |
| `interval` | Paralelo | Misma idea a ambos lados del puente |
| Fin de serie | **Shapes distintos** | Persistencia: dos opcionales (`endDate`, `occurrenceCount`). Motor: un enum. UI: `RecurrenceEndKind` |
| Algoritmo de expansión | **No** | Solo `RecurrenceEngine` + `RecurrenceRule` |
| Presets de editor | **No (hoy)** | Solo en `RepeatRule.editorSelectableRules` |

Conclusión: es un **anti-corruption layer** entre store y engine, no dos implementaciones del mismo algoritmo.

---

## 4. ¿Qué ventajas tendría unificarlos?

Unificar en un único modelo podría:

1. **Reducir superficie cognitiva** — un solo tipo “Repeat/Recurrence” para onboarding de equipo.
2. **Eliminar el mapeo** `asRecurrenceRule` y la dualidad `none`/`never`.
3. **Simplificar tests de bridge** — un codec + un shape de motor.
4. **Facilitar features futuras** si se adopta un SSOT único (p. ej. RRULE canónico extremo a extremo) *y* se acepta migrar datos.

Estas ventajas son reales **solo** si se redefine conscientemente el único contrato de recurrencia y se planifica migración. No son un “cleanup” gratuito.

---

## 5. ¿Qué riesgos tendría unificarlos?

1. **Migración de datos** — `repeatRuleRawValue` hoy admite `none` y JSON v2; unificar con `never` / enum de fin exige versión de esquema y caminos de decode legacy.
2. **Acoplamiento store ↔ motor** — cambios de engine (`byWeekdays`, exclusiones) presionan el wire format; cambios CloudKit/SwiftData presionan el engine y la UI.
3. **Contaminación prematura del esquema** — campos reservados del motor entrarían en persistencia antes de tener producto/sync listo.
4. **Impacto transversal** — editor (`RecurrenceEndKind`), templates, mappers, catálogo, tests de codec/expansión, quick ops sobre masters.
5. **Regresión de Private Beta** — alto costo / bajo beneficio frente a un dual stack ya estable y documentado.
6. **Pérdida del anti-corruption layer** — el precio del dual stack (puente + dos vocabularios) es precisamente el desacoplamiento que unificar sacrifica.

```
Hoy (desacoplado):
  Event(RepeatRule)  --asRecurrenceRule-->  RecurrenceEngine(RecurrenceRule)

Tras unificar (acoplado):
  Event / Store / Editor / Engine  -->  Un solo tipo compartido
```

---

## 6. ¿Cuál es la recomendación profesional?

**Mantener el dual stack. No unificar en Private Beta.**

| Criterio | Veredicto |
|----------|-----------|
| ¿Por qué ambos? | Persistencia estable vs motor de expansión |
| ¿Capas distintas? | **Sí** |
| ¿Duplicación real? | Solapamiento de frecuencias; **no** doble lógica |
| ¿Unificar aporta? | Solo con epic de migración + SSOT rediseñado |
| ¿Unificar arriesga? | Acoplamiento, datos, regresión |
| **Acción** | Conservar `RepeatRule` + `asRecurrenceRule` + `RecurrenceRule` / `RecurrenceEngine`; documentar; no fusionar |

### Condiciones para reconsiderar (post–Private Beta)

Revisar unificación **solo si** ocurre al menos uno de:

- Adopción de **RRULE / iCalendar** como formato canónico de sync.
- CloudKit u otro sync que exija un **único** esquema de recurrencia consciente.
- Producto necesita features de motor (`byWeekdays`, exclusiones) **y** se acepta versionar el wire format de una vez.

Hasta entonces, el dual stack es la decisión arquitectónica correcta: costo cognitivo acotado, riesgo de datos bajo, evolución independiente de persistencia y expansión.

---

## Resumen ejecutivo

Repeat y Recurrence no son un error de naming: son **persistencia de producto** frente a **cálculo de ocurrencias**, unidos por un puente explícito. Unificar ahorraría tipos a costa de acoplamiento y migración. **Recomendación: no modificar; mantener dual stack.**
