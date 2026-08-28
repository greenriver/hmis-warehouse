# 4 Solution Strategy

[← Previous: 3 Context and Scope](03-context.md) | [Table of Contents](README.md) | [Next: 5 Building Block View →](05-building-blocks/05-0-building-blocks.md)

This section summarizes the fundamental decisions and solution strategies that shape the Open Path Platform, organized by the [quality goals](01-introduction.md#12-quality-goals) they address. The full set of quality requirements, goals and secondary alike, is in [Section 10](10-quality.md).

## 4.1 Quality Goals → Solution Approaches

One row per ranked quality goal, in priority order.

| Quality Goal | Solution Approach | Details |
| --- | --- | --- |
| **Extensibility & Local Configuration** | HUD CSV 1:1 source tables match the standard by construction; new mandated elements arrive through data-source configuration. Modular report drivers, per-spec-version importer drivers, and data-driven form/CE definitions keep new mandates and local variation outside the core, so no installation forks (Q-1–Q-3, Q-13, Q-14, Q-24). | [2.3 Conventions](02-constraints.md), [5.2.1 Warehouse](05-building-blocks/05-2-1-warehouse.md), [8.1 HMIS Data Model](08-concepts/08-1-hmis-data-model.md) |
| **Data Integrity & Auditability** | Source-preserving warehouse keeps ingested data in its original form; deduplication links rather than discards, and corrected exports replace their source records. The reporting engine snapshots contributing records at generation time, superseded fiscal-year generators are retained, and application deletes are soft deletes, so figures and records stay recoverable (Q-4–Q-6, Q-25). | [5.2.1 Warehouse](05-building-blocks/05-2-1-warehouse.md) |
| **Client Protection & Fair Access** | Policy-based authorization makes disclosure permission-checked and deny-by-default, with community policy configured on top of that default; CoC partitioning, access logging, externalized authentication, and encryption at rest and in transit bound what a compromised session reaches. Allocation outcomes are recorded rather than recollected: the Coordinated Entry path stores each match, the declining program, and its stated reason, and reports them by reason and agency (Q-7–Q-9, Q-21, Q-26). | [5.2.3 Authentication](05-building-blocks/05-2-3-authentication.md), [8.2 Security](08-concepts/08-2-security.md), [5.2.2 CAS](05-building-blocks/05-2-2-cas.md) |
| **Availability & Resilience** | The React SPA and GraphQL API decouple data entry from batch work; background processing keeps imports and large reports off the interactive path. Regular backups cover infrastructure failure; no RTO/RPO is committed (Q-22, Q-23). Per-batch import tracking identifies what a bad import touched, but undoing one still means a point-in-time restore, which discards unrelated work committed since ([D-2](11-risks.md#112-technical-debts)). | [8.4 Background Processing](08-concepts/08-4-background-processing.md) |
| **Data Scalability** | Bulk imports and system-wide reports run as background jobs with progress reporting, and interactive and background tiers scale as independently deployable containers. Storage growth is bounded by pruning the per-record import audit trail on a retention policy rather than retaining every version indefinitely (Q-11, Q-12, Q-27). | [8.4 Background Processing](08-concepts/08-4-background-processing.md), [5.2.1 Warehouse](05-building-blocks/05-2-1-warehouse.md) |

The three [secondary quality requirements](10-quality.md#101-quality-requirements-overview) — Operational Self-Sufficiency, Interoperability, and Usability — are not ranked architectural drivers, but they fall out of the technology decisions and architectural patterns described below. Operational Self-Sufficiency is served by making routine operations configuration rather than code — CoCs, data sources, user groups, visibility rules, and reference data are all managed through the administrative UI — and by background processing that isolates failures per job and reports them with enough detail for an administrator to act (Q-10, Q-16, Q-17); infrequent one-time tasks may still require engineering support. HUD CSV 1:1 source tables and S3-based export support Interoperability (Q-15); and the React SPA with GraphQL enables the responsive data entry workflows behind Usability (Q-18, Q-19).

## 4.2 Key Technology Decisions

| Decision | Rationale |
| --- | --- |
| **Rails monolith for the Warehouse** | Consolidates business logic, reporting, and data management in a single deployable unit. The driver module pattern (`/drivers/[module]`) provides internal modularity without the overhead of separate services. |
| **React SPA + GraphQL for HMIS Frontend** | Separates the data entry UI from the backend, allowing independent frontend development and deployment. GraphQL provides a flexible query interface suited to the complex, nested HMIS data model. The SPA architecture enables responsive, low-latency data entry workflows for front-line staff. |
| **Externalized authentication (OAuth2-Proxy / Dex)** | Removes credential management from application code. Allows the identity provider (Keycloak, Okta) to be swapped without application changes. |
| **S3 as ingestion boundary** | Provides a simple, durable handoff point between external data partners and the Warehouse. Partners deposit files; the Warehouse imports on schedule. Decouples partner availability from processing. |
| **DBT + Superset for analytics** | Separates analytical transformations from the operational database. DBT models warehouse data into analytics-ready datasets; Superset provides self-service dashboards without custom report development. |

## 4.3 Core Architectural Patterns

- **Source-Preserving Warehouse**: All ingested data is stored in HUD-schema source tables before normalization into unified warehouse records. This preserves full provenance and supports re-processing without data loss.
- **Modular Feature Drivers**: Features are isolated as self-contained module directories under `/drivers/`. See [8.3 Driver Module Pattern](08-concepts/08-3-driver-module-pattern.md) and the [driver catalog](05-building-blocks/05-2-1-warehouse.md).
- **Deduplication & Linking**: Cross-source fuzzy matching creates unified client identities while maintaining links to all contributing source records. See [5.2.1 Warehouse](05-building-blocks/05-2-1-warehouse.md).
- **Data-Driven Forms & Workflows**: Configurable form definitions handle evolving HUD and custom data collection requirements. CE referral lifecycles are driven by configuration rather than code.
- **Policy-Based Authorization**: Complex access control logic (ROI rules, role-based and relationship-based permissions, CoC-scoped visibility) is encapsulated in dedicated policy objects.
- **Reporting Provenance**: The reporting engine snapshots contributing data at generation time, ensuring users can inspect the exact records behind any report figure.
