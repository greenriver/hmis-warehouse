# 2 Architecture Constraints

[← Previous: 1 Introduction and Goals](01-introduction.md) | [Table of Contents](README.md) | [Next: 3 Context and Scope →](03-context.md)

This section describes the constraints that limit design and implementation freedom across the Open Path Platform.

## 2.1 Technical Constraints

| Constraint | Consequence |
| --- | --- |
| **HUD HMIS Data Standards** | Data models, collection forms, and reports must conform to HUD specifications. Published updates must be implemented by HUD's compliance deadlines. |
| **Data Portability** | The platform must support HUD CSV import from external HMIS vendors and export for data migration, ensuring it does not become a data silo. |
| **Multi-CoC Deployment** | Clients move between CoCs; cross-source deduplication requires a unified data store to correlate records across boundaries. A single deployment must support multiple Continua of Care with data partitioning for access control, ruling out per-CoC isolation strategies. |
| **PII Protection** | Client PII must be encrypted at rest and in transit. Access is governed by Release of Information (ROI) rules and role-based permissions. All access must be auditable. See [Section 10 (#secure scenarios)](10-quality.md#security--privacy-secure) for verification criteria. |
| **No In-App Credential Management** | The platform must integrate with existing community identity providers and must not store or manage user credentials directly. Authentication is delegated to an external layer. See [5.2.3 Authentication](05-building-blocks/05-2-3-authentication.md). |
| **Existing Technology Stack** | The Warehouse is a Ruby on Rails monolith; the HMIS frontend is a React SPA. Codebase size and team expertise make changing core technologies impractical. New capabilities (e.g., analytics via DBT/Python) are introduced as separate applications rather than replacements. |

## 2.2 Organizational Constraints

| Constraint | Consequence |
| --- | --- |
| **Open Source Distribution** | The platform is developed and distributed as open-source software. Core platform logic must be separable from community-specific customizations. Bespoke extensions use the driver module pattern to avoid forking the core. |
| **Federal & Local Privacy Regulations** | Client data handling must comply with applicable privacy regulations. Data sharing between organizations requires explicit consent tracking. |
| **Accessibility (WCAG 2.1 AA)** | Public-facing and staff-facing interfaces must meet WCAG 2.1 Level AA standards to ensure usability for all users. |
| **Small Engineering Team** | Architecture must favor convention and configuration over custom development. The modular driver pattern limits the blast radius of changes and allows parallel work. |

## 2.3 Conventions

| Convention | Consequence |
| --- | --- |
| **HUD CSV Schema as Source Tables** | Warehouse HUD data tables are 1:1 with the CSV exchange format, using HUD naming conventions. This ensures portability and simplifies compliance validation. |
| **Source Data Integrity Policy** | Data collected through the platform's own HMIS is validated for HUD compliance at the point of entry. Data received from external HMISs is preserved as-is — the platform does not correct or sanitize imported records. Reports surface upstream data quality issues intentionally, giving HMIS Leads visibility into DQ problems at their source rather than masking them. |
| **Data Source Provenance** | Every HUD record includes a data source identifier. Combined with the record ID, this forms a composite unique identity enabling multi-source deduplication. |
| **Driver Module Pattern** | Large features are isolated as self-contained Rails engine modules under `/drivers/`. See [8.3 Driver Module Pattern](08-concepts/08-3-driver-module-pattern.md). |
| **GraphQL API Boundary** | The HMIS React frontend communicates exclusively via GraphQL, enforcing a clean separation between presentation and business logic. |

*Note: Component-specific technical constraints (e.g., language versions, framework versions) are documented in the [Building Block View](05-building-blocks/05-0-building-blocks.md) for each component.*
