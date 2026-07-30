# Development Guide

Guía operativa alineada con el Composition Root y las capas reales del repo. No inventa módulos (Settings, CloudKit, Widgets) como si estuvieran listos.

## Prerrequisitos

- Xcode con soporte Swift 6 / SwiftUI / SwiftData.
- Proyecto Xcode local (puede estar fuera de este git tree) que compile las carpetas de código de este repositorio.
- Leer `Architecture.md` y `FolderStructure.md` antes del primer PR.

## Cómo crear una Feature

1. **Acotar dominio** — ¿modelo nuevo en `Domain/Models/…`? ¿solo UI?
2. **Contrato Domain** — structs/enums + protocolo de repositorio si hay persistencia.
3. **Data** — entidad SwiftData / mapper / repository (si aplica). Migración de schema solo si el store cambia.
4. **Application** — servicio o extensión de uno existente (`EventPersistenceService`, template, Universe…). Evitar “God services”; preferir coordinators (patrón `EventReminderCoordinator`).
5. **Presentation** — ViewModel `@Observable` + View. Reutilizar tokens del Design System (`Spacing`, `ColorPalette`, …).
6. **DI** — cablear en `DependencyContainer` y, si es pantalla de entrada, en `ViewModelFactory`. Child VMs: factory closures o creación desde el coordinator padre.
7. **Tests** — unitarios Domain/Application/ViewModel; integration si toca SwiftData; UI smoke solo si es flujo crítico Private Beta.
8. **Docs** — actualizar `DataModel.md` / `CHANGELOG.md` si el contrato o el producto cambia.

**No** habilitar flags CloudKit/Widgets/Watch sin decisión de producto explícita.

## Cómo añadir una pantalla

1. Crear `Presentation/Views/<Area>/MyScreen.swift` + `Presentation/ViewModels/<Area>/MyScreenViewModel.swift`.
2. Inyectar dependencias por **init** (fachadas Application o protocolos Domain) — no abrir SwiftData en la View.
3. Presentación de producto: flags `isPresenting*` + `fullScreenCover` / `sheet` en el ViewModel padre (patrón QA-06). No usar `AppRouter` salvo trabajo explícito sobre el push stack reservado.
4. Si es pantalla raíz nueva: método en `ViewModelFactory` + bootstrap desde `RootView` (hoy solo Home + grid).
5. Accessibility: IDs estables si entrará en UITests (`SmokeAccessibilityID` como referencia).
6. Localización `en` / `es` en `Resources/Localization/`.

## Cómo añadir un Repository

1. Protocolo en `Domain/Protocols/Repositories/` (`…Protocol`, errores tipados si aplica).
2. Implementación SwiftData en `Data/Repositories/`.
3. Variante `Unavailable…` si el store puede fallar al launch (mismo patrón que eventos / templates / Universe).
4. Wire en `DependencyContainer.init()` (rama `openedContainer` vs unavailable).
5. Exponer a Presentation **solo** vía Application service o, excepcionalmente, protocolo Domain en factory (Universe).
6. Tests: unitarios del mapper/repo con harness in-memory; integration en `Tests/IntegrationTests/Database/` si es persistencia crítica.

## Cómo añadir un Service

1. Decidir capa:
   - **Application** — orquestación, catálogo, engines, validación.
   - **No** poner lógica de negocio en Views.
2. Crear tipo en `Application/Services/` (o `Services/Universe/`).
3. Preferir dependencias por init (protocolos Domain / otros services).
4. Si es `@Observable` de producto (fachada UI): inyectar en Environment desde `GalacticCalendarApp` **solo** si muchas Views lo leen; si no, pasar por ViewModel.
5. Cablear instancia única en `DependencyContainer` (ciclo de vida process-scoped).
6. Documentar ownership en comentario `///` del tipo.

## Flujo Git recomendado

```
main (estable)
  └─ feature/<area>-<slug>   o   fix/<area>-<slug>
        └─ PR → review → merge
```

1. Branch desde `main` actualizado.
2. Commits pequeños, mensaje en imperativo (ver `Contributing.md`).
3. No incluir secretos (`.env`, claves) — ver `Config/Environment/SecretsPolicy.swift`.
4. No forzar push a `main`.
5. PR con resumen + plan de prueba (unit / integration / UI según alcance).

## Checklist rápido pre-PR

- [ ] Sin segundo Composition Root
- [ ] Sin SwiftData en Presentation
- [ ] Tokens Design System (sin magic numbers nuevos evitables)
- [ ] Navegación modal vía VM (no push huérfano)
- [ ] Tests del comportamiento tocado
- [ ] `en`/`es` si hay strings nuevos
