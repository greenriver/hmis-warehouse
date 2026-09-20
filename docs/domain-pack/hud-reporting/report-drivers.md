---
title: HUD report drivers
summary: "One section per report driver: where its newest generator lives, which fiscal years are runnable versus read-only stubs, its snapshot models, and what is unusual about it (LSA runs HUD T-SQL on a temporary SQL Server; PIT uses a lazy shared universe; HOPWA CAPER builds staging tables). Also the CSV version-migration utilities and adjacent non-framework tools."
area: hud-reporting
tags: [hud-reports, hud_apr, APR, CAPER, CE-APR, hud_spm_report, SPM, hud_lsa, LSA, SQL Server, hud_pit, PIT, hud_hic, HIC, hud_path_report, PATH, hud_data_quality_report, hopwa_caper, ce_performance, longitudinal_spm, CsvTransformer, AprClient, SpmEnrollment, PitClient]
sources:
  - app/controllers/hud_reports/base_controller.rb
  - app/jobs/reporting/hud/run_report_job.rb
  - drivers/hud_apr/README.md
  - drivers/hud_apr/config/initializers/hud_apr_feature.rb
  - drivers/hud_apr/app/models/hud_apr/generators/apr/fy2026/generator.rb
  - drivers/hud_apr/app/models/hud_apr/generators/caper/fy2026/generator.rb
  - drivers/hud_apr/app/models/hud_apr/generators/ce_apr/fy2026/generator.rb
  - drivers/hud_apr/app/models/hud_apr/generators/dq/fy2026/generator.rb
  - drivers/hud_spm_report/README.md
  - drivers/hud_spm_report/config/initializers/hud_spm_report_feature.rb
  - drivers/hud_spm_report/app/models/hud_spm_report/generators/fy2026/generator.rb
  - drivers/hud_spm_report/app/models/hud_spm_report/generators/fy2024/generator.rb
  - drivers/hud_spm_report/app/models/hud_spm_report.rb
  - drivers/hud_lsa/README.md
  - drivers/hud_lsa/config/initializers/hud_lsa_feature.rb
  - drivers/hud_lsa/app/models/hud_lsa/generators/fy2027/lsa.rb
  - drivers/hud_lsa/app/models/hud_lsa/generators/fy2027/rds_concern.rb
  - drivers/hud_lsa/app/models/hud_lsa/generators/retired_lsa_stub.rb
  - drivers/hud_lsa/app/controllers/hud_lsa/lsas_controller.rb
  - drivers/hud_lsa/app/jobs/hud_lsa/run_report_job.rb
  - lib/rds_sql_server/sql_server_base.rb
  - drivers/hud_pit/README.md
  - drivers/hud_pit/config/initializers/hud_pit_feature.rb
  - drivers/hud_pit/app/models/hud_pit/generators/pit/fy2025/generator.rb
  - drivers/hud_pit/app/models/hud_pit/generators/pit/fy2025/base.rb
  - drivers/hud_hic/README.md
  - drivers/hud_hic/config/initializers/hud_hic_feature.rb
  - drivers/hud_hic/app/models/hud_hic/generators/hic/fy2022/generator.rb
  - drivers/hud_path_report/README.md
  - drivers/hud_path_report/config/initializers/hud_path_report_feature.rb
  - drivers/hud_path_report/app/models/hud_path_report/generators/fy2026/generator.rb
  - drivers/hud_data_quality_report/README.md
  - drivers/hud_data_quality_report/app/models/hud_data_quality_report/generators/fy2022/generator.rb
  - drivers/hud_data_quality_report/app/controllers/hud_data_quality_report/base_controller.rb
  - drivers/hopwa_caper/README.md
  - drivers/hopwa_caper/config/initializers/hopwa_caper_feature.rb
  - drivers/hopwa_caper/app/models/hopwa_caper/generators/fy2026/generator.rb
  - drivers/hopwa_caper/app/models/hopwa_caper/generators/fy2024/generator.rb
  - drivers/hopwa_caper/app/models/hopwa_caper/extensions/hud_reports/report_instance_extension.rb
  - drivers/hud_twenty_twenty_to_twenty_twenty_two/app/models/hud_twenty_twenty_to_twenty_twenty_two/csv_transformer.rb
  - drivers/hud_twenty_twenty_two_to_twenty_twenty_four/app/models/hud_twenty_twenty_two_to_twenty_twenty_four/csv_transformer.rb
  - drivers/hud_twenty_twenty_four_to_twenty_twenty_six/app/models/hud_twenty_twenty_four_to_twenty_twenty_six/csv_transformer.rb
  - drivers/ce_performance/README.md
  - drivers/longitudinal_spm/README.md
  - drivers/performance_measurement/app/models/performance_measurement/report.rb
  - lib/rds_sql_server/rds.rb
related:
  - hud-reporting/report-framework.md
  - hud-reporting/hud-utility-versions.md
  - hud-reporting/csv-import.md
---

## Purpose

Each HUD report is a Rails driver under `drivers/` that plugs a `HudReports::GeneratorBase`
subclass into the shared framework. This doc says, per driver, where the newest generator
lives, which fiscal years can still be run, which exist only so historical reports remain
viewable, which per-report snapshot tables it writes, and the one thing about it that is not
like the others. It also covers the three HMIS CSV version-migration drivers and three
reporting tools that sit next to the HUD drivers but do not use the framework.

HUD specifications (universes, question definitions, enumerations) are out of scope. Use the
HMIS domain knowledge MCP server (`search_docs`) for spec content; this doc covers only how
the code is organized.

A fiscal year is "runnable" when its controller lists it in `available_report_versions` with
`active: true` (or in a driver's own `active_report_versions`), so it appears in the new-report
form. A year is "read-only" when it is listed inactive: existing reports open and download,
new runs cannot be started from the UI. Some read-only years are stubs whose question and
calculation code has been deleted; the Entry points table marks those with `*`.

## Entry points

Every framework driver registers each generator class in
`Rails.application.config.hud_reports[...]` from `drivers/<driver>/config/initializers/<driver>_feature.rb`
with a `title` and a route `helper`. `Reporting::Hud::RunReportJob` and
`HudReports::QuestionBase` raise for any class not in that hash. The driver controller maps
version slugs to classes in `possible_generator_classes` and decides activity in
`available_report_versions`; the framework default in `HudReports::BaseController` follows
`HudHelper.current_version`, and several drivers override it.

| Driver | Newest generator class | Runnable years | Read-only years (`*` = stub, calculation code removed) |
|---|---|---|---|
| `hud_apr` (APR) | `HudApr::Generators::Apr::Fy2026::Generator` | FY2026 | FY2020\*, FY2021, FY2023, FY2024 |
| `hud_apr` (CAPER) | `HudApr::Generators::Caper::Fy2026::Generator` | FY2026 | FY2020\*, FY2021, FY2023, FY2024 |
| `hud_apr` (CE-APR) | `HudApr::Generators::CeApr::Fy2026::Generator` | FY2026 | FY2020\*, FY2021, FY2023, FY2024 |
| `hud_apr` (DQ) | `HudApr::Generators::Dq::Fy2026::Generator` | FY2026 | FY2024 |
| `hud_spm_report` | `HudSpmReport::Generators::Fy2026::Generator` | FY2026 | FY2020\*, FY2023\*, FY2024\* |
| `hud_lsa` | `HudLsa::Generators::Fy2027::Lsa` | FY2026, FY2027 | FY2022\*, FY2023\*, FY2024\* |
| `hud_pit` | `HudPit::Generators::Pit::Fy2025::Generator` | FY2022, FY2023, FY2024, FY2025 | none |
| `hud_hic` | `HudHic::Generators::Hic::Fy2022::Generator` | FY2022 | none |
| `hud_path_report` | `HudPathReport::Generators::Fy2026::Generator` | FY2026 | FY2020\*, FY2021, FY2024 |
| `hud_data_quality_report` | `HudDataQualityReport::Generators::Fy2022::Generator` | none | FY2020, FY2022 |
| `hopwa_caper` | `HopwaCaper::Generators::Fy2026::Generator` | FY2026 | FY2024\* |

`hud_data_quality_report` has no feature initializer and no `config.hud_reports` entry, so its
generators cannot be queued even though their question code is intact; it serves the
`/hud_reports/past_dqs` history routes. The framework labels the `hud_path_report` `fy2021`
slug "FY 2022" in `HudReports::BaseController#available_report_versions`.

CSV migrations are run from a console: `HudTwentyTwentyToTwentyTwentyTwo::CsvTransformer.up(source_dir, destination_dir)`
and the two later namesakes. The first two drivers also expose
`rails driver:<driver>:migrate:up` for in-database conversion.

## How it works

### hud_apr (APR, CAPER, CE-APR, DQ)

One driver, four report families, each with its own `generators/<family>/fyXXXX/generator.rb`.
The APR, CAPER and CE-APR question classes subclass shared implementations in
`generators/shared/fyXXXX/`, so a question fix usually lands there once. All years write the
same snapshot tables: `HudApr::Fy2020::AprClient` (`hud_report_apr_clients`) and
`HudApr::Fy2020::AprLivingSituation`, joined to cells through
`HudApr::HudReports::UniverseMemberExtension`. `HudApr::CellDetailsConcern` supplies cell
drilldowns; `HudApr::Archival` registers the report for archival. `HudApr.current_generator(report:)`
resolves the active year from the framework default. The FY2026 DQ generator exposes
`source_report_id_for_contexts`, read by the SPM HDX upload; it is currently a no-op.

### hud_spm_report (SPM)

`HudSpmReport::Generators::Fy2026::Generator` is the only version that runs. It sets
`supports_idempotent_retry?` to true and, in `prepare_report`, calls
`HudReports::HouseholdContextBuilder` with a 7-year lookback before measures run. Measures 1-7
plus `HdxUpload` are the questions; `HdxUpload` also queues a
`HudApr::Generators::Dq::Fy2026::Generator` sub-report. Snapshot models live under
`HudSpmReport::Fy2026`: `SpmEnrollment` (`hud_report_spm_enrollments`), `Episode`,
`EnrollmentLink`, `BedNight`, `Return`. `HudSpmReport::HudReports::ReportInstanceExtension`
adds `spm_enrollments` to `HudReports::ReportInstance`. FY2020, FY2023 and FY2024 generators
replace their measure classes with a frozen `LegacyQuestion` `Data` struct that only supplies
`client_class` and `client_scope` for drilldowns. `HudSpmReport.current_generator` raises unless
the framework default is `:fy2026`.

### hud_lsa (LSA and HIC-via-LSA)

`HudLsa::Generators::Fy2027::Lsa` subclasses `HudReports::ReportInstance` directly (not
`GeneratorBase`) and is run by `HudLsa::RunReportJob` on the long-running queue. `calculate`
creates an RDS SQL Server instance (`RdsConcern#create_temporary_rds`, or a static host when
`LSA_DB_HOST` is set), exports HMIS CSV with `HmisCsvTwentyTwentySix::Exporter::Base`, bulk-loads
it into SQL Server, runs HUD's T-SQL from `lib/rds_sql_server/lsa/fy2027/lsa_queries.rb`,
fetches result and intermediate tables to zips attached as `result_file` and
`intermediate_file`, and drops the instance in an `ensure`. The `lsa_scope` option turns the
same class into the HIC run (`hic?`). FY2026 is a near-copy and still active. FY2022-FY2024
include `HudLsa::Generators::RetiredLsaStub`: STI, downloads and archival only.

### hud_pit (PIT)

`HudPit::Generators::Pit::Fy2025::Generator` takes a single `on` date. Its questions share one
lazily built universe: `Base#universe` calls `add` unless `populated?` finds existing universe
members, so the first question to run writes every `HudPit::Fy2025::PitClient` row
(`hud_report_pit_clients`, subclassing `HudPit::Fy2024::PitClient`) and later questions only
filter it. All four registered years are active in `HudPit::PitConcern#available_report_versions`;
FY2023 still uses `HudPit::Fy2022::PitClient`. The default project types come from
`HudHelper.util('2024')`, not the current version.

### hud_hic (HIC)

`HudHic::Generators::Hic::Fy2022::Generator` is the only year. It has no client universe; each
question (`Organization`, `Project`, `ProjectCoc`, `Inventory`, `Funder`) copies HUD records
active on the `on` date into a `HudHic::Fy2022::*` table shaped like the HMIS CSV file of the
same name, and `Base#run_question!` writes those rows into cells. The universe-member link is
`HudHic::HudReports::UniverseMemberExtension`. The HIC that HUD actually collects is the LSA
run with the HIC scope; this driver produces the tabular version.

### hud_path_report (PATH)

`HudPathReport::Generators::Fy2026::Generator` uses its own
`HudPathReport::Filters::PathFilter` and default project types from
`HudHelper.util('2026').path_project_type_codes`. Questions are grouped (`QuestionEightToSixteen`,
`QuestionNineteenToTwentyFour`, ...). Every year writes `HudPathReport::Fy2020::PathClient`
(`hud_report_path_clients`). `HudPathReport::BaseController` marks FY2026 as the only active
version and hides the framework's "FY 2023" entry, which this driver never had.

### hud_data_quality_report (legacy DQ)

The pre-FY2024 Data Quality report. `HudDataQualityReport::Generators::Fy2022::Generator` and
the FY2020 sibling write `HudDataQualityReport::Fy2020::DqClient` and `DqLivingSituation`, but
neither is registered in `config.hud_reports`, and `HudDataQualityReport::BaseController`
lists both inactive. It exists for `/hud_reports/past_dqs` history, downloads and PDF export.
`HudApr::Dq::DqConcern#history` redirects FY2020/FY2022 requests here. New DQ work goes in
`hud_apr`.

### hopwa_caper (HOPWA CAPER)

`HopwaCaper::Generators::Fy2026::Generator#prepare_report` builds report-scoped staging tables
before any sheet runs: `HopwaCaper::Enrollment` (`hopwa_caper_enrollments`), `HopwaCaper::Service`
(HUD and `Hmis::Hud::CustomService` rows, 15-year lookback) and `HopwaCaper::Funder`, all
`HudReports::ReportClientBase` subclasses hung off `HudReports::ReportInstance` by
`HopwaCaper::HudReports::ReportInstanceExtension`. Post-processing normalizes client attributes
across enrollments, tags one `hopwa_eligible` member per household, aggregates household
income/insurance, and reads Access-to-Care answers from custom assessments when
`HopwaCaper::Configuration#atc_tab_enabled?`. Questions are `Sheets::*` classes. In development
`prepare_report` defaults `reset: true` and deletes the staging rows first. The FY2024 generator
raises `NotImplementedError` from `queue`, `run!` and `prepare_report`.

### CSV version migrations

`drivers/hud_twenty_twenty_to_twenty_twenty_two`, `hud_twenty_twenty_two_to_twenty_twenty_four`
and `hud_twenty_twenty_four_to_twenty_twenty_six` each define a `CsvTransformer` with a
`TRANSFORM_TYPES` hash keyed by HUD CSV filename. Each entry is `:copy` (normalize line endings
and copy), `:update` (run a Kiba job from the named `<Namespace>::<File>::Csv` transformer), or
`:create` (write a file the old version lacked, optionally from `references` to other source
files). Headers are normalized case-insensitively against the target model's
`hmis_configuration(version:)`. The 2024-to-2026 transformer also emits `CustomGender.csv` and
`CustomEnrollmentFY26Deprecations.csv` for fields HUD removed. Nothing in `app/` or other
drivers calls these classes; they are console tools.

### Adjacent tools

`ce_performance` (`CePerformance::Report < SimpleReports::ReportInstance`) tracks Coordinated
Entry performance by running CE-APRs and comparing to goals. `longitudinal_spm`
(`LongitudinalSpm::Report < GrdaWarehouseBase`) runs quarterly SPMs through
`HudSpmReport.current_generator` and compares measures across quarters. `performance_measurement`
(`PerformanceMeasurement::Report < SimpleReports::ReportInstance`, no README) is the CoC
performance dashboard; it includes `SpmBasedReports` and reads `HudSpmReport::Fy2026`
snapshot models directly. None subclass `HudReports::GeneratorBase` or register in
`config.hud_reports`.

## Key files

- `app/controllers/hud_reports/base_controller.rb:115` `available_report_versions`; `:141`
  `default_report_version`; `:309` `generator` from `possible_generator_classes[report_version]`.
- `app/jobs/reporting/hud/run_report_job.rb:22` raises for unregistered generator classes.
- `drivers/hud_apr/config/initializers/hud_apr_feature.rb`: 17 registrations across four families.
- `drivers/hud_apr/app/models/hud_apr/generators/apr/fy2026/generator.rb` and the sibling `caper`, `ce_apr`, `dq` FY2026 generators:
  templates for a new APR-family year.
- `drivers/hud_spm_report/app/models/hud_spm_report/generators/fy2026/generator.rb:40`
  `HouseholdContextBuilder.call`; `:91` `archival_csv_config`.
- `drivers/hud_spm_report/app/models/hud_spm_report/generators/fy2024/generator.rb:34`
  `LegacyQuestion` stub pattern.
- `drivers/hud_spm_report/app/models/hud_spm_report.rb:10` `current_generator`.
- `drivers/hud_lsa/app/models/hud_lsa/generators/fy2027/lsa.rb:9` conditional `load` of
  `lib/rds_sql_server/rds.rb` with an `Rds` stub fallback; `:105` `calculate`; `:187`
  `run_lsa_queries`.
- `drivers/hud_lsa/app/models/hud_lsa/generators/fy2027/rds_concern.rb:35` `create_temporary_rds`;
  `:57` `remove_temporary_rds`.
- `drivers/hud_lsa/app/models/hud_lsa/generators/retired_lsa_stub.rb`: what a retired LSA year keeps.
- `drivers/hud_lsa/app/controllers/hud_lsa/lsas_controller.rb:200` version list; `:213`
  LSA-specific `default_report_version`.
- `drivers/hud_lsa/app/jobs/hud_lsa/run_report_job.rb`: loads from the STI base, `max_attempts` 1.
- `lib/rds_sql_server/sql_server_base.rb:10` `cattr_accessor :rds, :host, :database`.
- `drivers/hud_pit/app/models/hud_pit/generators/pit/fy2025/base.rb:41` lazy `universe`; `:245`
  `populated?`.
- `drivers/hud_hic/app/models/hud_hic/generators/hic/fy2022/generator.rb:102` `table_classes`.
- `drivers/hud_path_report/app/models/hud_path_report/generators/fy2026/generator.rb`.
- `drivers/hud_data_quality_report/app/controllers/hud_data_quality_report/base_controller.rb:14`
  both versions inactive; `:81` `possible_generator_classes`.
- `drivers/hopwa_caper/app/models/hopwa_caper/generators/fy2026/generator.rb:37` `prepare_report`;
  `:114` `build_hopwa_caper_models`; `:222` `update_hopwa_eligibility`.
- `drivers/hopwa_caper/app/models/hopwa_caper/generators/fy2024/generator.rb`: read-only stub
  that raises.
- `drivers/hopwa_caper/app/models/hopwa_caper/extensions/hud_reports/report_instance_extension.rb`:
  staging-table associations with `dependent: :delete_all`.
- `drivers/hud_twenty_twenty_four_to_twenty_twenty_six/app/models/hud_twenty_twenty_four_to_twenty_twenty_six/csv_transformer.rb:13`
  `TRANSFORM_TYPES`; `:143` `up`.
- `drivers/performance_measurement/app/models/performance_measurement/report.rb:13`
  `SimpleReports::ReportInstance` parent.

## Gotchas

- LSA is not thread safe. `SqlServerBase` holds the RDS instance, host and database in
  `cattr_accessor`s and `establish_connection` runs at class-load time; `Lsa#run_lsa_queries`
  assigns `::Rds.identifier`, `::Rds.database` and `::Rds.timeout` globally. One LSA per
  process.
- LSA RDS lifecycle: `remove_temporary_rds` runs in `calculate`'s `ensure`, but only when
  `destroy_rds?` is true and `LSA_DB_HOST` is blank. Setting `report.destroy_rds = false` leaves
  a billed instance running.
- Without `RDS_AWS_ACCESS_KEY_ID` (or with `NO_LSA_RDS`), `lsa.rb` defines a stub `::Rds` whose
  `rds_available?` is false so views load; nothing LSA-related runs.
- The only automated SQL Server coverage is the `lsa_integration_test.yml` workflow, which runs
  `rake driver:hud_lsa:ci_integration_test` for FY2027 in test mode against a SQL Server 2022
  container. Unit specs never touch SQL Server. FY2026 has no automated coverage.
- Retired years cannot run. LSA FY2022-FY2024 are `RetiredLsaStub` includes; SPM FY2020, FY2023,
  FY2024 have `LegacyQuestion` structs instead of measure classes; HOPWA FY2024 raises
  `NotImplementedError`. Their T-SQL, wrappers and question code are deleted, so a "quick
  re-run" of an old year means restoring code from history.
- Inactive is not the same as stubbed. APR-family FY2021-FY2024, PATH FY2021-FY2024 and PIT
  FY2022-FY2024 keep full question code and will run if queued programmatically; the FY2020
  question classes have no `run_question!`.
- Registration has two halves. The initializer hash gates `RunReportJob` and `QuestionBase`;
  the controller's `possible_generator_classes` gates the UI. `hud_data_quality_report` shows
  what happens with only the second: viewable, never runnable.
- Snapshot tables are shared across years within a driver (`HudApr::Fy2020::AprClient`,
  `HudPathReport::Fy2020::PathClient`, `HudDataQualityReport::Fy2020::DqClient`, and
  `HudPit::Fy2025::PitClient < HudPit::Fy2024::PitClient`). A column change touches every
  year's drilldowns.
- `HudSpmReport.current_generator` and `HudApr.current_generator` derive the year from
  `HudReports::BaseController.new.default_report_version`; `HudSpmReport.current_generator`
  raises for anything but `:fy2026`. Callers outside the drivers (`longitudinal_spm`,
  `performance_measurement`) break on a year bump until updated.
- `HopwaCaper::Generators::Fy2026::Generator#prepare_report` defaults `reset:` to
  `Rails.env.development?`, so a development re-run wipes and rebuilds staging rows while
  production appends with `on_duplicate_key_ignore`.
- PIT FY2025 and HIC FY2022 still call `HudHelper.util('2024')` for default project types.

## Do not repeat

- Using a stub year as the template for a new fiscal year. `HudLsa::Generators::Fy2024::Lsa`,
  `HudSpmReport::Generators::Fy2024::Generator` and `HopwaCaper::Generators::Fy2024::Generator`
  have no calculation code. Copy the newest active year (`Fy2027::Lsa`, `Fy2026::Generator`)
  and register the new class in the feature initializer and the controller's
  `possible_generator_classes`. See `hud-reporting/report-framework.md`.
- Adding a report under the `HudReports` namespace, or registering it in `config.hud_reports`,
  when it does not implement `GeneratorBase` questions. `ce_performance`, `longitudinal_spm`
  and `performance_measurement` use `SimpleReports::ReportInstance` or a plain model and stay
  outside the framework.
- Registering a generator in only one of the two places. `hud_data_quality_report` (controller
  only) is the existing instance of a report that can be opened but never run.
- Hard-coding `HudHelper.util('2024')` in a new year's generator. Existing instances:
  `HudPit::Generators::Pit::Fy2025::Generator`, `HudHic::Generators::Hic::Fy2022::Generator`.
  Use the version matching the fiscal year, as `HudApr::Generators::Apr::Fy2026::Generator`
  does with `HudHelper.util('2026')`. See `hud-reporting/hud-utility-versions.md`.
- Adding class-level mutable state to LSA (`cattr_accessor`, module-level `::Rds` writes).
  `SqlServerBase` and `Lsa#run_lsa_queries` are the existing instances that make the job
  single-process; do not extend the pattern.
- Calling `CsvTransformer` classes from application code. They are console utilities with no
  callers in `app/` or other drivers; the import pipeline has its own version handling
  (`hud-reporting/csv-import.md`).

## Related

- `hud-reporting/report-framework.md`: `GeneratorBase`, `QuestionBase`, `ReportInstance`,
  universe members, `HouseholdContext`, archival, and the version-registration contract these
  drivers follow.
- `hud-reporting/hud-utility-versions.md`: `HudHelper.util(version)` and why generators pin a
  version string.
- `hud-reporting/csv-import.md`: the `hmis_csv_twenty_twenty*` version drivers that the
  migration transformers target.
- `docs/features/warehouse/hud-spm-report.md`, `hud-pit-report.md`, `hopwa-caper.md`, and
  `drivers/hud_lsa/README.md`: human-facing descriptions of the SPM, PIT, HOPWA CAPER and LSA
  pipelines.
