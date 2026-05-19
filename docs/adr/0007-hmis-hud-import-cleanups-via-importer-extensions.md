# ADR 0007: move OP HMIS HUD data cleanups to Importer Extensions

## Status

- Current Status: Proposed
- Date of last update: 2026-05-13
- Decision-makers: Dave, Theron, Elliot

## Context

### Why does data migrated into OP HMIS need extra cleanup?

Two things drive the same fixes:

1. **HMIS is stricter than the warehouse.** The Open Path HMIS app enforces invariants that HUD CSV or legacy warehouse data often violate (for example, missing `HouseholdID` values that the HMIS API will not resolve).

2. **We want migrated history to match “native” HMIS quality.** Before and after go-live, we normalize vendor-shaped data so it behaves like data entered in OP HMIS—computed fields consistent with the app (for example, **Monthly Total Income** matching the sum of detail columns), not only “good enough” for the application to work.

### What's wrong with our current process?

Setting up a new HMIS data source, or converting an existing warehouse data source to HMIS, is **time-consuming** and today relies heavily on **console work and internal runbooks** (one-off invocations of `HmisDataCleanup::Util`, manual ordering of jobs) to do all the cleanup necessary. Each time another HUD CSV file is imported into an HMIS data source, the cleanup needs to be performed again (sometimes for a subset of projects).

### Why add more extensions to the HMIS CSV import path?

This is the crux of this ADR. We know we need something better, but do we want to move these into the Importer?

We need a repeatable place for HUD cleanup. Not only for **HMIS launch** (today’s need), but also for continued HUD CSV imports into "live" HMIS data sources.

**Near-term:** Some CoCs want **ongoing HUD CSV imports into the same data source as live HMIS** (for example, a subset of projects still fed by a vendor CSV while the rest of the CoC is edited in the app). Today we often isolate that in a separate data source; demand is growing to import directly into HMIS. See issue: https://github.com/open-path/Green-River/issues/8017

**Longer-term:** Support **phased HMIS migration**, whereby agencies move to HMIS gradually, so for a while the HMIS data source may mix **nightly HUD imports for some projects** with **day-to-day HMIS use on others**.

Note: Those mixed models will eventually need **guards** (e.g. “imported” vs “live” projects so CSV does not clobber user-entered data). That is out of scope here; this ADR targets improving HMIS launch process first.

**Importer Extensions** already provide off-by-default, per data source levers for fixing data that would be better than one-off rake tasks that operators must remember to re-run after every import.

## Decision

### Importer-first HUD cleanup

This document argues for an **importer-leaning** approach to HMIS data clean-up. Specifically, adding more ImporterExtensions to replace existing functionality in the `HmisDataCleanup::Util` class.

Certain extensions might be required for HMIS-marked Data Sources (e.g. assigning Household ID), while others might be optional (but encouraged) data quality improvements. See **APPENDIX A** at the end of this file for a list.

We are happy with **importer extensions** so far. They are mostly very light-weight, though they are flexible enough (see the enrollment aggregator) that they can be slow. If they only read/update one row at a time, they are very fast. The code for importer extensions is stable. Eventually, we'd like to refactor the entire import process (maybe moving it to a tool more suited to the job, something like DBT) but we expect importer extensions will continue to exist in some format.

### Potential additional needs
We may need to make some enhancements to ImporterExtension:
- Structured per-extension summary  (e.g. # rows updated, logging sample of affected rows)
- Optional dry-run mode to report counts without mutating, for pre–go-live monitoring.
- Post-ingest extensions that don't operate on staging data

### Out of scope: generating HUD Intake/Exit Assessments

`MigrateAssessmentsJob` also needs to be run after import into an HMIS data source. It generates the HUD Intake/Update/Annual/Exit CustomAssessment records (and associated FormProcessor), grouping together related records by InformationDate and DataCollectionStage. We currently invoke this manually around HMIS migration.

**Why it does not fit `HmisCsvCleanup`**

- It **creates** HMIS application records, not row-level fixes on HUD CSV
- It can **delete** records when run with `delete_dangling_records` / `clobber`

**Recommended direction for discussion**

More discussion needed; calling this out-of-scope for this ADR. We may want to enqueue a process after import, or run something nightly.

## Consequences

### Positive

- HUD integrity fixes become **repeatable** with every import for customers that need them, including **live** HMIS sources receiving partial ongoing HUD feeds.
- Configuration is **data-source–local** (`import_cleanups`), supporting isolated behavior across installations.
- Operators get a **single pipeline** (import logs, staging → warehouse) instead of remembering separate console cleanups after each vendor drop.
- New extensions default **off**, limiting blast radius.
- Non-OP-HMIS-customers can also benefit from the cleanup routines. (At their own risk, as they will mask Vendor data quality issues.)

### Negative / risks

- Engineering cost to port `HmisDataCleanup::Util` logic to **staging** scopes and to keep behavior aligned with HUD expectations and tests.
- If some cleanups are **optional** we run the risk of needing to maintain the existing `HmisDataCleanup::Util` logic alongside the new importer extensions. Because customers may opt not to clean up certain things before launch, but after launch they decide they change their mind. We can't re-use the importer cleanup routines once the data is "live" (I think), so we would need 2 implementations.
  - **Mitigation**: It could be written such that the util could use the importer extension to do transformations that need to occur in both locations.
- Some fixes (personal ID alignment; clear ExportID) may **not** fit cleanly in pre-ingest `cleanup_data_set!`; split phases add complexity.
  - **Mitigation**: We could build a post-ingest extension mechanism to handle this and others that don't operate on staging data.
- `MigrateAssessmentsJob` auto-queue needs to be addressed separately

## Alternatives Considered

1. **Console-only / rake-only cleanups after import** — Preserves today’s `HmisDataCleanup::Util` pattern. Rejected as the primary approach for HMIS live-import scenarios because it does not scale operationally and is easy to skip after re-import.
2. **Post-ingest-only hooks without staging cleanups** — Could handle warehouse-only graph fixes. May still be needed for a subset of work; not mutually exclusive, but less ideal as the *only* path for row-level HUD fixes that can run on staging before `ingest!`.
3. **Cleanup process that can be triggered manually in the Warehouse** - click a button to run HMIS-needed/preferred cleanups on an existing data source (or project selection). Customers would need to know/remember to run it after importing into an HMIS.

## Related Documents

- [`HmisCsvImporter::HmisCsvCleanup::Base`](../../drivers/hmis_csv_importer/app/models/hmis_csv_importer/hmis_csv_cleanup/base.rb) — `cleanup!`, `self.enable`, `self.description`, `self.associated_model`
- [`docs/features/hmis-csv-importer.md`](../features/hmis-csv-importer.md) — import lifecycle and log models

### APPENDIX A: Proposed Importer Extensions to Add

This is not a finalized/comprehensive list, but an illustration of the types of cleanups that are currently performed manually.

- `Enrollment`: Reassign duplicate household IDs across projects
  - When the same `HouseholdID` appears on enrollments in different projects, assign a new UUID-like household id per project so household scope stays project-local.
- `Enrollment`: Make sole household member head of household
  - For single-member households, set `RelationshipToHoH` to head-of-household (1) when it was not.
- `Enrollment`: Normalize disabling condition nulls
  - Set null `DisablingCondition` on enrollments to 99 (data not collected).
- `Client`: Normalize race and gender “99” sentinel fields
  - Coerce invalid 99 values on discrete race/gender columns to 0 and set the corresponding “none” field to 99 when all discrete fields are zero but “none” was left blank (matches existing LSA-oriented cleanup intent).
- `Service`: Deduplicate bed-night services
  - For night-by-night bed-night records (`RecordType` 200), soft-delete duplicate rows sharing the same enrollment and date, keeping one.
- `Exit`: Deduplicate exit records per enrollment
  - When more than one non-deleted exit exists for the same `EnrollmentID`, soft-delete extras (typically keep oldest by id), matching one-off migration practice.
- `IncomeBenefit`: Fill missing total monthly income
  - Where `IncomeFromAnySource` indicates income but `TotalMonthlyIncome` is null, recompute total from detailed income columns (same reconciler idea as `fix_missing_monthly_total_income!`).
- `IncomeBenefits`: Reconcile total income from income amount fields
  - Recompute `TotalMonthlyIncome` from detailed income columns (same reconciler idea as `fix_missing_monthly_total_income!`)
- *Optional* `Enrollment`: Normalize invalid "Data not collected" relationship to HoH
  - Replace `RelationshipToHoH` value 99 with 5 (unrelated household member) where 99 is invalid for the field.
  - This cleanup has been done for HMIS customers because of data quality flags. HMIS application accommodates 99 value.
- *Multiple / TBD*: Align personal IDs on enrollment-related HUD rows
  - Fix rows where `PersonalID` does not match the enrollment’s client for the same `EnrollmentID` (today’s util spans many classes); likely needs **either** coordinated staging passes per file **or** a dedicated **post-ingest** extension with a clear scope (data source + involved projects + importer log).

Already available Importer Extensions to use for HMIS migrations:

- `HmisCsvImporter::HmisCsvCleanup::FixBlankHouseholdIds` - assign `HouseholdID` when missing
- `HmisCsvImporter::HmisCsvCleanup::ForceValidEnrollmentCoc` - set `Enrollment.EnrollmentCoc`
- `HmisCsvImporter::HmisCsvCleanup::EnforceRelationshipToHoh` - this overlaps with "make sole household member HoH", see if we want this logic around other relationships as well. It does seem to set some relationships to 99 which is invalid in HUD spec.
