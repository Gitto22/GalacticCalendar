# Contributing

Contribuciones al código de Galactic Calendar. El `.xcodeproj` puede residir fuera de este árbol; coordina con el mantenedor para el workspace local.

## Convenciones

- Seguir `CodingStandards.md` y la arquitectura en `Architecture.md`.
- No inventar pantallas, flags ni integraciones (CloudKit, Widgets, Watch, StoreKit) sin brief explícito.
- Private Beta: priorizar estabilidad local, a11y y persistencia segura.
- Documentación de sprints en `Documentation/SprintReports/` cuando el cambio sea un quality gate o cleanup arquitectónico.

## Commits

- Mensajes cortos en imperativo: `Add catalog resilience skip for corrupt rows`.
- Un concern por commit cuando sea práctico.
- No commits vacíos; no incluir binarios enormes ni secretos.
- No usar `--no-verify` salvo acuerdo explícito.

## Branches

| Prefijo | Uso |
|---------|-----|
| `feature/` | Nueva capacidad dentro del alcance acordado |
| `fix/` | Corrección de defecto |
| `docs/` | Solo documentación |
| `qa/` | Quality gates / certificación |
| `refactor/` | Refactor sin cambio de producto (justificado) |

Evitar trabajo directo en `main`.

## Pull Requests

1. Título claro; cuerpo con **Summary** (1–3 bullets) y **Test plan**.
2. Enlazar informe de sprint si aplica.
3. Diff enfocado: no mezclar reformateos masivos con features.
4. Actualizar `CHANGELOG.md` / docs tocadas cuando el contrato público o el onboarding cambien.
5. Esperar review antes de merge.

## Code Review

Revisores comprueban:

| Área | Pregunta |
|------|----------|
| Capas | ¿Presentation depende de Infrastructure concreta? |
| DI | ¿Wiring en Composition Root / factory? |
| SRP | ¿Nuevo God object? |
| Persistencia | ¿Camino unavailable cubierto? |
| Nav | ¿Modales por VM, no push muerto? |
| Tests | ¿Cobertura del cambio? |
| Docs | ¿Arquitectura/DataModel siguen siendo verdad? |

Bloquear merge si hay feature fuera de alcance Private Beta activada por defecto, o store in-memory silencioso en producto.
