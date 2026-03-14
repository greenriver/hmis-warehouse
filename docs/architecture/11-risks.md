# 11 Risks and Technical Debts

[← Previous: 10 Quality Requirements](10-quality.md) | [Table of Contents](README.md) | [Next: 12 Glossary →](12-glossary.md)

This section lists identified architectural risks and technical debts, ordered by priority.

## 11.1 Technical Risks

| # | Risk | Impact | Mitigation |
| --- | --- | --- | --- |
| R-1 | **CAS direct database coupling.** The legacy CAS application bypasses the Warehouse API and connects directly to the Warehouse database. | Schema changes in the Warehouse can break CAS without warning. Shared-database integration makes it difficult to reason about data ownership, enforce access controls, or evolve either system independently. | Planned consolidation of CAS matching functionality into the modern Warehouse Coordinated Entry module. See [5.5 CAS Legacy](05-building-blocks/05-5-cas-legacy.md). |
| R-2 | **HUD compliance deadline pressure.** HUD publishes Data Standards and reporting specification updates that must be implemented by fixed deadlines. | Late compliance risks federal funding for CoC partners. The monolith's size can slow implementation of cross-cutting standards changes. | The driver module pattern isolates report implementations. HUD CSV 1:1 source tables reduce the surface area of schema changes. Data-driven form definitions allow collection changes via configuration. |
| R-3 | **Deduplication accuracy.** Cross-source fuzzy matching is inherently imperfect. | False positives (merging distinct clients) corrupt client records. False negatives (failing to link the same client) fragment service history and undermine reporting accuracy. | Deduplication links are maintained separately from source records, so false positives can be unlinked without data loss. Source records are always preserved. Manual review workflows support correction. |
| R-4 | **Upstream data quality.** The platform preserves data from external HMIS sources as-is to provide transparency into data quality issues at their source. | HMIS Leads must understand that DQ issues in reports may originate from upstream systems, not the platform itself. | DQ dashboards give HMIS Leads visibility into upstream issues. Data collected directly through the platform is validated at the point of entry. See [2.3 Conventions](02-constraints.md). |
| R-5 | **Dynamic language runtime.** The Warehouse is built in Ruby on Rails, which lacks static typing and has higher per-request overhead than compiled alternatives. | Type-related defects may not surface until runtime. CPU-bound operations (reporting, deduplication) can be slower than in statically typed or compiled languages. | Actively expanding automated test coverage (including AI-assisted test generation) to catch defects earlier. Performance-critical paths use background processing to avoid impacting interactive response times. The driver module pattern keeps the test surface manageable. |
| R-6 | **Historical data storage growth.** The source-preserving warehouse retains all ingested data across data sources, and time-series records (enrollments, services, assessments) accumulate indefinitely. | Database storage requirements grow with each import cycle. Large tables impact query performance for reporting and deduplication. | Actively pursuing archival of historical data to S3, reducing storage requirements for aged records while preserving access for auditing and compliance. |

## 11.2 Technical Debts

| # | Debt | Impact | Status |
| --- | --- | --- | --- |
|  | | | |

See the GitHub project board for additional issues labeled as technical debt.
