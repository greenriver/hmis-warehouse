---
title: Warehouse reports framework
summary: "How ad hoc warehouse reports are registered, filtered, run in the background, exported, published, and archived. Covers ReportDefinition and per-user access, Filters::FilterBase and Filters::Criteria, background_render_action, GenericReportJob and SimpleReports::ReportInstance, document exports, S3 publishing, PII redaction in detail rows, and CSV archival."
area: warehouse
tags: [warehouse-reports, ReportDefinition, ReportDefinitionsUser, WarehouseReportAuthorization, Filters::FilterBase, Filters::Criteria, effective_project_ids, background_render_action, BackgroundRenderJob, GenericReportJob, SimpleReports::ReportInstance, DocumentExport, WarehouseReports::Export, Publish, S3Toolset, PiiDetailRows, ReportArchival, archival]
sources:
  - app/models/grda_warehouse/warehouse_reports/report_definition.rb
  - app/models/grda_warehouse/warehouse_reports/report_definitions_user.rb
  - app/models/grda_warehouse/warehouse_reports/base.rb
  - app/models/simple_reports/report_instance.rb
  - app/controllers/warehouse_reports_controller.rb
  - app/controllers/concerns/warehouse_report_authorization.rb
  - app/controllers/concerns/background_render_action.rb
  - app/controllers/warehouse_reports/chronic_controller.rb
  - app/controllers/warehouse_reports/client_details/entries_controller.rb
  - app/controllers/document_exports_controller_base.rb
  - app/jobs/warehouse_reports/generic_report_job.rb
  - app/jobs/warehouse_reports/run_chronic_job.rb
  - app/jobs/background_render_job.rb
  - app/jobs/background_render/entry_clients_report_job.rb
  - app/models/filters/filter_base.rb
  - app/models/filters/criteria.rb
  - app/models/filters/criteria/base.rb
  - app/models/filters/criteria/configuration.rb
  - app/models/filters/criteria/filter_for_projects.rb
  - app/models/filters/criteria/filter_for_range.rb
  - app/models/filters/criteria/filter_for_user_access.rb
  - app/models/concerns/warehouse_reports/export.rb
  - app/models/concerns/warehouse_reports/publish.rb
  - app/models/concerns/warehouse_reports/s3_toolset.rb
  - app/models/concerns/warehouse_reports/pii_detail_rows.rb
  - app/models/concerns/report_archival.rb
  - app/models/grda_warehouse/document_exports/base_performance_export.rb
  - app/models/grda_warehouse/document_exports/client_performance_export.rb
related:
  - hud-reporting/report-framework.md
  - warehouse/pii-and-restricted-clients.md
  - authorization/warehouse-access-controls.md
  - authorization/warehouse-policies.md
  - conventions/do-not-repeat.md
---

## Purpose

"Warehouse reports" are the ad hoc reports listed at `/warehouse_reports`: everything under
`app/controllers/warehouse_reports/` plus the `warehouse_reports` controller namespaces inside
drivers. They are distinct from the HUD compliance reports (APR, SPM, LSA, and the rest), which
run through `HudReports::GeneratorBase` and are documented in
`hud-reporting/report-framework.md`.

The framework has six loosely coupled parts:

- Registration and access: `GrdaWarehouse::WarehouseReports::ReportDefinition` rows, one per
  report URL, granted to users through collections or access groups, and checked by the
  `WarehouseReportAuthorization` controller concern.
- Filtering: `Filters::FilterBase`, a `ModelForm` with about ninety attributes, resolving the
  user's selection to a set of project ids the user may see, and `Filters::Criteria`, small
  classes that apply one condition each to an enrollment scope.
- Running: three patterns. Synchronous rendering in the controller; live rendering of one page
  section by a background job pushed over ActionCable (`background_render_action`); and
  persisted results written by a job, either a bespoke job such as
  `WarehouseReports::RunChronicJob` or `WarehouseReports::GenericReportJob` calling
  `run_and_save!` on a report model. Driver reports that persist rows subclass
  `SimpleReports::ReportInstance`.
- Exports: `GrdaWarehouse::DocumentExport` subclasses build a PDF or Excel file in a job, and
  `WarehouseReports::PiiDetailRows` redacts name, DOB, and SSN in client-level rows per viewer.
- Publishing: `WarehouseReports::Publish` and `WarehouseReports::S3Toolset` push a rendered
  report to a public S3 website bucket and record a `GrdaWarehouse::PublishedReport`.
- Archival: `ReportArchival` writes a `SimpleReports::ReportInstance` subclass's rows to CSV
  attachments and purges the rows after a grace period; a reload service restores them.

This doc describes the shared machinery. Individual reports (chronic, client details, youth,
touch points, and the driver reports) are not described one by one.

## Entry points

- `WarehouseReportsController#index` (`app/controllers/warehouse_reports_controller.rb`): lists
  `current_user.reports.order(name: :asc)` grouped by `report_group`, the seven most recently
  viewed from `current_user.activity_logs.warehouse_reports` in the last week, and
  `current_user.favorite_reports`. It skips `report_visible?`; each report page checks itself.
- `WarehouseReportAuthorization` (`app/controllers/concerns/warehouse_report_authorization.rb`):
  `include` in every report controller. Adds `before_action :report_visible?` and
  `before_action :require_can_view_any_reports!`, plus `set_limited` and `reload_from_csv`.
- `GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions`: upserts the
  hard-coded `report_list` into the table by `url` and soft-deletes retired URLs. Called from
  `db/seed_maker.rb` (so `db/seeds.rb` runs it) and from `spec/rails_helper.rb`; no rake task or
  deploy hook calls it on its own.
- `Filters::FilterBase.new(user_id: current_user.id).update(params[:filters])` or
  `.set_from_params(...)`; `filter.for_params` serializes it for a job; `filter.apply(scope,
  report_scope_source)` or `filter.apply_criteria(scope, tags: [...])` applies criteria.
- `extend BackgroundRenderAction` then
  `background_render_action :render_section, ::BackgroundRender::SomeJob do { ... } end` in a
  controller; a `BackgroundRenderJob` subclass implements `render_html(**options)`.
- `WarehouseReports::GenericReportJob.perform_later(user_id:, report_class:, report_id:)` for a
  report class listed in `GenericReportJob#allowed_reports`.
- `DocumentExportsControllerBase#create` with `type` (a class name from
  `valid_document_export_classes`) and `query_string`; the browser polls `show` and then hits
  `download`.
- `report.publish!(user_id)` and `report.unpublish!` on a model including
  `WarehouseReports::Publish`; `ready_public_s3_bucket!` from `S3Toolset` to create the bucket.
- `report.archive_and_purge!(force: false)` on a model including `ReportArchival`;
  `rake reports:csv:archive_and_purge_eligible[dry_run]` (`lib/tasks/reports/migrate_to_csv.rake`);
  no schedule for it is defined in the repository.

## How it works

### Registration and access

`GrdaWarehouse::WarehouseReports::ReportDefinition`
(`app/models/grda_warehouse/warehouse_reports/report_definition.rb`) is a `GrdaWarehouseBase`
row with `url`, `name`, `description`, `report_group`, `limitable`, `enabled`, and `weight`,
`acts_as_paranoid`. `self.report_list` is a hash of group name to array of
`{ url:, name:, description:, limitable: }` entries; the `Public` group is populated only when
`PublicReports::Report.new.ready_public_s3_bucket!` succeeds, so the public reports appear only
where the S3 bucket exists. An entry may add `reporting_query`, a lambda over the
`ActivityLog` Arel table that replaces the default path-prefix match when counting report
usage for the access-log report usage summary. `maintain_report_definitions` runs
`first_or_initialize` by `url`, copies the other fields, then `cleanup_unused_reports`
soft-deletes a fixed list of retired URLs. Adding a report means adding an entry and running
that method.

Access is per definition. `has_many :group_viewable_entities, as: :entity` links definitions to
collections. `viewable_by(user)` has two branches: a user on Access Controls needs
`can_view_assigned_reports?` and a `GroupViewableEntity` in one of
`user.collections_for_permission(:can_view_assigned_reports)`; a legacy-role user with
`can_view_all_reports?` or `can_view_assigned_reports?` gets `where(id: user.reports.pluck(:id))`.
`User#reports` (`app/models/user.rb`) collects `report_ids` from collections or access groups.
`assignable_by(user)` returns everything for `can_assign_reports?` and nothing otherwise.
`limitable: false` marks reports that cannot be limited to a subset of projects; the collection
admin forms pass those ids to the browser as `unlimitable` and show a warning icon. The
`enabled` scope filters the admin pickers. `new_report?` is true for two weeks after creation.

`WarehouseReportAuthorization#report_visible?` calls
`related_report.viewable_by(current_user).exists?` and otherwise `not_authorized!`.
`related_report` derives the URL from `url_for(action: :index, only_path: true)` with the
leading slash removed and looks up definitions by that string, so the route path must equal the
`report_list` `url`. Override `related_report` when they differ. `set_limited` compares all
project ids with `Project.viewable_by(current_user, permission: :can_view_assigned_reports)` and
sets `@limited` and `@visible_projects` for the view.

`GrdaWarehouse::WarehouseReports::ReportDefinitionsUser` has one `belongs_to` and no other
reference in `app`, `drivers`, or `lib`. Favorites use `User#favorite_reports`, a polymorphic
`has_many :through` on `favorites` defined in `UserConcern`.

### Filters and criteria

`Filters::FilterBase` (`app/models/filters/filter_base.rb`) is a `ModelForm` holding every
filter input a warehouse report may take: date range (`start`, `end`, `on`), `project_ids`,
`project_group_ids`, `organization_ids`, `data_source_ids`, `funder_ids`, `coc_codes`,
`project_type_codes` and `project_type_numbers`, demographic arrays, `sub_population`,
`cohort_ids`, `excluded_project_ids`, `excluded_project_type_numbers`, and more. `user_id` is
the only identity; `user` does `User.find(user_id)` unless a `user:` object was passed to
`new`. `update(params)` normalizes incoming arrays and dates; `for_params` and `to_h` serialize
for jobs and cache keys. Many subclasses (`Filters::DateRange`, `Filters::HudFilterBase`,
`Filters::PerformanceDashboard`) narrow the set.

Project resolution starts from `all_project_scope`, which is
`GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports)`;
`all_project_ids` plucks it. `effective_project_ids` unions ids from five inputs: chosen
`project_ids` (cast to integers, not ACL-filtered here), project groups (through
`ProjectGroup.viewable_by(user)`), organizations, data sources, and CoC codes (each through a
scope merged with `all_project_scope`). An empty result becomes `[0]` so a `where(id:)` matches
nothing; `any_effective_project_ids?` ignores that sentinel. `reject_excluded_project_ids`
removes `excluded_project_ids` and projects of `excluded_project_type_numbers`.
`anded_effective_project_ids` intersects the same inputs plus project types.

`Filters::Criteria` (`app/models/filters/criteria.rb`) is a registry: `DEFINITIONS` maps a
criterion id (`:filter_for_projects`) to tags (`:hud`, `:warehouse`, `:project`, `:client`)
and a class `Filters::Criteria::FilterForProjects`. `classes_for_tags(tags)` returns the
classes carrying all given tags; `factory(id, input:, config:)` builds one. Each class
subclasses `Filters::Criteria::Base`, exposing `applies?` and `apply(scope)`, with `input` (the
filter) and `config` (`Filters::Criteria::Configuration`: `include_date_range`,
`report_scope_source` defaulting to `ServiceHistoryEnrollment.entry`, `project_types`,
`join_clients_method`, `chronic_at_entry`, `all_project_types`).

`FilterBase#apply_criteria(scope, tags:, except:, **opts)` instantiates every class for the
tags, drops `except` ids, and reduces the scope through those whose `applies?` is true.
`apply(scope, report_scope_source, ...)` calls it with `tags: [:warehouse]`.
`FilterForUserAccess` always applies and does `scope.joins(:project).merge(viewable_project_scope)`,
which is the ACL boundary for enrollment-level reports. `FilterForProjects` applies when
projects or project groups are chosen, unions group members with `project_ids` (the latter only
when `user.report_filter_visible?(:project_ids)`), returns `scope.none` when groups were chosen
but resolve to nothing, and does `scope.merge(viewable_project_scope).in_project(ids)` in that
order. `FilterForRange` applies `open_between` and, when `require_service_during_range`
(default from `GrdaWarehouse::Config.get(:require_service_for_reporting_default)`),
`with_service_between`.

### Background rendering

`background_render_action` (`app/controllers/concerns/background_render_action.rb`) is a class
method added to a controller with `extend BackgroundRenderAction`. It takes an action name, a
job class, and a block, and defines an action that runs the block with `instance_exec` to build
keyword arguments, calls `job_class.perform_later(params[:render_id], **job_args)`, and returns
`head :ok`. The block runs in the controller, so it can read `@filter` and `current_user`;
`WarehouseReports::ClientDetails::EntriesController` passes
`{ filter: @filter.for_params.to_json, user_id: current_user.id }`.

The browser side is the Stimulus controller `app/javascript/controllers/background_render_controller.js`
(a Sprockets copy exists at `app/assets/javascripts/background_render.js`). On connect it makes a
UUID, subscribes to `BackgroundRenderChannel` with that id, and once connected POSTs its
`fetchParams` plus `render_id` to the action URL. `BackgroundRenderChannel.stream_name(id)` is
`"background_render:#{id}"`.

`BackgroundRenderJob` (`app/jobs/background_render_job.rb`) runs on the short queue. `perform`
first asks the ActionCable Redis pubsub for channel names containing the `render_id`, polling
once a second for up to 15 seconds, and returns without rendering if the browser never
subscribed. It then calls the subclass's `render_html(**options)` and broadcasts a CableReady
`outer_html` operation targeting `[data-background-render-render-id-value="<id>"]`, replacing the
placeholder element. `handle_error` broadcasts an alert, appends the backtrace in development,
and sends the exception to Sentry; the rescue is `rescue Exception`, so the job itself finishes
successfully and Delayed Job does not retry it.

A subclass rebuilds request state from primitives. `BackgroundRender::EntryClientsReportJob`
does `User.find(user_id)`, `Filters::FilterBase.new(user_id:).set_from_params(JSON.parse(filter)...[:filters])`,
builds the report object, and renders with
`WarehouseReports::ClientDetails::EntriesController.render(partial: 'report', assigns: {...},
locals: { current_user: })`. It recomputes `limited` and `visible_projects` for that user rather
than trusting anything from the request. Fourteen controller files use this pattern (sixteen call sites), in core and in
drivers such as `core_demographics_report`, `access_logs`, `boston_reports`, and `analysis_tool`.

### Persisted results and SimpleReports

Reports whose results should outlive the request write them to a table and render from it
later. Two shapes exist.

The older shape is a bespoke job writing a `GrdaWarehouse::WarehouseReports::Base` subclass
(`app/models/grda_warehouse/warehouse_reports/base.rb`, table `warehouse_reports`). `Base` has
`user`, `started_at`, `finished_at`, `parameters`, and a `data` blob; `for_list` selects
everything except `data` and `support`; `completed?`, `status`, and `completed_in` derive from
the timestamps. `WarehouseReports::ChronicController#index` enqueues
`WarehouseReports::RunChronicJob.perform_later(filter_params.merge(current_user_id:
current_user.id))` when the form was submitted, lists `Delayed::Job.jobs_for_class('RunChronicJob')`
as pending runs, and pre-fills the filter from the previous run's `parameters['filter']`.
`RunChronicJob#perform` shims `permit` onto the incoming hash so the controller's `load_filter`
works, builds one `ChronicReport`, stores an array of client attribute hashes (including
`chronic_project_names` and joined disability text) in `data`, and sends
`NotifyUser.chronic_report_finished`. `show` reads `@report.data` and sorts in Ruby.

The current shape is `SimpleReports::ReportInstance` (`app/models/simple_reports/report_instance.rb`,
table `simple_report_instances`, STI on `type`). It has `user`, `report_cells`, `options`,
`started_at`, `completed_at`, `status`, and `archival_metadata`. `viewable_by(user)` returns all
rows for `can_view_all_reports?`, the user's own rows for `can_view_assigned_reports?`, else
none. `universe` and `cell(name)` give the cell rows; `running?` turns false after 24 hours
without completion. Nine driver reports subclass it: `PerformanceMeasurement::Report`,
`SystemPathways::Report`, `CePerformance::Report`, `HomelessSummaryReport::Report`,
`MaYyaReport::Report`, `MaReports::MonthlyPerformance::Report`, `PerformanceMetrics::Report`,
`AllNeighborsSystemDashboard::Report`, and `HapReport::Report`.

`WarehouseReports::GenericReportJob` (`app/jobs/warehouse_reports/generic_report_job.rb`) runs
most of them. `perform(user_id:, report_class:, report_id:)` takes a Postgres advisory lock
named `generic_report_<class>` with zero timeout; if another worker holds it the job is
re-queued for 10 minutes. `run_report` looks the class name up in `allowed_reports`, an
explicit allow-list; an unlisted class pings the notifier and returns false. The report must
respond to `title`, `url`, and `run_and_save!`; on completion `NotifyUser.report_completed`
emails the requester. A report deleted before the job runs returns false quietly.

### Exports and publishing

Document exports produce a downloadable file asynchronously. `GrdaWarehouse::DocumentExport`
(`DocumentExportBehavior`) stores `type`, `user`, `query_string`, `status`, `filename`,
`mime_type`, and `file_data`. `DocumentExportsControllerBase#create` parses `type` against
`valid_document_export_classes`, reuses a recent completed export with the same `type` and
`query_string` from `export_scope`, otherwise builds one; if `export.authorized?` it sets
`PENDING_STATUS`, saves, and enqueues `DocumentExportJob.perform_later(export_id:)`. `show`
returns `{ pollUrl, status, downloadUrl }` without an authorization check; `download` checks
`authorized?` and `completed?` then `send_data`. `DocumentExportJobBehavior#perform` loads
`not_expired.with_current_version`, calls `export.perform`, and emails
`NotifyUser.report_completed`. `PruneDocumentExportsJob` deletes expired rows.

A subclass implements `authorized?`, `perform`, and optionally `download_title`.
`GrdaWarehouse::DocumentExports::ClientPerformanceExport < BasePerformanceExport` is the model:
`authorized?` is `user.can_view_any_reports? && report_class.viewable_by(user)`; `filter` is a
`Filters::PerformanceDashboard` built from `Rack::Utils.parse_nested_query(query_string)['filters']`;
`perform` wraps `PdfGenerator.html(controller:, template:, layout:, user:, assigns:)` and
`PdfGenerator.new.perform(html:, file_name:)` in `with_status_progression`, which sets
`COMPLETED_STATUS` or `ERROR_STATUS` in an `ensure`. New classes must be added to
`valid_document_export_classes`. Human-facing detail: `docs/features/warehouse/document-export.md`.

`WarehouseReports::Export` (`app/models/concerns/warehouse_reports/export.rb`, included by
`GrdaWarehouse::WarehouseReports::Youth::Export` and `Exports::AdHoc`) gives an export model
`filter` (a `Filters::DateRangeAndSourcesResidentialOnly` over `options`), `status`, display
helpers that turn stored ids in `options` into names at render time, and client scoping helpers
merged with `Project.viewable_by(filter.user, permission: :can_view_assigned_reports)`.

`WarehouseReports::PiiDetailRows#redact_pii_in_row(row, headers:, user:, mode:, client_id_index:,
project_id:)` redacts `First Name`, `Last Name`, `DOB`, and `SSN` columns in an array row using
`user.reporting_policy_for_project(project_id:, mode:, client_id:)` and
`GrdaWarehouse::PiiProvider.from_attributes`. `mode: :download` honors the
`include_pii_in_detail_downloads` config. Includers: `DataQualityReportsController` and the
`Details` classes in `destination_report`, `prior_living_situation`, `income_benefits_report`.
Policy detail: `authorization/warehouse-policies.md`.

`WarehouseReports::Publish` (included by `PublicReports::Report`, `PerformanceMeasurement::Report`,
`AllNeighborsSystemDashboard::Report`) needs the model to define `public_s3_directory`, `path`,
`controller_class`, `raw_layout`, `instance_title`, and a `published_reports` association.
`publish!(user_id)` unpublishes any `GrdaWarehouse::PublishedReport` at the same `path`, renders
`as_html` (`controller_class.render(view_template, layout: raw_layout, assigns: { report: self })`,
with section markers when `view_template` is an array), inlines CSS with Premailer, saves
`published_url` and an iframe `embed_code`, then `push_all_to_s3` uploads each `publish_files`
entry with `acl: 'public-read'`. `unpublish!` deletes the objects and clears the row.
`S3Toolset` supplies `ready_public_s3_bucket!` (creates the bucket and website configuration),
the bucket name (`S3_PUBLIC_BUCKET` or `<CLIENT>-<env>-public`), the client (explicit
`S3_PUBLIC_ACCESS_KEY_ID`/`S3_PUBLIC_ACCESS_KEY_SECRET` or the default credential chain), and
`S3_PUBLIC_URL` as the base for `generate_publish_url`.

### Archival

`ReportArchival` (`app/models/concerns/report_archival.rb`) is the CSV archival concern for
`SimpleReports::ReportInstance` subclasses; eight of the nine include it (`HapReport::Report` does
not). HUD report instances use the separate `HudReportArchival`, described in
`hud-reporting/report-framework.md`. Both read the same status methods and grace period.

Including the concern registers the class name in `Rails.application.config.report_archival_types`
(initialized to `[]` in `config/application.rb`); the rake tasks iterate that list. The model
declares `has_many_attached :<name>_csv` for each archived association and overrides
`archival_csv_config` to return `{ name_csv: { association: :items, filename: -> { ... } } }`.
Filenames should include the report type and id to keep attachments distinct.

Status lives in the `archival_metadata` JSON column. `archived?` requires `archived_at` and
every expected file attached; `purged?` means `purged_at` is set; `purge_eligible?` is false
once purged, otherwise compares `purge_eligible_at` (if present) or `completed_at` plus the grace
period with now. The grace period comes from `archival_metadata['grace_period_days']`, else
`AppConfigProperty` key `reports/archival_grace_period_days`, else 60 days;
`Reports.archival_grace_period_days` (`app/services/reports.rb`) exposes the same lookup.
`update_archival_metadata(key, value)` sets one key; setting `purge_eligible_at` schedules an
early purge. `SimpleReports::ReportInstance.purge_eligible(days)` is the SQL form of the same
rule for the batch task.

`archive_and_purge!(force: false)` runs `Reports::ArchiveReportService#archive!` if not yet
archived (idempotent, skips attached files), then `Reports::PurgeArchivedReportDataService#purge!`,
which hard-deletes the association rows in batches of 1,000. Nightly,
`rake reports:csv:archive_and_purge_simple_reports[dry_run]` processes at most 20 eligible
reports oldest first; `archive_and_purge_eligible` runs that and the HUD task.

Restore is `Reports::ReloadReportFromCsvService#reload!`, which `upsert_all`s the CSV rows by
`id`. `WarehouseReportAuthorization#reload_from_csv` wraps it for controllers: it calls
`reload_from_csv_authorization!` (default `require_can_view_any_reports!`), reloads `@report`,
flashes counts or errors, and redirects to `reload_from_csv_redirect_path`. A show view renders
`warehouse_reports/reload_archived_report` when `@report.purged?`. The human guides are
`docs/features/warehouse/report-archival/report-csv-archival-migration-guide.md` and
`report-csv-archival-user-guide.md`; the migration guide names the base class
`GrdaWarehouse::SimpleReports::ReportInstance`, but the constant is `SimpleReports::ReportInstance`.

## Key files

- `app/models/grda_warehouse/warehouse_reports/report_definition.rb:22` `viewable_by`; `:50`
  `assignable_by`; `:64` `maintain_report_definitions`; `:83` `report_list`; `:953`
  `cleanup_unused_reports`.
- `app/models/grda_warehouse/warehouse_reports/report_definitions_user.rb`: unreferenced join
  model.
- `app/controllers/warehouse_reports_controller.rb:13` `index`.
- `app/controllers/concerns/warehouse_report_authorization.rb:15` `report_visible?`; `:24`
  `related_report`; `:32` `set_limited`; `:38` `reload_from_csv`.
- `app/models/filters/filter_base.rb:116` `update`; `:230` `for_params`; `:597`
  `effective_project_ids`; `:646` `apply_criteria`; `:667` `apply`; `:785` `all_project_ids`;
  `:789` `all_project_scope`; `:965` `user`; `:1535` `project_names`.
- `app/models/filters/criteria.rb:29` `classes_for_tags`; `:43` `factory`; `:71` `DEFINITIONS`.
- `app/models/filters/criteria/base.rb:16` `applies?`; `:20` `apply`.
- `app/models/filters/criteria/configuration.rb:14` defaults.
- `app/models/filters/criteria/filter_for_user_access.rb:12` the ACL join.
- `app/models/filters/criteria/filter_for_projects.rb:14` `apply`, order-dependent merge.
- `app/models/filters/criteria/filter_for_range.rb:14` `apply`.
- `app/controllers/concerns/background_render_action.rb:17` `background_render_action`.
- `app/jobs/background_render_job.rb:13` `perform` with the stream wait; `:46` `handle_error`.
- `app/controllers/warehouse_reports/client_details/entries_controller.rb:20` usage.
- `app/jobs/background_render/entry_clients_report_job.rb:10` `render_html`; `:28`
  `visible_projects`.
- `app/controllers/warehouse_reports/chronic_controller.rb:17` `index` enqueue; `:40` `show`.
- `app/jobs/warehouse_reports/run_chronic_job.rb:18` `perform`; `:96` `report.data =`.
- `app/models/grda_warehouse/warehouse_reports/base.rb:17` `for_list`; `:42` `completed?`.
- `app/models/simple_reports/report_instance.rb:17` `viewable_by`; `:28` `purge_eligible`;
  `:50` `running?`.
- `app/jobs/warehouse_reports/generic_report_job.rb:20` `perform`; `:24` advisory lock; `:60`
  `allowed_reports`.
- `app/controllers/document_exports_controller_base.rb:13` `create`; `:49` `find_or_create`;
  `:78` `valid_document_export_classes`.
- `app/models/grda_warehouse/document_exports/base_performance_export.rb:11` `authorized?`.
- `app/models/grda_warehouse/document_exports/client_performance_export.rb:11` `perform`.
- `app/models/concerns/warehouse_reports/export.rb:26` `value_for_display`; `:54` `status`;
  `:83` `clients_within_projects`.
- `app/models/concerns/warehouse_reports/publish.rb:79` `publish!`; `:109` `unpublish!`; `:122`
  `as_html`.
- `app/models/concerns/warehouse_reports/s3_toolset.rb:13` `ready_public_s3_bucket!`; `:67`
  `s3_bucket`; `:104` `push_all_to_s3`.
- `app/models/concerns/warehouse_reports/pii_detail_rows.rb:13` `redact_pii_in_row`.
- `app/models/concerns/report_archival.rb:26` `register_report_type`; `:36`
  `archival_csv_config`; `:62` `purge_eligible?`; `:169` `archive_and_purge!`.

## Gotchas

- Store project ids in report results and resolve names when rendering, per viewer.
  `GrdaWarehouse::Hud::Project#name(user)` returns the real name only when
  `user.policy_for(project).can_view_name?`, else the confidential placeholder, so a name
  resolved for the requesting user and saved into `data` leaks or over-redacts for the next
  viewer. `BackgroundRender::EntryClientsReportJob` recomputes `visible_projects` for the
  rendering user and its partial calls `project.name(current_user)` per row.
  `WarehouseReports::Export#value_for_display` passes `ignore_confidential_status: true`; that
  is safe only because it echoes the viewer's own selection, not result rows.
- `WarehouseReportAuthorization#related_report` matches the controller's index path against
  `ReportDefinition#url` as a string. A route that matches no `report_list` entry makes the
  report `not_authorized!` for everyone, including admins.
- `ReportDefinition.viewable_by` in the legacy branch treats `can_view_all_reports?` and
  `can_view_assigned_reports?` alike. Seeing other users' runs is decided by each report model
  (for example `SimpleReports::ReportInstance.viewable_by`), not by the definition.
- `maintain_report_definitions` runs only from `db/seed_maker.rb` and the spec helper. A new
  `report_list` entry does nothing on an existing installation until someone runs it.
- `FilterBase#effective_project_ids_from_projects` is not ACL-filtered; only
  `FilterForProjects#apply` and `FilterForUserAccess#apply` merge `viewable_project_scope`. A
  query built from `effective_project_ids` alone is not access-limited.
- `effective_project_ids` returns `[0]` when nothing resolves. Use `any_effective_project_ids?`
  rather than `.present?`.
- `FilterBase#user` runs `User.find(user_id)`; a filter built without `user_id` raises when a
  criterion is applied. Jobs should serialize with `for_params.to_json` and rebuild with
  `set_from_params`.
- `BackgroundRenderJob` waits at most 15 seconds for the browser's ActionCable subscription
  and exits silently if it never appears; it reads the Redis pubsub adapter directly, so it
  needs the Redis cable adapter. It rescues `Exception` and returns normally, so Delayed Job
  never retries a failed render.
- `GenericReportJob` serializes runs per report class with an advisory lock; a second request
  waits at least 10 minutes. A class missing from `allowed_reports` fails with only a notifier
  ping.
- `WarehouseReports::Export#status` and `SimpleReports::ReportInstance#running?` both treat a
  run older than 24 hours without completion as failed; nothing marks the row itself.
- Archival: `archived?` is false while any expected file is missing, and the nightly task will
  not purge an incompletely archived report. Restore keeps the CSVs and clears only `purged_at`.

## Do not repeat

Repo-wide entries in `conventions/do-not-repeat.md`: entry 1 (`require_can_*!` before_actions;
`WarehouseReportAuthorization` itself still uses one and is the required hook, but add no
further ones), entry 10 (`rescue StandardError`, as in `WarehouseReports::S3Toolset`), entry 15
(`ENV` for installation settings; the `S3_PUBLIC_*` variables are deployment settings, not a
pattern to extend).

- A report controller with no `ReportDefinition` entry or without
  `include WarehouseReportAuthorization`. Replacement: add the `report_list` entry, include the
  concern, and override `related_report` if the route differs. Current example:
  `app/controllers/warehouse_reports/chronic_controller.rb`.
- Hand-rolled visibility joins in a report model (`joins(:project).merge(Project.viewable_by(...))`
  repeated per report, as in `WarehouseReports::Export#clients_within_projects`). Replacement:
  `filter.apply_criteria(scope, tags: [:warehouse, :project])` or a new `Filters::Criteria`
  class registered in `DEFINITIONS`. Current example: `Filters::Criteria::FilterForUserAccess`.
- Storing a resolved project name, a `Redacted` string, or the confidential placeholder in
  persisted results (`data`, report cells, export rows). Replacement: store `project_id` and
  `client_id`, then `project.name(current_user)` or `PiiDetailRows#redact_pii_in_row` at render.
  Current example: `app/jobs/background_render/entry_clients_report_job.rb`.
- Passing a `User` or `Filters::FilterBase` object to `perform_later`. Replacement: pass
  `user_id` and `filter.for_params.to_json`, rebuild in the job. Current example:
  `app/controllers/warehouse_reports/client_details/entries_controller.rb`.
- Shimming controller `params` behavior into a job, as `RunChronicJob` does with a singleton
  `permit`. Replacement: build the `Filters::FilterBase` from a serialized hash in the job.
- Reading `ReportDefinitionsUser` or writing rows to it. Replacement: collection or access
  group membership through `GroupViewableEntity`; favorites through `User#favorite_reports`.
- A new document export class without adding it to `valid_document_export_classes`, or a new
  `run_and_save!` report without adding it to `GenericReportJob#allowed_reports`. Both lists
  are allow-lists and fail closed.
- A new `SimpleReports::ReportInstance` subclass without `include ReportArchival` and an
  `archival_csv_config`. Current example: `drivers/performance_measurement/app/models/performance_measurement/report.rb`.

## Related

- `hud-reporting/report-framework.md`: HUD compliance reports, `HudReports::ReportInstance`,
  and `HudReportArchival`.
- `warehouse/pii-and-restricted-clients.md`: restriction sources and which surfaces redact.
- `authorization/warehouse-policies.md`: `reporting_policy_for_project`, `PiiProvider`, and
  `Project#name(user)`.
- `authorization/warehouse-access-controls.md`: how `collections_for_permission` and
  `GroupViewableEntity` grant report definitions.
- `conventions/do-not-repeat.md`: entries 1, 10, 15.
- Human-facing sources: `docs/features/warehouse/document-export.md`,
  `docs/features/warehouse/report-archival/report-csv-archival-migration-guide.md`,
  `docs/features/warehouse/report-archival/report-csv-archival-user-guide.md`.
