# HOPWA CAPER

The HOPWA CAPER feature produces the HUD-required Consolidated Annual Performance and Evaluation Report for Housing Opportunities for Persons With AIDS (HOPWA) grantees. It packages HMIS warehouse data into the CAPER workbook format. Note, not all sheets in the HOPWA CAPER are implemented as some data can not be sourced from an HMIS.

The report lives under the HUD Reports, use `HopwaCaper::BaseController` as an entry point.

## Data Preparation Pipeline
- **Filtering via ServiceHistoryEnrollment:** The generator uses `ServiceHistoryEnrollment` to identify enrollments within the report scope. This denormalized table supports date-range and project filtering.
- **Snapshotting from source records:** The generator retrieves canonical HUD enrollment records and their associations (services, income benefits, disabilities, funders).
- **Filtered staging tables:** Each run populates two report-scoped staging tables: `HopwaCaper::Enrollment` and `HopwaCaper::Service`. Services include both HUD services and custom services, with denormalized category and type names.
- **Uniform client attributes:** After importing enrollments, `ensure_uniform_client_attrs` normalizes age, HIV indicators, and viral load suppression across all enrollments for the same warehouse client. This prevents demographic aggregations from varying when a client has overlapping enrollments with inconsistent intake answers.
- **Household eligibility tagging:** `update_hopwa_eligibility` assigns a single HOPWA-eligible member per household (preferring an HIV-positive head of household). This resolves cases where multiple members qualify.
- **Universe links:** Both staging models inherit from `HudReports::ReportClientBase`, exposing `as_report_members` helpers that register each record as a `HudReports::UniverseMember`. This connects records to HUD report drill-downs and client detail tables.

## Household Counting Methodology
Household counts follow the HUD HMIS reporting glossary definition: "distinct count of personal IDs of all heads of households." When a household has multiple enrollments during the reporting period (e.g., enrolling at different projects), they are counted only once by deduplicating on the HoH.

## Question Sheets and Builders
- **Sheet architecture:** The FY 2026 generator enumerates sheet classes. Each inherits from `HopwaCaper::Generators::Fy2026::Sheets::Base` or `BaseProgramSheet`, which wrap `HudReports::QuestionSheet` and provide helpers for enrollment scoping, cell creation, and household table generation.
- **Filters:** Enrollment filters (age, gender, income, longevity, prior living situation, housing outcomes) and service filters (record type, STRMU assistance categories) are located under `app/models/hopwa_caper/generators/fy2026/enrollment_filters` and `.../service_filters`. Filters contain the business rules for grouping rows.

## Related Code
- Feature initializer: `/app/drivers/hopwa_caper/config/initializers/hopwa_caper_feature.rb`
- Generator: `/app/drivers/hopwa_caper/app/models/hopwa_caper/generators/fy2026/generator.rb`
- Staging models: `/app/drivers/hopwa_caper/app/models/hopwa_caper/enrollment.rb`, `/app/drivers/hopwa_caper/app/models/hopwa_caper/service.rb`
- Question sheets & filters: `/app/drivers/hopwa_caper/app/models/hopwa_caper/generators/fy2026/sheets/` and `.../enrollment_filters/`, `.../service_filters/`
- PDF export: `/app/drivers/hopwa_caper/app/models/hopwa_caper/document_exports/hopwa_caper_export.rb`
