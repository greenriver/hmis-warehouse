# HOPWA CAPER

The HOPWA CAPER feature produces the HUD-required Consolidated Annual Performance and Evaluation Report for Housing Opportunities for Persons With AIDS (HOPWA) grantees. It packages HMIS warehouse data into the CAPER workbook format, allowing program staff to validate results in the web UI, download PDF exports, and deliver a submission-ready dataset to HUD without manual spreadsheet work.

## Reporting Workflow
- **Entry point:** The report lives under the HUD Reports surface. `HopwaCaper::BaseController` wires the standard HUD filtering UI (date range, CoCs, projects, data sources) to the generator and exposes feature-aware routes for questions, cells, and exports. Only FY 2026 is active today, but the controller is version-aware so later fiscal-year generators can be added in place.
- **Report instances:** When a user queues a run, `HopwaCaper::Generators::Fy2026::Generator` prepares a dedicated `HudReports::ReportInstance`. The feature registers with `HudReports` via `/drivers/hopwa_caper/config/initializers/hopwa_caper_feature.rb`, so the shared job runners and dashboards treat it like any other HUD report.
- **Asynchronous processing:** The generator executes inside the standard HUD report job pipeline. It can run interactively from the UI or manually via `Reporting::Hud::RunReportJob`, producing repeatable results with the same filters.

## Data Preparation Pipeline
- **Source universe:** The generator pulls from `GrdaWarehouse::ServiceHistoryEnrollment`, looking for enrollments that overlap the reporting window and extending the look-back to 15 years for TBRA-funded projects. This extended window exists so HUD’s historical eligibility checks can pass without requiring separate data extracts.
- **Filtered staging tables:** Each run populates two report-scoped staging tables: `HopwaCaper::Enrollment` (people/households) and `HopwaCaper::Service` (financial assistance and supportive services). Storing slices per report instance keeps reruns isolated and enables reconciliation back to HUD data without mutating core HMIS facts.
- **Uniform client attributes:** After importing enrollments, `ensure_uniform_client_attrs` normalizes age, HIV indicators, and viral load suppression across all enrollments for the same warehouse client. This guarantees that downstream demographic aggregations do not fluctuate when a client has overlapping enrollments with inconsistent intake answers.
- **Household eligibility tagging:** `update_hopwa_eligibility` assigns a single HOPWA-eligible member per household (preferring an HIV-positive head of household). The CAPER asks household-level questions about HOPWA eligibility, so this tagging step avoids ambiguity when multiple members qualify. The tags also drive the household-level row builders in the sheet classes.
- **Universe links:** Both staging models inherit from `HudReports::ReportClientBase`, exposing `as_report_members` helpers that register each record as a `HudReports::UniverseMember`. This is how HUD report tooling resolves drill-downs and renders client detail tables in the UI.

## Question Sheets and Builders
- **Sheet architecture:** The FY 2026 generator enumerates four sheet classes (`DemographicsAndPriorLivingSituation`, `Tbra`, `Strmu`, `Php`). Each inherits from `HopwaCaper::Generators::Fy2026::Sheets::Base` or `BaseProgramSheet`, which wrap `HudReports::QuestionSheet` and provide common helpers for enrollment scoping, cell creation, and household table generation.
- **Reusable filters:** Enrollment filters (age, gender, income, longevity, prior living situation, housing outcomes) and service filters (record type, STRMU assistance categories) live under `app/models/hopwa_caper/generators/fy2026/enrollment_filters` and `.../service_filters`. Filters encapsulate the business rules for grouping rows so that question sheets remain declarative. When HUD guidance changes, editing or adding a filter object usually suffices.
- **Cell construction:** Sheets compose filters to build household counts, expenditure totals, and outcome tallies. For example, the STRMU sheet combines financial assistance service filters with household enrollment scopes so that “served with STRMU Mortgage Assistance only” can be answered consistently across UI, CSV, and PDF exports. The builders return `HudReports::ReportCell` records that power both the UI tables and downloads.

## UI & Export Integration
- **Synchronized controllers:** `ReportsController`, `QuestionsController`, and `PathsController` inherit from the base controller and primarily delegate to shared HUD report concerns. They keep UI affordances (history views, reruns, cell drill-down links) aligned with the rest of the HUD reporting suite.
- **Document export:** `HopwaCaper::DocumentExports::HopwaCaperExport` uses `HudReports::HudPdfExportConcern` to render PDF snapshots from the same controller paths. Because the export asks the controller for its available generator classes, version upgrades automatically appear in download menus.
- **Universe member extensions:** Extensions in `/drivers/hopwa_caper/extensions/hud_reports` add HOPWA associations to `HudReports::ReportInstance` and `HudReports::UniverseMember`. This keeps drill-down queries deterministic and prevents orphaned staging rows when report instances are purged.

## Extensibility Notes
- **Adding a new fiscal year:** Implement a new generator and sheet subset under `HopwaCaper::Generators::<FY>` and register it in `possible_generator_classes` plus `available_report_versions`. Filters can usually be shared; wrap divergent logic in version-specific filter subclasses when HUD definitions change.
- **Expanding STRMU/TBRA logic:** All eligibility and grouping rules route through the filter objects. Update or extend those classes rather than mutating question builders directly; this maintains test coverage and keeps the sheet DSL readable.
- **Downstream integrations:** The feature expects service history rebuilds to have run recently and assumes CAPER consumers will reconcile via HMIS Personal IDs. When integrating with external deliverables (e.g., CSV uploads to HUD Exchange), prefer exporting from the staging tables to preserve the point-in-time snapshot.

## Related Code
- Feature initializer: `/app/drivers/hopwa_caper/config/initializers/hopwa_caper_feature.rb`
- Generator: `/app/drivers/hopwa_caper/app/models/hopwa_caper/generators/fy2026/generator.rb`
- Staging models: `/app/drivers/hopwa_caper/app/models/hopwa_caper/enrollment.rb`, `/app/drivers/hopwa_caper/app/models/hopwa_caper/service.rb`
- Question sheets & filters: `/app/drivers/hopwa_caper/app/models/hopwa_caper/generators/fy2026/sheets/` and `.../enrollment_filters/`, `.../service_filters/`
- PDF export: `/app/drivers/hopwa_caper/app/models/hopwa_caper/document_exports/hopwa_caper_export.rb`
- HUD report extensions: `/app/drivers/hopwa_caper/extensions/hud_reports/`
