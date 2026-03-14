# 12 Glossary

[← Previous: 11 Risks and Technical Debts](11-risks.md) | [Table of Contents](README.md)

This section defines domain and technical terms used throughout the architecture documentation.

### HMIS Domain

| Term | Definition |
| --- | --- |
| **BNL** | By-Name List. A real-time list of individuals experiencing homelessness, used for prioritization and housing matching. |
| **BOS** | Balance of State. A CoC that covers the geographic area of a state not included in other CoCs. |
| **CAS** | Coordinated Access System. The legacy housing matching application within Open Path. See [5.5 CAS Legacy](05-building-blocks/05-5-cas-legacy.md). |
| **CE** | Coordinated Entry. A standardized process for assessing, prioritizing, and referring individuals to housing and services. |
| **CLS** | Current Living Situation. An assessment type recorded during an enrollment to track a client's housing status over time. |
| **CoC** | Continuum of Care. A regional or local planning body that coordinates housing and services funding for homeless families and individuals. |
| **DQ** | Data Quality. Refers to the completeness, accuracy, and timeliness of HMIS data. The platform surfaces DQ issues from upstream sources rather than correcting them. |
| **HMIS** | Homeless Management Information System. An information technology system used to collect client-level data on the provision of housing and services to individuals and families experiencing homelessness. |
| **HoH** | Head of Household. The primary member of a household enrollment, to whom household-level data is attached. |
| **HUD** | U.S. Department of Housing and Urban Development. Defines the HMIS Data Standards and reporting requirements. |
| **ROI** | Release of Information. A consent form authorizing the sharing of a client's PII between organizations. Enforced as an access control mechanism in the platform. |
| **SA** | System Administrator. Manages the HMIS locally — user access, data sources, and system configuration. |
| **VA** | U.S. Department of Veterans Affairs. Relevant to veteran-specific project types (SSVF) and reporting. |
| **VI-SPDAT** | Vulnerability Index — Service Prioritization Decision Assistance Tool. A standardized assessment used to prioritize clients for housing interventions. |

### HUD Project Types

These appear as the `ProjectType` field in the [HMIS Data Model](08-concepts/08-1-hmis-data-model.md) and determine reporting and workflow behavior.

| Term | Definition |
| --- | --- |
| **ES** | Emergency Shelter. |
| **HOPWA** | Housing Opportunities for Persons with AIDS. |
| **OPH** | Other Permanent Housing. |
| **PATH** | Projects for Assistance in Transition from Homelessness. |
| **PSH** | Permanent Supportive Housing. |
| **RHY** | Runaway and Homeless Youth. |
| **RRH** | Rapid Rehousing. |
| **SSO** | Supportive Services Only. |
| **SSVF** | Supportive Services for Veteran Families. |
| **TH** | Transitional Housing. |
| **YHDP** | Youth Homeless Demonstration Program. |

### HUD Reports & Submissions

These are the mandated reports referenced throughout the [Reporting components](05-building-blocks/05-4-warehouse-application.md).

| Term | Definition |
| --- | --- |
| **APR** | Annual Performance Report. A HUD-mandated report on project-level outcomes. |
| **CAPER** | Consolidated Annual Performance and Evaluation Report. Similar to the APR, for ESG-funded projects. |
| **HDX** | Homelessness Data Exchange. HUD's online portal for submitting reports (LSA, SPM, HIC, PIT). |
| **HIC** | Housing Inventory Count. An inventory of beds and units available for people experiencing homelessness. |
| **LSA** | Longitudinal System Analysis. A HUD report analyzing client movement through the homeless services system over time. |
| **PIT** | Point-in-Time count. A count of sheltered and unsheltered people experiencing homelessness on a single night in January. |
| **SPM** | System Performance Measures. HUD-defined metrics for evaluating CoC-level system effectiveness. |

### Platform-Specific Terms

| Term | Definition |
| --- | --- |
| **Data Source** | A configured origin for HMIS data (e.g., an external HMIS vendor, the platform's own HMIS). Combined with a record's ID, it forms the composite unique identity for each record in the warehouse. |
| **Destination Record** | A unified, deduplicated warehouse record created by linking one or more source records to a single client identity. |
| **Driver Module** | An isolated feature directory under `/drivers/[module]` that mirrors the Rails application structure. Used to encapsulate large features (e.g., specific HUD reports, CE workflows) without polluting the core codebase. |
| **Source Record** | A record stored in HUD-schema source tables exactly as received from a data source, before normalization or deduplication. |
| **Warehouse Client** | The unified client entity in the warehouse, created by deduplication. Links back to all contributing source records across data sources. |
