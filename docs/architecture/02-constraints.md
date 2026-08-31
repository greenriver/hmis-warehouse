# 2 Architecture Constraints

[← Previous: 1 Introduction and Goals](01-introduction.md) | [Table of Contents](README.md) | [Next: 3 Context and Scope →](03-context.md)

This section describes the constraints that limit design and implementation freedom across the Open Path Platform.

## 2.1 Technical Constraints

| Constraint | Consequence |
| --- | --- |
| **HUD HMIS Data Standards** | Data models, collection forms, and reports must conform to HUD specifications, and published updates must be implemented by HUD's compliance deadlines. Data collected in the platform's own HMIS must be HUD-compliant at the point of entry. |
| **Data Portability** | The platform must consume HUD CSV exports from external HMIS vendors and produce exports conforming to the same published specification, so a community can migrate in or out. The format and its revisions are dictated by HUD, not chosen. |
| **Multi-CoC Deployment** | A single deployment must support multiple Continua of Care with data partitioning for access control, ruling out per-CoC isolation strategies. Clients move between CoCs, so records must remain correlatable across those boundaries. |
| **Multi-Installation Customization** | A single codebase must serve many independent installations, each customized to its community, and every installation must be able to take core upgrades — so per-customer forks or long-lived branches are not available. |
| **PII Protection** | Client PII must be encrypted at rest and in transit, and all access to it must be auditable. |
| **Externalized Credential Management** | The platform must integrate with existing community identity providers, delegating authentication to an external layer rather than managing user credentials in-app. |
| **Existing Technology Stack** | The Warehouse is a Ruby on Rails monolith; the HMIS frontend is a React SPA. Codebase size and team expertise make changing core technologies impractical. New capabilities (e.g., analytics via DBT/Python) are introduced as separate applications rather than replacements. |

## 2.2 Organizational Constraints

| Constraint | Consequence |
| --- | --- |
| **Open Source Distribution** | The platform is developed and distributed as open-source software. Third parties can inspect, deploy, and contribute to the codebase, so licensing, dependency choices, and public repository practices must remain compatible with open-source release. |
| **Federal & Local Privacy Regulations** | Client data handling must comply with applicable privacy regulations, which vary by community: some require explicit consent tracking before data is shared between organizations, others permit far broader disclosure. The platform must be configurable to either without code changes. |
| **Efficiency at Scale** | Engineering capacity is shared across many installations, so the architecture favors convention and configuration over custom development per community. This keeps every community on the same well-tested code path rather than a bespoke fork, and lets improvements reach all installations at once. |

## 2.3 Conventions

| Convention | Consequence |
| --- | --- |
| **HUD CSV Schema as Source Tables** | Warehouse HUD data tables are 1:1 with the CSV exchange format, using HUD naming conventions. This ensures portability and simplifies compliance validation. |
| **Imported Data Retained As Received** | The upload from an external HMIS is retained unmodified; corrections applied on the way in are opt-in per data source and write only to the derived copies. Reports surface the remaining upstream data quality issues intentionally, giving HMIS Leads visibility into DQ problems at their source rather than masking them. |
| **Data Source Provenance** | Every HUD record includes a data source identifier. Combined with the record ID, this forms a composite unique identity enabling multi-source deduplication. |
| **Driver Module Pattern** | Features are isolated as self-contained module directories under `/drivers/`, which is one way the Multi-Installation Customization constraint above is satisfied without forking. See [8.3 Driver Module Pattern](08-concepts/08-3-driver-module-pattern.md). |
| **GraphQL API Boundary** | The HMIS React frontend communicates exclusively via GraphQL, enforcing a clean separation between presentation and business logic. |

*Note: Component-specific technical constraints (e.g., language versions, framework versions) are documented in the [Building Block View](05-building-blocks/05-0-building-blocks.md) for each component.*
