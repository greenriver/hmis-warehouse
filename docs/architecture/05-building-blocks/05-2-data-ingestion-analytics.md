# 5.2 Data Ingestion & Analytics

[← 5.1 Core Operations](05-1-core-operations.md) | [Table of Contents](../README.md) | [Next: 5.3 Authentication & Identity →](05-3-authentication-identity.md)

This view focuses on the ETL pipeline, supplemental data processing, and the community analytics stack (C4 Level 2).

```mermaid
flowchart LR
    UPSTREAM["Upstream Data Partners (HMIS, Referral, Bespoke)"]

    subgraph OP_INGEST ["Data Ingestion & Storage"]
        AIRFLOW["Apache Airflow (ETL Orchestration)"]
        S3_INGEST["Ingestion Bucket (S3 CSV)"]
        S3_SUPP["Supplemental Bucket (S3 Bespoke)"]
    end

    subgraph OP_TRANSFORM ["Transformation & Analytics"]
        WAREHOUSE["Warehouse Application (Ruby on Rails)"]
        DBT_LAYER["DBT (Data transformation)"]
        SUPERSET["Superset (Dashboards)"]
        
        WAREHOUSE_DB["Warehouse DB"]
        ANALYTICS_DB["Analytics DB"]
    end

    AR["Analysts & Researchers"]

    UPSTREAM -- "HUD CSV exports" --> S3_INGEST
    UPSTREAM -- "Raw bespoke data" --> AIRFLOW
    UPSTREAM -- "Direct API data" --> WAREHOUSE

    AIRFLOW -- "Transforms & writes" --> S3_SUPP

    WAREHOUSE -- "Ingests CSV" --> S3_INGEST
    WAREHOUSE -- "Ingests Supplemental" --> S3_SUPP
    WAREHOUSE -- "Persists records" --> WAREHOUSE_DB

    DBT_LAYER -- "Transforms source" --> WAREHOUSE_DB
    DBT_LAYER -- "Writes modeled data" --> ANALYTICS_DB
    SUPERSET -- "Queries" --> ANALYTICS_DB

    AR -- "Analyzes data" --> SUPERSET
```

### Containers & Details
| Container | Technology | Responsibilities |
| --- | --- | --- |
| **Apache Airflow** | Apache Airflow | Orchestrates ETL pipelines for "Supplemental HMIS Data" (e.g., criminal justice). |
| **DBT** | dbt | Runs scheduled transformations of warehouse data into analytics-ready datasets. |
| **Superset** | Apache Superset | Hosted dashboards for community-specific operational reporting. |
| **Ingestion Bucket** | S3 | Shared boundary where external providers deposit HUD CSV exports. |
| **Supplemental Bucket** | S3 | Storage for transformed non-HMIS data processed by Airflow. |
| **Analytics Database** | PostgreSQL | Optimized store for Superset queries, populated by DBT. |
