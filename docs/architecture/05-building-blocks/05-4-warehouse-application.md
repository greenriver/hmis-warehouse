# 5.4 Warehouse Application

[← 5.3 Authentication & Identity](05-3-authentication-identity.md) | [Table of Contents](../README.md) | [Next: 5.5 CAS Legacy →](05-5-cas-legacy.md)

This document shows the internal components of the Warehouse Application container.

## Technical Stack
- **Framework**: Ruby on Rails
- **Language**: Ruby
- **Database**: PostgreSQL
- **Background Processing**: Delayed Job
- **View Layer**: HAML (for Administrative UI)
- **API**: GraphQL (serving the HMIS Frontend)

## HMIS & Data Collection
This area focuses on how data is captured via the interactive frontend and public forms.

```mermaid
flowchart TB
    HMIS_FE["HMIS Frontend (React SPA)"]
    S3_PUBLIC["S3 Public Hosting (Forms)"]

    subgraph WAREHOUSE["Warehouse Application"]
        subgraph hmis ["HMIS Module"]
            HMIS_API["HMIS GraphQL API"]
            FORM_DEFS["Custom Form Definitions"]
            CE["Coordinated Entry"]
            PUB_FORMS["Public Forms"]
            DOCS["Document Management"]
        end
    end

    WH_DB["Warehouse Database (PostgreSQL)"]

    HMIS_FE -- "GraphQL" --> HMIS_API
    HMIS_API -- "Writes to source tables" --> WH_DB

    CE -- "Referral state" --> HMIS_API
    FORM_DEFS -. "Defines forms" .-> HMIS_API
    FORM_DEFS -. "Defines forms" .-> PUB_FORMS
    PUB_FORMS -- "Static HTML" --> S3_PUBLIC

    DOCS -- "S3 Object IDs" --> HMIS_API
```

### Components & Details
| Component | Responsibilities |
| --- | --- |
| **HMIS GraphQL API** | Serving the HMIS Frontend; manages direct data entry and service recording to HUD source tables. |
| **Custom Form Definitions** | Engine for configurable, HUD-compliant intake and assessment forms across interactive and public channels. |
| **Coordinated Entry (CE)** | Modern workflows for assessments, housing prioritization, and referral management. |
| **Public Forms** | Publishes static HTML forms to S3 for anonymous community data collection (e.g., PIT counts). |
| **Document Management** | Direct S3 client file storage and consent tracking with role-based access controls. |

## Warehouse Pipeline (Processing)
This area focuses on the ingestion of external data and the core normalization and deduplication process.

```mermaid
flowchart LR
    subgraph STAGING ["Staging Layers"]
        S3_INGEST["Ingestion Bucket (S3 CSV)"]
        S3_SUPP["Supplemental Bucket (S3 Bespoke)"]
        S3_PUBLIC["Public Form Submissions"]
    end

    subgraph WAREHOUSE_PIPELINE ["Warehouse Pipeline"]
        INGEST["External Data Ingestion"]
        DEDUP["Deduplication & Normalization"]
        COHORTS["Cohorts & Prioritization"]
    end

    WH_DB["Warehouse Database (PostgreSQL)"]
    CAS["CAS (Legacy Container)"]

    S3_INGEST -- "HUD CSV" --> INGEST
    S3_SUPP -- "Airflow Data" --> INGEST
    S3_PUBLIC -- "Form Data" --> INGEST

    INGEST -- "Load Source Tables" --> WH_DB
    DEDUP -- "Link Source to Destination" --> WH_DB
    COHORTS -- "Maintain Membership" --> WH_DB

    DEDUP --> COHORTS
    COHORTS -- "By-name Lists" --> CAS
```

### Components & Details
| Component | Responsibilities |
| --- | --- |
| **External Data Ingestion** | ETL pipelines for validating and loading HUD CSV exports, supplemental non-HMIS data (e.g., from Airflow), and public form submissions into source tables. |
| **Deduplication & Normalization** | Cross-source fuzzy matching and linking of source records to unique warehouse client entities. |
| **Cohorts & Prioritization** | Maintenance of system cohorts (e.g., veterans) and custom by-name lists for housing matching. |

## Reporting, Analytics & Governance
This area focuses on data output, administrative configuration, and access controls.

```mermaid
flowchart TB
    subgraph WAREHOUSE_ADMIN ["Administration & Output"]
        WEB_UI["Warehouse Web UI"]
        HUD_REPORT["HUD Reporting Engine"]
        WH_REPORTS["Warehouse Reports"]

        subgraph cross ["Cross-Cutting"]
            ACL["Access Control"]
            REFDATA["Reference Data"]
            PLATFORM["Platform Services"]
        end
    end

    WH_DB["Warehouse Database"]
    ANALYTICS_DB["Analytics Database"]
    S3_PUBLIC["S3 Public Reports"]

    WEB_UI -- "Configuration" --> REFDATA
    WEB_UI -- "Access Management" --> ACL

    HUD_REPORT -- "Denormalized Queries" --> WH_DB
    WH_REPORTS -- "Aggregated Queries" --> WH_DB
    WH_REPORTS -- "Publish" --> S3_PUBLIC

    ACL -- "Enforce ROI/Permissions" --> WH_DB
    WH_DB -- "DBT Transformation" --> ANALYTICS_DB
```

### Components & Details
| Component | Responsibilities |
| --- | --- |
| **Warehouse Web UI** | Administrative interface for platform configuration, data governance, and reporting access. |
| **HUD Reporting** | Mandated reporting engine (APR, CAPER, LSA, SPM) using denormalized service history. |
| **Warehouse Reports** | Performance dashboards and operational reports; select reports are published to S3 for public access. |
| **Access Control** | Role-based and relationship-based permission system scoped to user groups. Enforces client ROI rules and multi-CoC data partitioning. |
| **Platform Services** | Authentication, audit logging, background job orchestration, and administrative tools. |
