# Release Process

Proceso de release alineado con el estado certificado del repo (Private Beta **apto**, 2026-07-30). CloudKit / Widgets / Watch **no** forman parte de estos trenes hasta que el roadmap los active.

## Canales

```
Private Beta → Public Beta → Release Candidate → App Store
         ↑
    TestFlight (distribución)
```

## Beta privada

**Estado código:** 🟢 Apto (`PrivateBetaCertificationAudit.md`, PB-06).

Checklist operativo:

1. Scheme iOS (o el destino acordado del tren privado).
2. Version / build bump en el target Xcode local.
3. App Icon 1024 RGB sin alpha incluido en el asset catalog.
4. `PrivacyInfo.xcprivacy` en Copy Bundle Resources.
5. Archive → subir a **TestFlight** (grupo cerrado).
6. Smoke manual: launch, mes, CRUD evento, agenda, Universe, store unavailable (si se prueba el camino).
7. Confirmar flags fuera de alcance **off** (`cloudKitSync`, widgets, etc.).

Alcance producto: calendario local, eventos avanzados, Universe, a11y base, persistencia segura.

## TestFlight

- Usado como vehículo de **Beta privada** (y más adelante pública).
- Grupo interno / externos limitados; feedback vía TestFlight Notes + issues.
- URLs legales (`Legal/`, Info.plist → albancal.com): válidas para tren cerrado; verificar hosting antes de pública amplia.

## Beta pública

Aún **no** abierta por defecto en el roadmap de producto. Antes de ampliar:

1. Cerrar feedback bloqueante de privada.
2. Re-correr Unit + Integration + UI Smoke.
3. Revisar copy App Store (`Marketing/AppStore/`) y Privacy/Terms.
4. Tren TestFlight de grupo amplio o External Testing.
5. Seguir excluyendo CloudKit/Widgets/Watch hasta FASE 3.

## Release Candidate

1. Tag / branch `rc/x.y.z`.
2. Congelar features; solo fixes P0/P1.
3. Archive de producción (certificados Distribution).
4. Checklist RC: a11y, persistencia, icono, privacy manifest, localización `en`/`es`, sin flags de scaffold activos.
5. Validación TestFlight RC ≥ ciclo acordado (p.ej. 48–72 h).

## App Store

1. Metadata y capturas desde `Marketing/`.
2. Submit RC aprobado.
3. Phased release recomendado en el primer store público.
4. Hotfix: mismo proceso RC reducido + notas de “fix only”.

## Lo que este repo no automatiza

- No hay pipeline CI versionado en este árbol.
- El `.xcodeproj` / signing / Asc API keys viven fuera del git documentado aquí — el mantenedor local es source of truth para archive.

## Referencias

- `Documentation/SprintReports/SprintPB06_ProductionReadiness.md`
- `Documentation/SprintReports/PrivateBetaCertificationAudit.md`
- `Documentation/Roadmap.md`
