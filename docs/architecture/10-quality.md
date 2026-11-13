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

Each row states the property required, not the situation that tests it — situations are [10.2](#102-quality-scenarios)'s job. The five goal rows also reference [Section 1.2](01-introduction.md#12-quality-goals), which carries each goal's driving scenario; the secondary rows stand alone, since Section 1 omits them.

| Tier | Category | Label | Requirement |
| --- | --- | --- | --- |
| Goal 1 | **Extensibility & Local Configuration** | #suitable #flexible #maintainable | New HUD standards and community-specific data elements and workflows are accommodated by adding drivers and configuration, not by modifying existing drivers or core domain models. Goal — see [§1.2](01-introduction.md#12-quality-goals); [Q-1–Q-6](#extensibility--local-configuration-suitable-flexible-maintainable). |
| Goal 2 | **Data Integrity & Auditability** | #reliable #suitable | Warehouse records and report figures are traceable to their contributing source records, and remain so after the underlying data changes, after a deletion, and after the reporting specification is superseded. Goal — see [§1.2](01-introduction.md#12-quality-goals); [Q-7–Q-13](#data-integrity--auditability-reliable-suitable). |
| Goal 3 | **Client Protection & Fair Access** | #secure #reliable #suitable | Disclosure of client PII is deny-by-default, with community policy layered on that default rather than assumed by it, and every access is logged. Allocation outcomes are recorded, not recollected. Goal — see [§1.2](01-introduction.md#12-quality-goals); [Q-14–Q-20](#client-protection--fair-access-secure-reliable-suitable). |
| Goal 4 | **Availability & Resilience** | #reliable #operable | The HMIS data-entry interface is available and responsive through operating hours independently of concurrent batch work, and warehouse data is restorable after catastrophic infrastructure failure. No recovery time objective is committed — see Q-22. Goal — see [§1.2](01-introduction.md#12-quality-goals); [Q-21, Q-22](#availability--resilience-reliable-operable). |
| Goal 5 | **Data Scalability** | #flexible #efficient | Deployment scale, from a single organization to multi-state, and years of accumulated data are absorbed without architectural change; storage growth is bounded by a retention policy rather than unbounded retention. Goal — see [§1.2](01-introduction.md#12-quality-goals); [Q-23, Q-24](#data-scalability-flexible-efficient). |
| Secondary | **Operational Self-Sufficiency** | #usable #operable | Administrators perform routine, common operations themselves without code changes or deployments. Failed background work is diagnosable from its logs by the person who has to act on it. Infrequent or one-time tasks may still require engineering support. |
| Secondary | **Interoperability** | #suitable | HUD CSV exchange goes both ways: exports conform to the published specification and are consumable by external systems without transformation, and any CSV set conforming to a supported HUD specification imports without transformation. |
| Secondary | **Usability** | #usable #reliable | Data entry workflows do not impede front-line staff productivity. Long-running operations report progress and completion. A transient network failure during data entry does not silently discard entered data, and is surfaced to the user as a recoverable condition. |

## 10.2 Quality Scenarios

One group per quality, in the tier order of 10.1: the five goals first, then the three secondary requirements. Scenario IDs are assigned on creation and never reused, and are cited from [Section 1.2](01-introduction.md#12-quality-goals) and [Section 4.1](04-solution-strategy.md#41-quality-goals--solution-approaches).

### Extensibility & Local Configuration (#suitable #flexible #maintainable)

| ID | Stimulus | Context | Metric |
| --- | --- | --- | --- |
| Q-1 | HUD publishes updated HMIS Data Standards (e.g., new CSV fields, revised project types). | Annual HMIS Data Standards release, in effect for the new standards year. | Changes are deployed to staging by September 1 and to production by October 1, ahead of HUD's compliance deadline. |
| Q-2 | HUD publishes a new or revised reporting specification (e.g., updated APR logic). | Federal fiscal year reporting cycle. | The updated report's generated tables match the HUD Datalab testkit reference for that fiscal year, verified in CI, except for a tracked list of cells with documented reference or spec discrepancies. |
| Q-3 | A community needs to capture a local data point that is not part of the HUD Data Standards. | Local reporting or program need, not a HUD standards change. | The field is added as a custom data element (a definition plus its stored values) through configuration, with no schema migration and no change to core domain models. |
| Q-4 | A new HUD report type is required. | New federal reporting mandate. | The report is implemented as an isolated driver module without modifying core warehouse models or existing reports. |
| Q-5 | A community needs a custom Coordinated Entry assessment workflow. | Each CoC sets its own CE assessment and prioritization rules; they vary between communities and there is no shared default. | The workflow is configured through form definitions and CE settings without forking application code. |
| Q-6 | A data source is still exporting an older HUD CSV specification while others have moved to the current one. | Staggered vendor adoption across a multi-source deployment during a standards transition. | Both formats import into the same warehouse concurrently, each handled by its own importer driver — one per HUD CSV standard year — with no change to core models and no fork. |

### Data Integrity & Auditability (#reliable #suitable)

| ID | Stimulus | Context | Metric |
| --- | --- | --- | --- |
| Q-7 | An HMIS Lead questions a specific figure in a generated HUD report. | Post-generation review before HUD submission. | The user can drill into the report to see the exact client records and data sources that contributed to the figure. |
| Q-8 | A data source re-submits a corrected CSV export. | Routine data correction after initial import. | Re-import replaces the affected source records; the warehouse re-normalizes without duplicating or orphaning destination records. |
| Q-9 | An upstream vendor's export contains records that match existing warehouse clients. | Nightly or scheduled import of a multi-source deployment. | The deduplication engine links matching records to existing warehouse clients rather than creating duplicates. |
| Q-10 | An HMIS Lead loads a HUD report for a previous fiscal-year specification. | Fields or programming specs for the the current specification has moved on. | The report loads its original figures, its is unchanged by the new specification and still true to the specification that produced it. |
| Q-11 | A source field that feeds service history changes — an exit date is added, a project type is reclassified, night-by-night service rows are deleted, or a destination client is merged. | Routine re-import or nightly project cleanup following an upstream correction. | The affected enrollment's service history rows and homeless/literally-homeless flags are regenerated to match the new source state within one daily cycle; a drift check finds zero mismatches between source and derived rows. |
| Q-12 | An import's precalculated change counts exceed a configured add/remove threshold — e.g. a truncated or partial CSV export. | Automated nightly import of a multi-source deployment, where a bad export would otherwise replace-and-soft-delete large numbers of warehouse rows. | Ingest does not run; the import halts in a paused state with zero in-scope warehouse rows soft-deleted, and proceeds only after an explicit resume — no data is lost in the interim. |
| Q-13 | A user merges two or more client records representing the same person. | HMIS client merge from the profile or admin tool; all clients share a data source. | Every related record repoints to the retained client with none orphaned or lost; deduplication-eligible types collapse while enrollments are preserved; the merge audit records enough to fully restore the prior state via the undo job; the retained client remains findable by every pre-merge HMIS ID and name. |

### Client Protection & Fair Access (#secure #reliable #suitable)

| ID | Stimulus | Context | Metric |
| --- | --- | --- | --- |
| Q-14 | A user with no permission to view a client's PII attempts to view the client record. | Normal application use. | Only non-identifying information is returned, the name, DOB, and social redacted. |
| Q-15 | A user in CoC A attempts to access client data belonging to CoC B. | Multi-CoC deployment with data partitioning. | The system enforces CoC-scoped visibility; the user sees no indication that the record exists. |
| Q-16 | A security auditor requests a log of all access to a specific client's record. | Compliance audit or incident investigation. | The system produces a complete access log including user, timestamp, and action for the requested client. |
| Q-17 | An attacker obtains a stolen staff credential and attempts to read client PII at scale. | Internet-facing deployment holding PII; compromised staff account. | Client data is restricted; the session sees no more than that user's permission grants and CoC scope allow; and every record accessed is recorded in the audit log, so the affected clients can be identified and notified. |
| Q-18 | A client matched to a housing vacancy through Coordinated Entry is declined for it, and the CoC is asked to account for the outcome. | Referral review, client grievance, or CoC-level equity analysis of who is passed over. | The decline is reconstructable from recorded data: the match, the declining program, and the stated reason are stored on the match record and are reportable by reason and by agency. |
| Q-19 | A Coordinated Entry pool is evaluated against a client universe with layered eligibility and priority rules at unit-group, project, and organization scope. | Waitlist-enabled project with overlapping rules from multiple owners — the output decides who is offered a vacancy. | Every client satisfying the combined eligibility requirement appears as a candidate and no non-matching client does; priority order matches the selected scheme, including owner precedence (unit-group over project over organization) and the id tie-break; the result is identical whether reached by incremental or full processing. |
| Q-20 | A HUD CSV export runs for a data source containing a client flagged for external-data-sharing exclusion, or a client created within the embargo window. | Multi-source deployment with external-data-sharing exclusion enabled; every exporter that applies the export scope. | The excluded client appears in no file of the export — absent from Client, Enrollment, and Exit, and from every assessment and service record that joins through the enrollment scope; a newly created client is likewise absent until the embargo lapses. |

### Availability & Resilience (#reliable #operable)

| ID | Stimulus | Context | Metric |
| --- | --- | --- | --- |
| Q-21 | Front-line staff load and use the HMIS data-entry interface. | Peak intake hours, with imports and large reports running concurrently in the Warehouse. | The data-entry interface stays available and responsive; concurrent Warehouse workloads do not impede HMIS operation. |
| Q-22 | A catastrophic database failure destroys or corrupts warehouse data. | Rare RDS-level fault; routine record deletion is not in scope here, as application deletes are soft deletes and are reversible in place. | Data is restored from backup, and data loss is bounded to 24 hours. |

### Data Scalability (#flexible #efficient)

| ID | Stimulus | Context | Metric |
| --- | --- | --- | --- |
| Q-23 | A statewide deployment accumulates ten years of nightly imports. | Long-running multi-source deployment; every import retains the loaded and imported rows behind each warehouse record. | Storage growth stays bounded without re-architecting: the per-record import audit trail is pruned on a retention policy rather than kept indefinitely — a scheduled cleanup job retains a configured number of recent versions past a retention date. |
| Q-24 | A report aggregates millions of disability or service rows across a large deployment. | System-wide report over years of accumulated data. | Peak memory stays bounded regardless of result-set size — rows are streamed or processed in batches rather than loaded at once — with a footprint under 6 GB. |

### Operational Self-Sufficiency (#usable #operable)

| ID | Stimulus | Context | Metric |
| --- | --- | --- | --- |
| Q-25 | A new CoC is onboarded to an existing deployment. | Statewide expansion. | The CoC is configured (data source, user groups, visibility rules) through administrative UI without code changes or architectural modification. |
| Q-26 | A system administrator needs to grant a new user access scoped to specific projects. | Staff onboarding. | Access is granted through the administrative UI with appropriate role and project scope; no developer intervention required. |
| Q-27 | A background import job fails due to malformed source data. | Automated nightly processing. | The failure is logged with actionable detail; other queued jobs continue processing; the administrator is notified. |
| Q-28 | A nightly import's per-CSV row counts cross a threshold an administrator set (e.g. too few new services, too many enrollments removed). | Data-quality monitoring of a recurring multi-source import. | The administrator configures per-data-source, per-CSV thresholds and notification recipients through the admin UI; when a completed import breaches one, the configured recipients are notified — no code change or deployment. |

### Interoperability (#suitable)

| ID | Stimulus | Context | Metric |
| --- | --- | --- | --- |
| Q-29 | An external system or migration tool consumes a HUD CSV export produced by the platform. | Data portability or system migration. | The exported CSV files conform to the published HUD CSV specification and pass validation by the receiving system. |
| Q-30 | An external HMIS or vendor supplies a HUD CSV export for the platform to consume. | Onboarding a new data source or migrating from another system. | Any CSV set conforming to a supported HUD CSV specification imports without transformation; the platform accepts the published format as produced by the source system. |
| Q-31 | An HMIS Lead downloads a generated HUD report as its submission file to upload to HUD's portal (e.g. the SPM HDX 2.0 CSV, the LSA CSV set, or the APR/CAPER table bundle). | End-of-cycle HUD reporting; the file is uploaded to HDX 2.0 / Sage, not re-imported here. | The exported file conforms to HUD's published CSV export specification for that report — column names, order, and per-field data types — and is accepted by the HUD portal without transformation. |

### Usability (#usable #reliable)

| ID | Stimulus | Context | Metric |
| --- | --- | --- | --- |
| Q-32 | A case manager begins a new client intake (project enrollment, basic demographics, initial assessment). | Walk-in at an emergency shelter during peak hours. | The case manager completes the intake workflow and saves the record within 10 minutes using only the standard UI, without requiring help documentation or support. |
| Q-33 | An HMIS Lead generates a standard HUD report for the first time. | New staff member with HMIS experience but no prior training on this platform. | The user locates the report interface, selects the correct parameters, and initiates generation within 5 minutes without external assistance. |
| Q-34 | A transient network failure interrupts a front-line worker — a dropped request while a form loads, or while a completed form is being saved. | Flaky connectivity at an intake site; a single dropped request rather than a sustained outage. | A failed data load recovers without user action, retried automatically with backoff; a failed save does not discard the entered values — the form stays populated and shows a recoverable error, so re-submitting once connectivity returns succeeds without re-keying. |
