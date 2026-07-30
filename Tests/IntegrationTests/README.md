# QA-02 — SwiftData Integration Tests

Validates real persistence (SwiftData) for Private Beta. Not unit tests. Not UI tests.

## Target

Add `Tests/IntegrationTests/Database/*.swift` to a test target with `@testable import GalacticCalendar` + SwiftData.

## Cases

| # | File | Focus |
|---|------|-------|
| 1 | `SwiftDataStoreOpenIntegrationTests` | Temp store init |
| 2 | `SwiftDataEventCRUDIntegrationTests` | Event CRUD |
| 3 | `SwiftDataPersistenceRoundTripIntegrationTests` | Close / reopen on-disk |
| 4 | `SwiftDataTemplateIntegrationTests` | Template CRUD + event from template |
| 5 | `SwiftDataCatalogIntegrationTests` | `refresh()` catalog coherence |
| 6 | `SwiftDataErrorIntegrationTests` | Unavailable open/write + corrupt read |
| — | `ResilientEventCatalogIntegrationTests` | Catalog resilience matrix (QA-03) |

## Isolation

- Unique in-memory name or unique on-disk temp directory per test
- On-disk directories deleted in `tearDown` / `defer`
