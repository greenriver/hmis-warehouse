# 1 Introduction and Goals

[Table of Contents](README.md) | [Next: 2 Architecture Constraints →](02-constraints.md)

## 1.1 Requirements Overview

Open Path Platform is an integrated platform for homeless services management, built to help one or more **Continua of Care (CoC)** meet federal data collection and reporting requirements. The platform must support deployments ranging from a single municipality to an entire state.

- **HMIS Data Entry** — Direct client data collection via a modern web interface, supporting configurable forms aligned with HUD HMIS Data Standards.
- **Coordinated Entry** — Assessment, prioritization, and referral workflows for housing placements.
- **Data Warehousing** — Ingestion, deduplication, and normalization of client records from multiple upstream HMIS vendors into a unified system of record.
- **HUD-Compliant Reporting** — Generation of mandated reports (APR, CAPER, LSA, SPM) with snapshotted data provenance.
- **Community Analytics** — Transformed warehouse data powering operational dashboards and strategic planning.

## 1.2 Quality Goals

| Priority | Quality Goal | Scenario |
| --- | --- | --- |
| 1 | **Regulatory Compliance** | When HUD publishes updated Data Standards or reporting specifications, the platform can implement the changes and meet the published compliance deadline. |
| 2 | **Data Integrity & Provenance** | When a report result is questioned, an auditor can trace any figure back to the exact source records and data source that contributed to it. |
| 3 | **Security & Privacy** | Client PII is accessible only to users with an active Release of Information (ROI) or appropriate role-based permissions; unauthorized access is denied; access is logged and can be audited. |
| 4 | **Scalability** | Additional CoCs can be onboarded without architectural changes, scaling from a single community to a statewide deployment. |

See [Section 10 (Quality Requirements)](10-quality.md) for detailed quality scenarios.

## 1.3 Stakeholders

| Role | Architectural Expectation |
| --- | --- |
| **HMIS End Users** | Responsive, intuitive interface that does not impede data entry workflows. |
| **HMIS Leads** | Reliable, auditable reports that satisfy HUD submission requirements. |
| **System Administrators** | Manageable configuration for user access, data sources, and system behavior without code changes. |
| **Analysts & Researchers** | Stable, well-modeled analytics data that supports ad-hoc querying and dashboards. |
| **Open Path Engineering Team** | Modular, well-documented codebase that supports independent feature development and safe deployments. |
| **Upstream Data Partners** | Stable ingestion interfaces (S3, API) with clear data format contracts. |

See [Context and Scope](03-context.md) for detailed user roles and system interfaces. See the [Open Path charter](https://docs.google.com/document/d/1Y8pHuWvb0CdUDf2v-y1sJKmjvZkFQ-dcitB35s9gwlI/edit?usp=sharing) for organizational governance.
