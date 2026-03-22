# 4 Solution Strategy

[← Previous: 3 Context and Scope](03-context.md) | [Table of Contents](README.md) | [Next: 5 Building Block View →](05-building-blocks/05-0-building-blocks.md)

This section summarizes the fundamental decisions and solution strategies that shape the Open Path Platform, organized by the [quality goals](01-introduction.md) they address.

## 4.1 Quality Goals → Solution Approaches

| Quality Goal | Solution Approach | Details |
| --- | --- | --- |
| **Regulatory Compliance** | HUD CSV 1:1 source tables ensure data structures match the standard by construction. Data-driven form definitions allow HUD collection requirements to evolve via configuration. Modular report drivers isolate each HUD report so new mandates can be implemented without modifying the core. | [2.3 Conventions](02-constraints.md), [5.2.1 Warehouse](05-building-blocks/05-2-1-warehouse.md), [8.1 HMIS Data Model](08-concepts/08-1-hmis-data-model.md) |
| **Data Integrity & Provenance** | Source-preserving warehouse retains all ingested data in its original form before normalization. Deduplication links source records to unified warehouse clients without discarding source data. The reporting engine snapshots contributing records at generation time so results are auditable even as underlying data changes. | [5.2.1 Warehouse](05-building-blocks/05-2-1-warehouse.md) |
| **Security & Privacy** | Policy-based authorization encapsulates ROI rules and multi-stakeholder permissions into dedicated policy objects. Externalized authentication delegates credential management to an OAuth2-Proxy / Dex / Keycloak layer. Multi-CoC data partitioning is enforced at the access control layer. | [5.2.3 Authentication](05-building-blocks/05-2-3-authentication.md), [8.2 Security](08-concepts/08-2-security.md) |
| **Scalability** | Distributed architecture consists of independently deployable containers (HMIS Frontend, Warehouse, Analytics, CAS). Multi-CoC support is a first-class concern — CoCs are onboarded via configuration, not code. Background processing handles bulk imports without blocking interactive use. | [5 Building Block View](05-building-blocks/05-0-building-blocks.md), [5.2.4 Analytics](05-building-blocks/05-2-4-analytics.md) |

## 4.2 Key Technology Decisions

| Decision | Rationale |
| --- | --- |
| **Rails monolith for the Warehouse** | Consolidates business logic, reporting, and data management in a single deployable unit. The driver module pattern (`/drivers/[module]`) provides internal modularity without the overhead of separate services. |
| **React SPA + GraphQL for HMIS Frontend** | Separates the data entry UI from the backend, allowing independent frontend development and deployment. GraphQL provides a flexible query interface suited to the complex, nested HMIS data model. |
| **Externalized authentication (OAuth2-Proxy / Dex)** | Removes credential management from application code. Allows the identity provider (Keycloak, Okta) to be swapped without application changes. |
| **S3 as ingestion boundary** | Provides a simple, durable handoff point between external data partners and the Warehouse. Partners deposit files; the Warehouse imports on schedule. Decouples partner availability from processing. |
| **DBT + Superset for analytics** | Separates analytical transformations from the operational database. DBT models warehouse data into analytics-ready datasets; Superset provides self-service dashboards without custom report development. |

## 4.3 Core Architectural Patterns

- **Source-Preserving Warehouse**: All ingested data is stored in HUD-schema source tables before normalization into unified warehouse records. This preserves full provenance and supports re-processing without data loss.
- **Modular Feature Drivers**: Large features (HUD reports, CE workflows) are isolated in `/drivers/[module]` directories mirroring the Rails structure, keeping core domain models clean and limiting the blast radius of changes.
- **Deduplication & Linking**: Cross-source fuzzy matching creates unified client identities while maintaining links to all contributing source records. See [5.2.1 Warehouse](05-building-blocks/05-2-1-warehouse.md).
- **Data-Driven Forms & Workflows**: Configurable form definitions handle evolving HUD and custom data collection requirements. CE referral lifecycles are driven by configuration rather than code.
- **Policy-Based Authorization**: Complex access control logic (ROI rules, role-based and relationship-based permissions, CoC-scoped visibility) is encapsulated in dedicated policy objects.
- **Reporting Provenance**: The reporting engine snapshots contributing data at generation time, ensuring users can inspect the exact records behind any report figure.
