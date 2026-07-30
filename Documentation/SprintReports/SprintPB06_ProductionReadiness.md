# Sprint PB-06 — Production Readiness

**Fecha:** 2026-07-30  
**Objetivo:** Preparar Galactic Calendar para Beta privada (sin CloudKit / Widgets / Watch).

---

## Acciones realizadas

| Área | Cambio |
|------|--------|
| `Info.plist` | URLs `albancal.example` → `albancal.com/apps/galactic-calendar/*`; `UILaunchScreen`; nota de Private Beta |
| `PrivacyInfo.xcprivacy` | Manifest limpio (no tracking, no collected data types, no required-reason APIs en código app) |
| Legal | Privacy + Terms sin marcadores PLACEHOLDER / example.com |
| Marketing | Description + Keywords listos como borrador de beta |
| Constants | CloudKit/Widget marcados reserved; `SecretsPlaceholder` → `SecretsPolicy` |
| Docs | README + Roadmap actualizados |
| AppIcon | README de bloqueante (assets aún vacíos) |

## Verificado OK

- Localización en/es: **257/257** (paridad)  
- Entitlements iOS vacíos (sin iCloud/Push/App Groups)  
- Feature flags: CloudKit / widgets / watch / EventKit / sharing / StoreKit = **false**  
- Fondos mensuales con PNG cableados  

## Informe ejecutivo

Ver respuesta de cierre del sprint (bloqueantes / riesgos / estado).
