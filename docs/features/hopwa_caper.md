# HOPWA CAPER

The HOPWA CAPER feature produces the HUD-required Consolidated Annual Performance and Evaluation Report for Housing Opportunities for Persons With AIDS (HOPWA) grantees. It packages HMIS warehouse data into the CAPER workbook format, reducing manual reporting work needed to deliver the report. Note, not all sheets in the HOPWA CAPER are implemented as some data can not be sourced from an HMIS.

The report lives under the HUD Reports surface. `HopwaCaper::BaseController` wires the standard HUD filtering UI (date range, CoCs, projects, data sources) to the generator and exposes feature-aware routes for questions, cells, and exports.

## Data Preparation Pipeline
- **Filtering via ServiceHistoryEnrollment:** The generator uses `ServiceHistoryEnrollment` to identify which enrollments fall within scope. This denormalized table enables efficient date-range and project filtering.
- **Snapshotting from source records:** Once the enrollment universe is identified, the generator traverses back to the canonical HUD enrollment records and their associations (services, income benefits, disabilities, funders). This ensures report snapshots capture complete detail from the source data.
- **Service date filtering:** Services are included only if their `date_provided` falls within the report period.
- **Filtered staging tables:** Each run populates two report-scoped staging tables: `HopwaCaper::Enrollment` and `HopwaCaper::Service`. Services include both HUD services and custom services, with denormalized category and type names for simpler querying.
- **Uniform client attributes:** After importing enrollments, `ensure_uniform_client_attrs` normalizes age, HIV indicators, and viral load suppression across all enrollments for the same warehouse client. This guarantees that downstream demographic aggregations do not fluctuate when a client has overlapping enrollments with inconsistent intake answers.
- **Household eligibility tagging:** `update_hopwa_eligibility` assigns a single HOPWA-eligible member per household (preferring an HIV-positive head of household). The CAPER asks household-level questions about HOPWA eligibility, so this tagging step avoids ambiguity when multiple members qualify.
- **Universe links:** Both staging models inherit from `HudReports::ReportClientBase`, exposing `as_report_members` helpers that register each record as a `HudReports::UniverseMember`. This is how HUD report tooling resolves drill-downs and renders client detail tables in the UI.

## Question Sheets and Builders
- **Sheet architecture:** The FY 2026 generator enumerates sheet classes. Each inherits from `HopwaCaper::Generators::Fy2026::Sheets::Base` or `BaseProgramSheet`, which wrap `HudReports::QuestionSheet` and provide common helpers for enrollment scoping, cell creation, and household table generation.
- **Reusable filters:** Enrollment filters (age, gender, income, longevity, prior living situation, housing outcomes) and service filters (record type, STRMU assistance categories) live under `app/models/hopwa_caper/generators/fy2026/enrollment_filters` and `.../service_filters`. Filters encapsulate the business rules for grouping rows so that question sheets remain declarative.

## Related Code
- Feature initializer: `/app/drivers/hopwa_caper/config/initializers/hopwa_caper_feature.rb`
- Generator: `/app/drivers/hopwa_caper/app/models/hopwa_caper/generators/fy2026/generator.rb`
- Staging models: `/app/drivers/hopwa_caper/app/models/hopwa_caper/enrollment.rb`, `/app/drivers/hopwa_caper/app/models/hopwa_caper/service.rb`
- Question sheets & filters: `/app/drivers/hopwa_caper/app/models/hopwa_caper/generators/fy2026/sheets/` and `.../enrollment_filters/`, `.../service_filters/`
- PDF export: `/app/drivers/hopwa_caper/app/models/hopwa_caper/document_exports/hopwa_caper_export.rb`
