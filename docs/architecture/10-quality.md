# 10 Quality Requirements

[← Previous: 9 Architecture Decisions](09-decisions.md) | [Table of Contents](README.md) | [Next: 11 Risks and Technical Debts →](11-risks.md)

This section holds the platform's complete set of quality requirements and the scenarios that make each one testable.

Labels are the nine [Q42](https://quality.arc42.org) dimensions, defined below, and a quality may carry more than one. The dimensions overlap by design — tag every dimension that genuinely applies, not just one. When `#suitable` seems to be the only fit, check whether a more specific dimension (often `#reliable` or `#usable`) actually applies first.

The tags live only in this section. Sections 1.2 and 4.1 reference each goal by name and scenario ID, not by tag.

| Dimension | Meaning | Use it for — and the line that separates it from its neighbour |
| --- | --- | --- |
| `#reliable` | Performs its specified function under specified conditions without failure. | Accuracy, availability, fault tolerance, auditability, reproducibility, correctness, consistency. |
| `#usable` | Easy to learn, operate, and satisfying for whoever interacts with it. | Ease of use — for end users **and** for admins (self-service config) and developers (readable code). Accessibility lives here. Not "the feature works" (that is `#suitable`). |
| `#suitable` | Right and appropriate for its purpose — functional suitability. | Conformance to a spec, correctness, completeness. The deliberate catch-all: use it, but name the specific quality where you can. |
| `#safe` | Avoids states that endanger life, health, property, or environment. | Safety-/life-critical behaviour only. Not currently a driver for this platform. |
| `#flexible` | Adapts to **external** change — new requirements, context, or environment. | Scaling, new deployment targets, absorbing new HUD standards. Contrast `#maintainable`: flexible is adapting to the outside world, maintainable is changing the code. |
| `#secure` | Prevents unauthorized access; protects confidentiality, integrity, availability. | Authn/authz, encryption, partitioning, attack resistance. Standards-driven (GDPR, HIPAA-adjacent) — a signal to check compliance, not just architecture. |
| `#efficient` | Produces results with little waste of time, resources, or money. | Latency, throughput, resource/storage use. Name the facet (runtime vs. dev speed vs. cost). Not the same as effective. |
| `#maintainable` | Economical, predictable **internal** change over the system's lifetime. | Analyzability, modifiability, testability of the code. The developer-facing counterpart to `#flexible`. |
| `#operable` | Easy to build, install, deploy, configure, operate/monitor, and decommission. | Anchored on deployability and operations: backup/restore, monitoring, job diagnosability. If there is no deploy/operate content, it does not apply. |

Two tiers:

- **Quality goals** (tier `Goal 1`–`Goal 5`) — the ranked architectural drivers. These are the goals named in [Section 1.2](01-introduction.md#12-quality-goals); a trade-off is resolved in their favour, in priority order. [Section 4.1](04-solution-strategy.md#41-quality-goals--solution-approaches) states the solution approach for each.
- **Secondary quality requirements** (tier `Secondary`) — genuine acceptance criteria the platform must meet, but not drivers. They constrain implementation, not the top-level architecture, and they are unranked among themselves.

## 10.1 Quality Requirements Overview

| Tier | Category | Label | Requirement |
| --- | --- | --- | --- |
| Goal 1 | **Extensibility & Local Configuration** | #suitable #flexible #maintainable | Data structures and report outputs conform to the published HUD HMIS Data Standards and reporting specifications, and new or revised standards are in production before HUD's stated compliance deadline. New HUD report types, custom data elements, custom forms, and local workflow variations (e.g., Coordinated Entry) arrive as isolated driver modules or as configuration — without modifying core domain models, without touching existing reports, and without forking any installation. |
| Goal 2 | **Data Integrity & Auditability** | #reliable #suitable | Every warehouse record and every report figure is traceable to the source records that produced it, and remains auditable after the underlying data changes. Source data is preserved in its original form, corrected exports re-import without duplicating or orphaning records, routine deletions are reversible because records are soft-deleted rather than destroyed, and a report generated under a prior fiscal-year specification still reproduces its original figures because superseded report generators are retained rather than replaced. |
| Goal 3 | **Client Protection & Fair Access** | #secure #reliable | Disclosure of client PII defaults to deny: a user sees a client's identifying data only where a permission grant covers it, and a community's disclosure policy — however narrow or however broad — is configuration layered on that default rather than assumed by it. Every access is logged. In multi-CoC deployments, one CoC's data is not visible to another. PII is encrypted in transit and at rest, and a stolen credential exposes no more than that user's authorized scope. Allocation outcomes are recorded rather than recollected, so a client passed over for a housing vacancy can be accounted for from recorded data. |
| Goal 4 | **Availability & Resilience** | #reliable #operable | Availability and recovery together: the HMIS data-entry interface remains available and responsive to front-line staff during operating hours, and planned maintenance and heavy background work do not take it offline; warehouse data is backed up on a regular schedule and can be restored after a catastrophic infrastructure failure. No recovery objective is committed here — see Q-23. |
| Goal 5 | **Data Scalability** | #flexible #efficient | The platform supports deployments of varying scale, ranging from a single municipality to multi-state organizations, and absorbs years of accumulating data volume without architectural change. Bulk imports and large reports do not degrade interactive use, and storage growth stays bounded — the retained audit trail of imported records is pruned on a retention policy rather than kept indefinitely. |
| Secondary | **Operational Self-Sufficiency** | #usable #operable | Administrators perform routine, common operations themselves without code changes or deployments. Failed background work is diagnosable from its logs by the person who has to act on it. Infrequent or one-time tasks may still require engineering support. |
| Secondary | **Interoperability** | #suitable | HUD CSV exports conform to the published specification and are consumable by external systems without transformation. |
| Secondary | **Usability** | #usable #operable | Data entry workflows do not impede front-line staff productivity. Long-running operations report progress and completion. |

## 10.2 Quality Scenarios

One group per quality, in the tier order of 10.1: the five goals first, then the three secondary requirements. Scenario IDs are assigned on creation and never reused, and are cited from [Section 1.2](01-introduction.md#12-quality-goals) and [Section 4.1](04-solution-strategy.md#41-quality-goals--solution-approaches).

### Extensibility & Local Configuration (#suitable #flexible #maintainable)

| ID | Stimulus | Context | Metric |
| --- | --- | --- | --- |
| Q-1 | HUD publishes updated HMIS Data Standards (e.g., new CSV fields, revised project types). | Annual HMIS Data Standards release, in effect for the new standards year. | Changes are deployed to staging by September 1 and to production by October 1, ahead of HUD's compliance deadline. |
| Q-2 | HUD publishes a new or revised reporting specification (e.g., updated APR logic). | Federal fiscal year reporting cycle. | The updated report's generated tables match the HUD Datalab testkit reference for that fiscal year, verified in CI, except for a tracked list of cells with documented reference or spec discrepancies. |
| Q-3 | A community needs to capture a local data point that is not part of the HUD Data Standards. | Local reporting or program need, not a HUD standards change. | The field is added as a custom data element (a definition plus its stored values) through configuration, with no schema migration and no change to core domain models. |
| Q-13 | A new HUD report type is required. | New federal reporting mandate. | The report is implemented as an isolated driver module without modifying core warehouse models or existing reports. |
| Q-14 | A community needs a custom Coordinated Entry assessment workflow. | Each CoC sets its own CE assessment and prioritization rules; they vary between communities and there is no shared default. | The workflow is configured through form definitions and CE settings without forking application code. |
| Q-24 | A data source is still exporting an older HUD CSV specification while others have moved to the current one. | Staggered vendor adoption across a multi-source deployment during a standards transition. | Both formats import into the same warehouse concurrently, each handled by its own importer driver — one per HUD CSV standard year — with no change to core models and no fork. |

### Data Integrity & Auditability (#reliable #suitable)

| ID | Stimulus | Context | Metric |
| --- | --- | --- | --- |
| Q-4 | An HMIS Lead questions a specific figure in a generated HUD report. | Post-generation review before HUD submission. | The user can drill into the report to see the exact client records and data sources that contributed to the figure. |
| Q-5 | A data source re-submits a corrected CSV export. | Routine data correction after initial import. | Re-import replaces the affected source records; the warehouse re-normalizes without duplicating or orphaning destination records. |
| Q-6 | An upstream vendor's export contains records that match existing warehouse clients. | Nightly or scheduled import of a multi-source deployment. | The deduplication engine links matching records to existing warehouse clients rather than creating duplicates. |
| Q-25 | An HMIS Lead re-runs a HUD report for a reporting period governed by a superseded fiscal-year specification. | Audit, resubmission, or year-over-year comparison after the current specification has moved on. | The report reproduces its original figures, because the generator for each fiscal-year specification is retained alongside the current one rather than replaced — every superseded year's generator ships side by side with the latest. |

### Client Protection & Fair Access (#secure #reliable)

| ID | Stimulus | Context | Metric |
| --- | --- | --- | --- |
| Q-7 | A user with no permission grant covering a client attempts to view that client's PII. | Normal application use. | Access is denied and only non-identifying information is returned. |
| Q-8 | A user in CoC A attempts to access client data belonging to CoC B. | Multi-CoC deployment with data partitioning. | The system enforces CoC-scoped visibility; the user sees no indication that the record exists. |
| Q-9 | A security auditor requests a log of all access to a specific client's record. | Compliance audit or incident investigation. | The system produces a complete access log including user, timestamp, and action for the requested client. |
| Q-21 | An attacker obtains a stolen staff credential and attempts to read client PII at scale. | Internet-facing deployment holding PII; credential leak or phished staff account. | PII is encrypted in transit and at rest; the session sees no more than that user's permission grants and CoC scope allow; and every record accessed is recorded in the audit log, so the affected clients can be identified and notified. |
| Q-26 | A client matched to a housing vacancy through Coordinated Entry is declined for it, and the CoC is asked to account for the outcome. | Referral review, client grievance, or CoC-level equity analysis of who is passed over. | The decline is reconstructable from recorded data rather than recollection: the match, the declining program, and the stated reason are stored on the match record and are reportable by reason and by agency. |

### Availability & Resilience (#reliable #operable)

| ID | Stimulus | Context | Metric |
| --- | --- | --- | --- |
| Q-22 | Front-line staff load and use the HMIS data-entry interface. | Peak intake hours, with imports and large reports running in the background. | The data-entry interface stays available and responsive; background work and planned maintenance do not take it offline. No platform-wide availability percentage is committed: availability targets are per-deployment contractual terms, and a deployment that has agreed one measures against it. |
| Q-23 | A catastrophic database failure destroys or corrupts warehouse data. | Rare RDS-level fault; routine record deletion is not in scope here, as application deletes are soft deletes and are reversible in place. | Data is restored from backup, and data loss is bounded by the backup interval in effect. No RTO or RPO is committed: backup schedule and retention are set on the managed database instance by infrastructure configuration held outside this repository. |

### Data Scalability (#flexible #efficient)

| ID | Stimulus | Context | Metric |
| --- | --- | --- | --- |
| Q-11 | A large upstream partner submits a bulk CSV export. | Scheduled nightly import. | The import runs as background processing and does not take the interactive application offline or degrade its responsiveness for the duration. No specific response-time target is committed. |
| Q-12 | An HMIS Lead generates a system-wide SPM report covering multiple CoCs. | Annual reporting period. | The report executes as a background job and reports periodic progress (percentage or phase); the user can navigate away and is notified on completion. No specific completion-time target is committed. |
| Q-27 | A statewide deployment accumulates ten years of nightly imports and service transactions. | Long-running multi-source deployment; every import retains the loaded and imported rows behind each warehouse record. | Reporting stays within its stated time budget and storage growth stays bounded without re-architecting: the per-record import audit trail is pruned on a retention policy rather than kept indefinitely — a scheduled cleanup job retains a configured number of recent versions past a retention date. |

### Operational Self-Sufficiency (#usable #operable)

| ID | Stimulus | Context | Metric |
| --- | --- | --- | --- |
| Q-10 | A new CoC is onboarded to an existing deployment. | Statewide expansion. | The CoC is configured (data source, user groups, visibility rules) through administrative UI without code changes or architectural modification. |
| Q-16 | A system administrator needs to grant a new user access scoped to specific projects. | Staff onboarding. | Access is granted through the administrative UI with appropriate role and project scope; no developer intervention required. |
| Q-17 | A background import job fails due to malformed source data. | Automated nightly processing. | The failure is logged with actionable detail; other queued jobs continue processing; the administrator is notified. |

### Interoperability (#suitable)

| ID | Stimulus | Context | Metric |
| --- | --- | --- | --- |
| Q-15 | An external system or migration tool consumes a HUD CSV export produced by the platform. | Data portability or system migration. | The exported CSV files conform to the published HUD CSV specification and pass validation by the receiving system. |

### Usability (#usable #operable)

| ID | Stimulus | Context | Metric |
| --- | --- | --- | --- |
| Q-18 | A case manager begins a new client intake (project enrollment, basic demographics, initial assessment). | Walk-in at an emergency shelter during peak hours. | The case manager completes the intake workflow and saves the record within 10 minutes using only the standard UI, without requiring help documentation or support. |
| Q-19 | An HMIS Lead generates a standard HUD report for the first time. | New staff member with HMIS experience but no prior training on this platform. | The user locates the report interface, selects the correct parameters, and initiates generation within 5 minutes without external assistance. |
