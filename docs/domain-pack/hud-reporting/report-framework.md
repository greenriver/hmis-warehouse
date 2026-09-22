---
title: HUD report framework
summary: "The generator, question, cell, universe-member pattern behind APR, CAPER, CE-APR, SPM, PIT, HIC, PATH, DQ, and HOPWA CAPER reports. Covers ReportInstance lifecycle, fiscal-year registration in driver feature initializers, driver extensions onto UniverseMember and ReportInstance, the HouseholdContext precomputed layer, drilldowns, archival, and retry-safe snapshot patterns."
area: hud-reporting
tags: [hud-reports, HudReports, GeneratorBase, QuestionBase, ReportInstance, ReportCell, UniverseMember, HouseholdContext, HouseholdLogic, ReportCheckpoint, drilldown, RunReportJob, hud_reports config, universe_member_extension, supports_idempotent_retry?, reset_derived_data, archive]
sources:
  - app/models/hud_reports/generator_base.rb
  - app/models/hud_reports/question_base.rb
  - app/models/hud_reports/report_instance.rb
  - app/models/hud_reports/report_cell.rb
  - app/models/hud_reports/universe_member.rb
  - app/models/hud_reports/report_client_base.rb
  - app/models/hud_reports/household_context.rb
  - app/models/hud_reports/household_context_builder.rb
  - app/models/hud_reports/household_logic.rb
  - app/models/hud_reports/report_checkpoint.rb
  - app/models/hud_reports/drilldown_context.rb
  - app/models/hud_reports/cell_detail_export_builder_base.rb
  - app/models/concerns/hud_report_archival.rb
  - app/controllers/hud_reports/base_controller.rb
  - app/controllers/concerns/hud_reports/cell_drilldown_concern.rb
  - app/jobs/reporting/hud/run_report_job.rb
  - app/jobs/importing/run_daily_imports_job.rb
  - app/services/hud_reports/archive_report_service.rb
  - app/services/hud_reports/restore_archived_report_data_service.rb
  - app/models/grda_warehouse/auth_policies/hud_report_policy.rb
  - lib/hud_reports/route_concerns.rb
  - lib/tasks/reports/migrate_to_csv.rake
  - config/application.rb
  - drivers/hud_apr/config/initializers/hud_apr_feature.rb
  - drivers/hud_apr/app/models/hud_apr/extensions/hud_reports/universe_member_extension.rb
  - drivers/hud_apr/app/models/hud_apr/generators/apr/fy2026/generator.rb
  - drivers/hud_apr/app/models/hud_apr/generators/apr/fy2026/question_four.rb
  - drivers/hud_spm_report/app/models/hud_spm_report/generators/fy2026/generator.rb
  - drivers/hud_spm_report/app/models/hud_spm_report/extensions/hud_reports/report_instance_extension.rb
related:
  - hud-reporting/report-drivers.md
  - hud-reporting/hud-utility-versions.md
  - hud-reporting/service-history.md
  - authorization/warehouse-policies.md
---

## Purpose

How `app/models/hud_reports/` runs a HUD compliance report: a `GeneratorBase` subclass in a driver declares an ordered set of `QuestionBase` subclasses; `Reporting::Hud::RunReportJob` runs them against a `HudReports::ReportInstance`; each question writes `HudReports::ReportCell` rows and links cells to report-specific snapshot records through the polymorphic `HudReports::UniverseMember`. Also covered: the `HouseholdContext` precomputed layer, checkpoint-based progress and retry, cell drilldowns and Excel export, CSV archival and restore, and who may see a run.

HUD specifications (universes, question definitions, enumerations) are out of scope. Spec content is available through the HMIS domain knowledge MCP server (`search_docs`). This doc describes only how the code implements them. Per-driver detail (APR, SPM, LSA, PIT, and the rest) is in `hud-reporting/report-drivers.md`.

## Entry points

- Routes: each report driver's `config/routes.rb` does `extend HudReports::RouteConcerns` (`lib/hud_reports/route_concerns.rb`) and declares `resources :aprs do concerns :hud_report_actions ... end` under `scope module: :hud_apr, path: :hud_reports, as: :hud_reports`. `hud_report_actions` adds `running`, `running_all_questions`, `history`, `download`, `restore`; `hud_drilldown_actions` adds nested `questions/:id/cells/:id` with `search` and `search_queries`. Core `config/routes.rb` only has the `/hud_reports` index plus historic PIT and LSA lists.
- `HudReports::BaseController` (`app/controllers/hud_reports/base_controller.rb`): `index` lists every registered report from `Rails.application.config.hud_reports`; `new`/`create` build a `Filters::HudFilterBase`, call `ReportInstance.from_filter(filter, report_name, build_for_questions: generator.questions.keys)`, then `generator.new(@report).queue`; `show` renders HTML or a zip via `HudReports::ZipExporter`; `download` renders `hud_reports/download` as xlsx; `restore` calls `HudReports::RestoreArchivedReportDataService`; `destroy` soft-deletes the instance. Driver controllers subclass it and supply `possible_generator_classes` and `path_for_*` helpers.
- `GeneratorBase#queue` sets `state = 'Waiting'`, copies `questions.keys` into `question_names`, saves, and enqueues `Reporting::Hud::RunReportJob.perform_later(class_name, report.id)`. `GeneratorBase#run!` does the same with `perform_now` and `manual:`.
- Console: `Reporting::Hud::RunReportJob.new.perform(generator_class.name, report_instance.id, email: false)`. Only generators with `supports_idempotent_retry?` can be re-run on an existing instance.
- Registration: `Rails.application.config.hud_reports = {}` in `config/application.rb`; each driver's `config/initializers/<driver>_feature.rb` adds `config.hud_reports['<Generator class>'] = { title:, helper: }`. `RunReportJob#perform` and `QuestionBase#initialize` raise on an unregistered class name.
- `GeneratorBase.drilldown_context(report:, measure_id:, cell_id:, table_id:)` builds a `HudReports::DrilldownContext` for cell views and exports.

## How it works

### Three tiers

`HudReports::GeneratorBase` (`app/models/hud_reports/generator_base.rb`) is instantiated with one `ReportInstance`. A subclass defines class methods `fiscal_year`, `generic_title`, `short_name`, `questions` (an ordered hash of `question_number => class`, frozen), `filter_class`, `default_project_type_codes`, `client_class(question)`, `detail_template`, and optionally `valid_question_number`, `pii_columns`, `file_prefix`, `supports_idempotent_retry?`, `archival_csv_config`. `title` is `"#{generic_title} - #{fiscal_year}"` and is the value stored in `ReportInstance#report_name`; the model supports STI but the code keys report type off `report_name`. `base_enrollment_scope` and `client_scope` apply the saved filter to `GrdaWarehouse::ServiceHistoryEnrollment.entry`, so service history is the base data for every report.

`HudReports::QuestionBase` (`question_base.rb`) is built with `(generator, report)`. `run!` calls `prepare_for_run`, then the subclass's `run_question!`, then removes the question from `report.remaining_questions`. On any error it writes the message and `status: 'Failed'` to the question's universe cell and re-raises. A concrete question (`drivers/hud_apr/app/models/hud_apr/generators/apr/fy2026/question_four.rb`) does `@report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)`, fills cells, then `@report.complete(QUESTION_NUMBER)`. `HudReports::QuestionSheet` is the row/column builder most questions use.

`HudReports::ReportCell` (`report_cell.rb`, table `hud_report_cells`) is keyed by `question` and `cell_name`; `value` aliases the JSON `summary` column. One cell per question has `universe: true` and holds the question's universe plus `metadata['tables']`. `add_universe_members(members)` bulk-imports `HudReports::UniverseMember` rows (`hud_report_universe_members`), each pointing at a `universe_membership` polymorphic record (an `AprClient`, `SpmEnrollment`, or other `HudReports::ReportClientBase` subclass) and caching `first_name`/`last_name` as `pii_attr`s for drilldown display. `ReportCell#members` joins the polymorphic table by reading the class of the first member, because all members of one cell share a table.

`HudReports::ReportClientBase` is the abstract base for snapshot models: `display_value` routes columns through `HudHelper.util` and `GrdaWarehouse::PiiProvider`; `search_clients` implements drilldown search and excludes `hmis_restricted_source_client_ids` from PII-column matches.

### Lifecycle and progress

`Reporting::Hud::RunReportJob` (`app/jobs/reporting/hud/run_report_job.rb`) runs on the long-running queue and declares `self.interruptible? = true`, so `ReportInstance#check_halt_status!` can raise `JobCancelled` between checkpoints. `perform` reloads the instance (returns silently if deleted), sets `report.active_job`, and for `manual` runs takes an advisory lock named after the generator class to count `created_recently.incomplete.started.for_report(report_name)`; more than one means another copy is running and the job is requeued four minutes out with `requeue_at`.

`run_report` fails fast when `report.started_at` is set and the generator does not support idempotent retry (writes `error_details`, raises `NonIdempotentRetryError`). It then wraps `generator.prepare_report` in `report.track_progress('Preparation')`, and for each entry in `generator.class.questions` that is in `build_for_questions` and not already in `completed_questions`, runs `klass.new(generator, report).run!` inside `track_progress(question_number)`. Any exception marks the instance `Failed` and re-raises. Success calls `report.complete_report` and mails `NotifyUser.driver_hud_report_finished`.

`ReportInstance#track_progress(name)` creates a `HudReports::ReportCheckpoint` (`hud_report_checkpoints`, status `running`/`success`/`error`), yields, and records `completed_at`. If a `success` checkpoint with that name already exists it returns it without yielding, which is how a retried run skips Preparation. `ReportCheckpoint.calculate_duration_seconds` merges overlapping intervals; `ReportInstance#total_duration_in_words` prefers it over wall clock.

State is a string column: `Waiting` -> `Started` (`start_report`, which sets `started_at` only once) -> `Completed` (`complete_report`, when `remaining_questions` is empty) or `Failed`. `current_status` derives the display label, treating a `Started` instance older than 24 hours, or one whose `Delayed::Job` is missing or failed, as `Failed`, and a purged instance as `Archived`.

### Fiscal-year registration

A report year is a sibling namespace, not an edit: `HudApr::Generators::Apr::Fy2020`, `Fy2021`, `Fy2023`, `Fy2024`, `Fy2026` each have their own `Generator` and question classes under `drivers/hud_apr/app/models/hud_apr/generators/apr/<fy>/`, usually subclassing shared question logic under `generators/shared/<fy>/`. `drivers/hud_apr/config/initializers/hud_apr_feature.rb` registers every year of APR, CAPER, CE-APR, and DQ with the same `title` and route helper, so the controller can list one link per report type (`report_urls` uniqs on title).

`HudReports::BaseController#available_report_versions` lists the selectable slugs (`fy2020`, `fy2021`, `fy2023`, `fy2024`, `fy2026`) and marks one active based on `default_report_version`, which is `"fy#{HudHelper.hud_csv_version}"`. `generator` resolves `possible_generator_classes[report_version]`, where `report_version` comes from the filter params, the saved instance's `options['report_version']`, or the default. `report_scope` matches `report_name` against every possible generator's `title`, so the history list shows all years of one report.

Driver feature initializers load from `config/application.rb`'s `load_driver_feature_initializers` initializer, after core `config/initializers`, using `Dir[...].sort`. Driver `app/models`, `app/controllers`, and similar directories are added to `autoload_paths` and `eager_load_paths` there as well.

The newest year is the template for the next one. Older years are kept so historical instances still render and drill down. Some are read-only stubs: `HudApr::Generators::Apr::Fy2020` question classes keep `QUESTION_NUMBER`, headers, and `table_descriptions` but have no `run_question!`, so they cannot produce a new run. FY2021 through FY2026 APR questions still define `run_question!`. Per-driver year status is in `hud-reporting/report-drivers.md`.

### Driver extensions

Core models include driver concerns rather than declaring driver-specific associations themselves. `HudReports::UniverseMember` includes `HopwaCaper::HudReports::UniverseMemberExtension`, `HudApr::...`, `HudDataQualityReport::...`, `HudHic::...`, `HudPathReport::...`, `HudPit::...`, and `HudSpmReport::HudReports::UniverseMemberExtension`. `HudReports::ReportInstance` includes `HopwaCaper::HudReports::ReportInstanceExtension`, `HudSpmReport::HudReports::ReportInstanceExtension`, and `HudReportArchival`.

Each extension lives at `drivers/<driver>/app/models/<namespace>/extensions/hud_reports/<model>_extension.rb` and is an `ActiveSupport::Concern` whose `included` block adds associations. `drivers/hud_apr/app/models/hud_apr/extensions/hud_reports/universe_member_extension.rb` adds `belongs_to :apr_client` (plus `:hud_report_apr_client` and `:ce_apr_client` aliases) scoped to `universe_membership_type = 'HudApr::Fy2020::AprClient'` on `universe_membership_id`. The snapshot model declares the inverse: `HudApr::Fy2020::AprClient` has `has_many :hud_reports_universe_members, inverse_of: :universe_membership, foreign_key: :universe_membership_id`. The HOPWA `ReportInstanceExtension` adds `has_many :hopwa_caper_enrollments/_services/_funders, dependent: :delete_all`.

The include list in the core model is hard-coded; adding a driver means editing `universe_member.rb` or `report_instance.rb` to include the new concern, then creating the concern file at the conventional path. The concerns resolve through the driver autoload paths configured in `config/application.rb`, so nothing else registers them.

Archival is also extension-shaped: `HudReportArchival.register_archival_generator(title, klass)` is called from a per-driver concern (`HudApr::Archival`, `HudSpmReport::Archival`) that each generator includes as its last line, and `HudReportArchival`'s `included` block declares every driver's `has_one_attached :<prefix>_..._csv` up front.

### HouseholdContext

`HudReports::HouseholdContext` (`hud_report_household_contexts`) stores one row per in-universe `ServiceHistoryEnrollment` per report run with household-level values resolved once: the anchor head of household's ids and dates, `household_type`, `inherited_chronic_status`/`_detail`, `inherited_move_in_date`, `inherited_date_to_street`, `is_parenting_youth`, `non_youth_household`, `hoh_length_of_stay`, `hh_max_age`. `ReportInstance has_many :household_contexts, dependent: :delete_all`.

`HudReports::HouseholdContextBuilder.call(generator, report, enrollment_scope:, source_report_id: nil, lookback_years: 2)` fills it during `prepare_report`. It first deletes any existing rows for the run, so it is safe under retry. With `source_report_id` it copies matching rows from another instance via `HouseholdContext.copy_subset!` after checking the date ranges match. Otherwise it snapshots the universe in a `REPEATABLE READ` transaction (skipped when already inside one, as in specs), groups by `COALESCE(household_id, enrollment_group_id || '*HH')` and `data_source_id`, loads every enrollment for those households back to `start_date - lookback_years` with `preload(enrollment: [:client, :disabilities_at_entry, :project])`, picks the anchor HoH (`find_anchor_hoh`: active first, latest entry, has move-in, lowest id), and imports in batches of 2000. Night-by-night enrollments count as active only with a bed night or exit in range (`nbn_active?`).

Pure rules are class methods on `HudReports::HouseholdLogic`: `calculate_household_type`, `calculate_chronic_status` (two modes keyed by `chronic_status_key`, `:chronic_status` or `:pit_chronic_status`), `calculate_move_in_date`, `calculate_date_to_street`, `calculate_length_of_stay`, `calculate_is_parenting_youth`, `only_youth?`, `any_youth_children?`. They take plain hashes so both the builder and older hash-based code can call them; `HouseholdContext#to_legacy_member_hash` converts a row back to that shape.

As of 2026-09 only `HudSpmReport::Generators::Fy2026::Generator#prepare_report` calls the builder (`lookback_years: 7`). `HudApr::Generators::Dq::Fy2026::Generator` still reads a `source_report_id_for_contexts` option but no longer acts on it. APR, CAPER, DQ, PIT, PATH, and LSA compute household attributes inline (`app/models/concerns/hud_reports/households.rb`).

Rows are pruned by `HouseholdContext.prune!` from `Importing::RunDailyImportsJob` (`'Prune HUD report data'` maintenance task): anything for an instance older than two weeks or with no instance.

### Snapshot patterns

Two patterns coexist and the retry behavior follows from which one a generator uses.

Eager snapshot with retry (SPM FY2026 only; the HOPWA CAPER FY2026 generator has the override commented out): the generator overrides `self.supports_idempotent_retry?` to `true`. `prepare_report` builds shared snapshot rows (for SPM, `HudSpmReport::Fy2026::SpmEnrollment`, plus `HouseholdContext`). `ReportInstance#snapshot_status` (`mark_snapshot_started!`, `mark_snapshot_completed!`, `snapshot_completed?`, constants on `GeneratorBase`) lets a generator skip rebuilding on retry. Each question is independent; before it runs, `QuestionBase#prepare_for_run` calls `self.class.reset_derived_data(report)` (a no-op unless overridden, for example to delete SPM `Return` rows) and `report.reset_question(question_number)`, which `delete_all`s the question's universe members and cells. `RunReportJob` skips questions already in `completed_questions` and `track_progress` skips a successful Preparation, so a re-run resumes.

Lazy shared universe without retry (PIT, older APR years): `supports_idempotent_retry?` stays `false`. The first question populates a universe that later questions read; nothing resets per question. `RunReportJob` refuses any run where `started_at` is set, records the original `Delayed::Job` error under `"\nOriginal failure:\n"` in `error_details`, and the user creates a new instance.

`BaseJob#supports_idempotent_retry?` reads the generator class name from the job arguments through `JobDetail#job_class` and asks the generator, so `calculated_attempts` gives non-idempotent report jobs a single attempt.

`ReportInstance#_purge_universe` deletes every snapshot row, universe member, and cell for an instance without changing state; it is a debugging tool, not part of the run path.

### Drilldowns and archival

A cell view is `HudReports::DrilldownContext` (`drilldown_context.rb`), a `Struct` built by `GeneratorBase.drilldown_context`. `build` sanitizes `cell_id` and `table_id` to `[.A-Z0-9 -]` and resolves `measure_id` through the generator's `valid_question_number` when the generator overrides it. `base_scope` is `generator.client_scope(measure)` (or `client_class(measure)`) joined through `hud_reports_universe_members -> report_cell -> report_instance` and filtered by table, cell, and instance id. `filtered_scope` applies `search_clients` when the snapshot model reports `searchable?`. `export_headers` drops `generator.pii_columns` unless `GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)`.

Controllers include `HudReports::CellDrilldownConcern` (`app/controllers/concerns/hud_reports/cell_drilldown_concern.rb`), which provides `show` and `search` (search terms come from a saved `GrdaWarehouse::ClientSearchQuery` by `query_id`), paginates 100 per page, and preloads `policy_context.preload_project_dependencies` for the page. Subclasses supply `report_param_name`, `measure_id`, `export_class_name`, `export_query_params`, and path helpers; `HudApr::CellsController` is the reference implementation. Excel export subclasses `HudReports::CellDetailExportBuilderBase`, which streams `find_in_batches` and asks `user.reporting_policy_for_project(project_id:, mode: :download, client_id:)` per row before `display_value`.

Archival (`app/models/concerns/hud_report_archival.rb`): a generator's `archival_csv_config(report_instance)` returns `{ attachment_name => { scope:, filename:, delete_order: } }`, usually `HudReportArchival.shared_archival_entries` (universe members, cells) merged with driver tables. `HudReports::ArchiveReportService#archive!` writes each scope to CSV via Active Storage, JSON-encoding json/jsonb columns, skips attachments already present, and sets `archival_metadata['archived_at']` only when every file succeeded. `HudReports::PurgeArchivedReportDataService` then deletes rows; `archive_and_purge!` chains both. `HudReports::RestoreArchivedReportDataService#restore!` upserts CSV rows in reverse `delete_order` with `unique_by: :id`, resets sequences, and clears `purged_at`. `rake reports:archive_and_purge_hud_reports[dry_run]` (`lib/tasks/reports/migrate_to_csv.rake`) selects `ReportInstance.purge_eligible(grace_period_days)`; the grace period defaults to 60 days via `Reports.archival_grace_period_days`.

### Access

There is no `visible_to`-style scope on `ReportInstance`; visibility is enforced in `HudReports::BaseController`. `before_action :require_can_view_hud_reports!` is generated by `LegacyControllerAuthorization` from `UserPermissions#can_view_hud_reports`, which is `can_view_own_hud_reports? || can_view_all_hud_reports?`. `apply_view_filters` adds `where(user_id: current_user.id)` unless `can_view_all_hud_reports?`, in which case the history view offers a creator filter instead. `set_report` finds the instance in the same scoped relation, so a URL for another user's run 404s for own-only users. `QuestionBase.most_recent_answer(user:, report_name:)` applies the same rule when looking up the latest completed universe cell.

The two permissions are defined in `app/models/role.rb`: `can_view_all_hud_reports` (administrative; run any HUD report limited by data access, and see every run) and `can_view_own_hud_reports` (run any HUD report, see only own runs). Both are legacy role flags, not access-control-list permissions; `authorization/warehouse-legacy-roles.md` covers that split.

`ReportInstance#policy_class` returns `GrdaWarehouse::AuthPolicies::HudReportPolicy` (`app/models/grda_warehouse/auth_policies/hud_report_policy.rb`). As of 2026-09 it exposes one method, `can_view_checkpoints?` (`can_view_all_hud_reports? && can_manage_config?`), and wraps the user flags because no collection or access group maps to report instances. `authorization/warehouse-policies.md` describes the policy pattern.

Data inside a run is limited by the filter saved at creation: `GeneratorBase#client_scope` builds `filter_class.new(user_id: report.user_id, ...)` from `report.options`, so project and CoC access is the creator's at run time. Drilldown rows apply the viewer's PII policy per project (`reporting_policy_for_project`), and export headers drop PII columns unless the site config allows them.

## Key files

- `app/models/hud_reports/generator_base.rb:29` `find_report`; `:48` `supports_idempotent_retry?` default false; `:52` `queue`; `:59` `prepare_report`; `:63` `run!`; `:71` `base_enrollment_scope`; `:82` `client_scope`; `:150` `drilldown_context`; `:169` `allowed_options`.
- `app/models/hud_reports/question_base.rb:17` `initialize`; `:43` `run!`; `:58` `most_recent_answer`; `:75` `reset_derived_data`; `:83` `prepare_for_run`.
- `app/models/hud_reports/report_instance.rb:23` driver extension includes; `:60` `policy_class`; `:64` `from_filter`; `:78` `current_status`; `:134` `reset_question`; `:172` `start`; `:176` `start_report`; `:187` `track_progress`; `:214` `complete`; `:259` `answer`; `:276` `universe`; `:283` `_purge_universe`.
- `app/models/hud_reports/report_cell.rb:23` `value` alias; `:79` `add_universe_members`; `:99` `write_detail`; `:179` `join_universe`.
- `app/models/hud_reports/universe_member.rb:14` extension includes; `:29` polymorphic `universe_membership`.
- `app/models/hud_reports/report_client_base.rb:16` `display_value`; `:32` `search_clients`; `:55` `restricted_condition`; `:121` `transform_value`.
- `app/models/hud_reports/household_context.rb:33` `prune!`; `:44` `copy_subset!`; `:61` `to_legacy_member_hash`.
- `app/models/hud_reports/household_context_builder.rb:15` `initialize`; `:23` `call`; `:89` `snapshot_universe!`; `:254` `find_anchor_hoh`; `:308` context attributes.
- `app/models/hud_reports/household_logic.rb:22` `calculate_household_type`; `:46` `calculate_chronic_status`; `:90` `calculate_move_in_date`; `:127` `calculate_date_to_street`; `:148` `calculate_length_of_stay`; `:157` `calculate_is_parenting_youth`.
- `app/models/hud_reports/report_checkpoint.rb:14` status values; `:20` `calculate_duration_seconds`.
- `app/models/hud_reports/drilldown_context.rb:28` `build`; `:87` `base_scope`; `:105` `export_headers`; `:112` `filtered_scope`.
- `app/models/hud_reports/cell_detail_export_builder_base.rb:38` `call`; `:67` `build_package`; `:79` per-row PII policy.
- `app/models/concerns/hud_report_archival.rb:17` `register_archival_generator`; `:29` `shared_archival_entries`; `:82` `purge_eligible`; `:104` `archived?`; `:228` `archive_and_purge!`.
- `app/controllers/hud_reports/base_controller.rb:11` `require_can_view_hud_reports!`; `:58` `create`; `:69` `restore`; `:115` `available_report_versions`; `:141` `default_report_version`; `:173` `apply_view_filters`; `:200` `set_report`; `:305` `report_scope`; `:309` `generator`; `:340` `report_version`.
- `app/controllers/concerns/hud_reports/cell_drilldown_concern.rb:42` `show`; `:51` `search`; `:67` `set_drilldown_context`; `:93` `render_html_response`.
- `app/jobs/reporting/hud/run_report_job.rb:21` `perform`; `:52` `check_and_requeue_for_running`; `:78` non-idempotent fail-fast; `:85` Preparation checkpoint; `:90` question loop; `:106` `capture_failure`.
- `app/jobs/importing/run_daily_imports_job.rb:180` `HouseholdContext.prune!`.
- `app/services/hud_reports/archive_report_service.rb:34` `archive!`.
- `app/services/hud_reports/restore_archived_report_data_service.rb:32` `restore!`; `:159` `reset_sequences`.
- `app/models/grda_warehouse/auth_policies/hud_report_policy.rb:17` `can_view_checkpoints?`.
- `lib/hud_reports/route_concerns.rb:19` `hud_report_actions`; `:30` `hud_drilldown_actions`.
- `lib/tasks/reports/migrate_to_csv.rake:117` `archive_and_purge_hud_reports`.
- `config/application.rb:172` driver autoload paths; `:213` `config.hud_reports = {}`; `:235` `load_driver_feature_initializers`.
- `drivers/hud_apr/config/initializers/hud_apr_feature.rb:29` FY2026 APR registration.
- `drivers/hud_apr/app/models/hud_apr/extensions/hud_reports/universe_member_extension.rb:14` `belongs_to :apr_client`.
- `drivers/hud_apr/app/models/hud_apr/generators/apr/fy2026/generator.rb:41` `questions`; `:78` `include HudApr::Archival` last.
- `drivers/hud_apr/app/models/hud_apr/generators/apr/fy2026/question_four.rb:13` `run_question!` shape.
- `drivers/hud_spm_report/app/models/hud_spm_report/generators/fy2026/generator.rb:25` `supports_idempotent_retry?`; `:37` `prepare_report` with `HouseholdContextBuilder`; `:91` `archival_csv_config`.
- `drivers/hud_spm_report/app/models/hud_spm_report/extensions/hud_reports/report_instance_extension.rb:14` `default_report_version` evaluated at include time.

## Gotchas

- Report type is `ReportInstance#report_name`, the generator's `title` string (`"Annual Performance Report - FY 2026"`), not STI `type`. Renaming `generic_title` or `fiscal_year` orphans existing instances from `report_scope` and from `HudReportArchival.generator_registry`; archives store `generator_class` in `archival_metadata` to survive that, but the history list does not.
- `has_many :report_cells` and `has_many :universe_members` have no `dependent:`; destroying an instance soft-deletes only the instance row. Cells, members, and snapshot rows stay until archival purge or `_purge_universe`.
- `ReportCell#join_universe` picks the join table from the first member's class. A cell whose members span two snapshot tables produces wrong counts silently.
- `reset_question` runs only when `supports_idempotent_retry?` is true. Flipping that flag to true on a lazy-shared-universe generator makes retries delete the universe that later questions depend on.
- `RunReportJob` raises `NonIdempotentRetryError` whenever `started_at` is set, including a run that was cancelled mid-question. The UI path is a new instance.
- `track_progress` skips a step only on a `success` checkpoint with the same name. Question numbers are the checkpoint names, so two questions with the same `QUESTION_NUMBER` collide.
- `HudSpmReport::HudReports::ReportInstanceExtension` evaluates `HudReports::BaseController.new.default_report_version` when included at boot, so `report_instance.spm_enrollments` points at the current year's `SpmEnrollment` table regardless of the instance's own year.
- `HudApr` universe members always join `HudApr::Fy2020::AprClient`; the APR snapshot table did not move when new years were added.
- The manual-run advisory lock counts instances by `report_name`, so two users running the same report year serialize; automated (`manual: false`) runs bypass the check.
- Extension load order: `universe_member.rb` and `report_instance.rb` reference driver constants at class load; there is no conditional include.
- Restored archives keep `archived_at` and the CSVs; only `purged_at` is cleared, so a second purge does not re-archive.
- `HouseholdContext.prune!` runs daily and deletes rows for instances older than two weeks; a re-run of an old SPM instance rebuilds them in `prepare_report`.

## Do not repeat

Repo-wide entries: `conventions/do-not-repeat.md` covers `RailsDrivers.loaded` gating and `require_can_*!` before_actions.

- Editing a shipped fiscal-year generator or its questions to meet a new spec. Instead: copy the newest year into a new sibling namespace (`drivers/hud_apr/app/models/hud_apr/generators/apr/fy2026/` is the current template), register it in the driver feature initializer, and add its slug to `HudReports::BaseController#available_report_versions`. Old years stay so old instances render.
- Using a stub year as the template. `HudApr::Generators::Apr::Fy2020` questions have no `run_question!`; copying them produces a generator that cannot run.
- A lazy shared universe for a new report (first question builds, later questions read, `supports_idempotent_retry?` false). Instead: build snapshots in `prepare_report`, guard with `snapshot_status`, override `supports_idempotent_retry?` to true, and implement `reset_derived_data` where a question writes derived rows. `drivers/hud_spm_report/app/models/hud_spm_report/generators/fy2026/generator.rb` is the example.
- Declaring driver associations on `HudReports::UniverseMember` or `ReportInstance` directly. Instead: an `extensions/hud_reports/*_extension.rb` concern in the driver, included from the core model (`drivers/hud_apr/app/models/hud_apr/extensions/hud_reports/universe_member_extension.rb`).
- Recomputing household inheritance inline in a new FY2026+ question. Instead: `HudReports::HouseholdLogic` for the rule and `HudReports::HouseholdContextBuilder` in `prepare_report` when the report needs rows.
- Gating report code on `RailsDrivers.loaded.include?('hud_apr')`. All drivers always load; see `conventions/do-not-repeat.md`.
- Ad hoc cell drilldown controllers. Instead: include `HudReports::CellDrilldownConcern` and implement its required methods, as `drivers/hud_apr/app/controllers/hud_apr/cells_controller.rb` does.
- Reading `ReportInstance#type` to decide the report kind. Instead: `report_name` and `possible_generator_classes` on the controller.

## Related

- `hud-reporting/report-drivers.md`: per-driver generators, runnable versus stub years, snapshot models, LSA and PIT specifics.
- `hud-reporting/hud-utility-versions.md`: `HudHelper.util(version)` used by `default_project_type_codes` and `ReportClientBase#transform_value`.
- `hud-reporting/service-history.md`: `GrdaWarehouse::ServiceHistoryEnrollment`, the base scope for every generator.
- `authorization/warehouse-policies.md`: `GrdaWarehouse::AuthPolicies::*` including `HudReportPolicy`; `authorization/warehouse-legacy-roles.md`: `can_view_all_hud_reports` / `can_view_own_hud_reports`.
- `conventions/do-not-repeat.md`: `RailsDrivers.loaded`, `require_can_*!`.
- `docs/features/warehouse/hud-report-framework.md`: human-facing overview with the class diagram.
