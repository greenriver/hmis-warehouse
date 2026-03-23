# 1 Introduction and Goals

[Table of Contents](README.md) | [Next: 2 Architecture Constraints →](02-constraints.md)

## 1.1 Requirements Overview

Open Path Platform is an integrated platform for homeless services management, built to help one or more **Continua of Care (CoC)** meet federal data collection and reporting requirements. The platform must support deployments ranging from a single municipality to an entire state.

> **Scope:** This architecture documentation covers the entire Open Path Platform across all of its repositories. Individual building blocks are mapped to their source repositories in [Section 5](05-building-blocks/05-0-building-blocks.md).

- **HMIS Data Entry** — Direct client data collection via a modern web interface, supporting configurable forms aligned with HUD HMIS Data Standards.
- **Coordinated Entry** — Assessment, prioritization, and referral workflows for housing placements.
- **Data Warehousing** — Ingestion, deduplication, and normalization of client records from multiple upstream HMIS vendors into a unified system of record.
- **HUD-Compliant Reporting** — Generation of mandated reports (APR, CAPER, LSA, SPM) with snapshotted data provenance.
- **Community Analytics** — Transformed warehouse data powering operational dashboards and strategic planning.

## 1.2 Quality Goals

The platform's top architectural priorities, in order, are: **Regulatory Compliance**, **Data Integrity & Provenance**, **Security & Privacy**, and **Scalability**. Four additional quality requirements — Modifiability, Interoperability, Operability, and Usability — are also tracked.

See [Section 10 (Quality Requirements)](10-quality.md) for definitions, labels, and detailed quality scenarios.

## 1.3 Stakeholders

| Role | Architectural Expectation |
| --- | --- |
| **HMIS End Users** | Responsive, intuitive interface that does not impede data entry workflows. |
| **HMIS Leads** | Reliable, auditable reports that satisfy HUD submission requirements. |
| **System Administrators** | Manageable configuration for user access, data sources, and system behavior without code changes. |
| **Analysts & Researchers** | Stable, well-modeled analytics data that supports ad-hoc querying and dashboards. |
| **Open Path Engineering Team** | Modular, well-documented codebase that supports independent feature development and safe deployments. |
| **Upstream Data Partners** | Stable ingestion interfaces (S3, API) with clear data format contracts. |

See [Context and Scope](03-context.md) for detailed user roles and system interfaces.
