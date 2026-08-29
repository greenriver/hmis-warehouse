# 1 Introduction and Goals

[Table of Contents](README.md) | [Next: 2 Architecture Constraints →](02-constraints.md)

## 1.1 Requirements Overview

Open Path Platform is an integrated platform for homeless services management, built to help one or more **Continua of Care (CoC)** meet federal data collection and reporting requirements. It supports deployments of varying scale, ranging from a single municipality to multi-state organizations.

> **Scope:** This architecture documentation covers the entire Open Path Platform across all of its repositories. Individual building blocks are mapped to their source repositories in [Section 5](05-building-blocks/05-0-building-blocks.md).

- **HMIS Data Entry** — Direct client data collection via a modern web interface, supporting configurable forms aligned with HUD HMIS Data Standards.
- **Coordinated Entry** — Assessment, prioritization, and referral workflows for housing placements.
- **Data Warehousing** — Ingestion, deduplication, and normalization of client records from multiple upstream HMIS vendors into a unified system of record.
- **HUD-Compliant Reporting** — Generation of mandated reports (APR, CAPER, LSA, SPM) with snapshotted data provenance.
- **Community Analytics** — Transformed warehouse data powering operational dashboards and strategic planning.
- **Case Management** — Shared client-level workspaces for teams collaborating on a by-name client list (cohorts).

## 1.2 Quality Goals

These five **quality goals** are the architecture's drivers, in priority order.

| Priority | Quality goal | Scenario | Detail |
| --- | --- | --- | --- |
| 1 | **Extensibility & Local Configuration** | HUD publishes revised HMIS Data Standards; they are in production before the compliance deadline, without modifying core domain models and without forking any installation. | [Q-1–Q-3, Q-13, Q-14, Q-24](10-quality.md#102-quality-scenarios) |
| 2 | **Data Integrity & Auditability** | An HMIS Lead questions a figure in a generated report and drills into the exact client records and data sources that produced it. | [Q-4–Q-6, Q-25](10-quality.md#102-quality-scenarios) |
| 3 | **Client Protection & Fair Access** | A staff member views a client record but lacks the permission to view PII; PII fields are withheld; all client information is restricted from users who have not been granted access. | [Q-7–Q-9, Q-21, Q-26](10-quality.md#102-quality-scenarios) |
| 4 | **Availability & Resilience** | Front-line staff can work in the HMIS without interruption through peak intake hours while a large report runs in the background. | [Q-22, Q-23](10-quality.md#102-quality-scenarios) |
| 5 | **Data Scalability** | A statewide deployment accumulates ten years of service data; reporting stays within its time budget and storage growth stays bounded, without re-architecting. | [Q-11, Q-12, Q-27](10-quality.md#102-quality-scenarios) |

Three further qualities — Operational Self-Sufficiency, Interoperability, and Usability — are tracked as **secondary quality requirements**: real acceptance criteria, but not ranked architectural drivers.

[Section 10 (Quality Requirements)](10-quality.md) holds the complete set — all eight qualities, their Q42 labels, and every scenario.

## 1.3 Stakeholders

| Role | Architectural Expectation |
| --- | --- |
| **HMIS End Users** | Responsive, intuitive interface that does not impede data entry workflows. |
| **HMIS Leads** | Reliable, auditable reports that satisfy HUD submission requirements. |
| **System Administrators** | Manageable configuration for user access, data sources, and system behavior without code changes. |
| **Analysts & Researchers** | Stable, well-modeled analytics data that supports ad-hoc querying and dashboards. |
| **Open Path Engineering Team** | Modular, well-documented codebase that supports independent feature development and safe deployments. |
| **Clients (People Experiencing Homelessness)** | Their PII is disclosed only where a permission grants it, under their community's disclosure rules; decisions that allocate housing to them are recorded and accountable. |
| **Housing Providers & Partner Agencies** | Access limited to the clients and referrals they are responsible for, and a durable record of referral decisions. |
| **Upstream Data Partners** | Stable ingestion interfaces (S3, API) with clear data format contracts. |
| **General Public** | Community-level figures readable without an account, aggregate figures only. |

See [Context and Scope](03-context.md) for detailed user roles and system interfaces.
