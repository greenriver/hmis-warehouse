---
sources:
  - app/models/grda_warehouse/warehouse_reports/report_definition.rb
  - app/controllers/concerns/warehouse_report_authorization.rb
  - app/models/filters/filter_base.rb
  - app/jobs/background_render_job.rb
  - app/jobs/warehouse_reports/generic_report_job.rb
  - app/models/simple_reports/report_instance.rb
  - app/models/concerns/warehouse_reports/publish.rb
  - app/models/concerns/report_archival.rb
---

# Warehouse Reports Framework

"Warehouse reports" are the ad hoc reports listed at `/warehouse_reports`: everything under `app/controllers/warehouse_reports/` plus the `warehouse_reports` controller namespaces inside drivers. They are distinct from the HUD compliance reports (APR, SPM, LSA, and so on); see [HUD Report Framework](hud-report-framework.md).

This doc covers the shared machinery and the places it is easy to get wrong. Individual reports are not described.

## Registration and per-user access

Each report has a `GrdaWarehouse::WarehouseReports::ReportDefinition` row keyed by URL, granted to users through collections or access groups.

- Adding a report means adding an entry to `report_list` and running `maintain_report_definitions`. It runs only from the seed script, from `GrdaWarehouse::Tasks::GrantAllHudReports`, and from specs. A new entry does nothing on an existing installation until someone runs it. It also soft-deletes a fixed list of retired URLs.
- Every report controller includes `WarehouseReportAuthorization`. It finds the definition by matching the controller's index path against the definition's `url` as a string. A route that matches no `report_list` entry is `not_authorized!` for everyone, admins included; override `related_report` when they differ.
- `limitable: false` marks reports that cannot be limited to a subset of projects.
- `viewable_by` treats `can_view_all_reports?` and `can_view_assigned_reports?` alike in the legacy-role branch. Seeing other users' runs is decided by each report model (for example `SimpleReports::ReportInstance.viewable_by`), not by the definition.
- The `Public` group is listed only when the public S3 bucket exists.
- HUD report entries use `ReportDefinition.hud_url(key)`, which raises `KeyError` on an unknown key instead of silently matching nothing.
- `ReportDefinitionsUser` is an unreferenced join model; don't read or write it. Grant access through collection or access-group membership.

## Filters and criteria

`Filters::FilterBase` holds every filter input a report may take and resolves the user's selection to a set of project ids.

- `effective_project_ids` returns `[0]` when nothing resolves, so a `where(id:)` matches nothing. Use `any_effective_project_ids?` rather than `.present?`.
- `effective_project_ids` is not access-limited for explicitly chosen `project_ids`. Only `Filters::Criteria::FilterForProjects` and `FilterForUserAccess` merge the user's viewable projects. A query built from `effective_project_ids` alone is not safe; apply criteria with `filter.apply_criteria(scope, tags: [:warehouse, :project])` or add a `Filters::Criteria` class instead of hand-rolling visibility joins.
- `FilterBase#user` does `User.find(user_id)`, so a filter built without `user_id` raises when a criterion applies. Jobs should receive `user_id` and `filter.for_params.to_json` and rebuild with `set_from_params`. Don't pass a `User` or filter object to `perform_later`, and don't shim controller `params` behavior into a job.
- For datetime columns use `time_range`; a `Date` upper bound casts to midnight and drops the last day.

## Running reports

Three patterns exist.

**Live background render.** A controller declares `background_render_action`, the browser subscribes over ActionCable, and a `BackgroundRenderJob` renders one page section and pushes it. The job waits up to 15 seconds for the browser's subscription and exits silently if it never appears; it reads the Redis pubsub adapter directly, so it needs the Redis cable adapter. It rescues `Exception` and finishes normally, so Delayed Job never retries a failed render.

**Persisted results.** `WarehouseReports::GenericReportJob` calls `run_and_save!` on a report class. It takes a per-class advisory lock; a second request for the same class is re-queued for 10 minutes. A class missing from `allowed_reports` fails with only a notifier ping. Newer driver reports subclass `SimpleReports::ReportInstance`; older ones use a bespoke job writing a `GrdaWarehouse::WarehouseReports::Base` subclass.

A run older than 24 hours without completion is treated as failed (`SimpleReports::ReportInstance#running?`, `WarehouseReports::Export#status`). Nothing marks the row itself.

**Synchronous.** Rendered in the controller.

`WarehouseReports::Export#value_for_display` passes `ignore_confidential_status: true` when naming the selected projects. That is safe only because it echoes the viewer's own selection, not result rows.

Store project ids and client ids in persisted results and resolve names at render time, per viewer. `Project#name(user)` returns the real name only when the viewer may see it, so a name resolved for the requesting user and saved into the results leaks or over-redacts for the next viewer. `WarehouseReports::PiiDetailRows#redact_pii_in_row` does the same for client-level detail rows; its `:download` mode honors the `include_pii_in_detail_downloads` config.

## Document exports

Exports built as PDF or Excel files run through the `DocumentExport` pipeline; see [Document Export](document-export.md). For a report export, `authorized?` should check the report definition is assigned to the user and look saved reports up through the model's per-user scope. Exports are not shareable between users.

## Publishing

`WarehouseReports::Publish` renders a report and pushes it to a public S3 website bucket, recording a `GrdaWarehouse::PublishedReport`. `publish!` first unpublishes any published report at the same path. `PublicReports::StateDashboard` and the deprecated `PublicReports::StateLevelHomelessness` share one S3 directory, so publishing either unpublishes the other. The bucket name comes from `S3_PUBLIC_BUCKET` when set. When the S3 endpoint is local, only the bucket is created, since the local S3 has no website API.

## Archival

`SimpleReports::ReportInstance` subclasses include `ReportArchival` (HUD report instances use the separate `HudReportArchival`; both share the grace period). A report is archived to CSV attachments, then its rows are purged after a grace period: `archival_metadata`, else the `reports/archival_grace_period_days` `AppConfigProperty`, else 60 days. A scheduled task (`reports:csv:archive_and_purge_eligible`) processes eligible reports; restore reloads the rows from the CSVs.

- A new `SimpleReports::ReportInstance` subclass needs `include ReportArchival` and an `archival_csv_config`; `PerformanceMeasurement::Report` is the model.
- `archived?` is false while any expected file is missing, and the task will not purge an incompletely archived report.
- Restore keeps the CSVs and clears only `purged_at`.

User and migration guides: [CSV archival user guide](report-archival/report-csv-archival-user-guide.md), [migration guide](report-archival/report-csv-archival-migration-guide.md).
