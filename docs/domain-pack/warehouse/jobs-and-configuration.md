---
title: Background jobs, daily pipeline, and configuration
summary: "BaseJob and Delayed Job queues, the nightly RunDailyImportsJob ordering, TaskQueue for run-once data-repair tasks, and the three configuration homes: GrdaWarehouse::Config for installation settings, AppConfigProperty for JSON key-value config without a natural model, and Translation for user-facing text overrides. Also threshold metric tracking."
area: warehouse
tags: [jobs, BaseJob, ApplicationJob, delayed_job, queues, priority, RunDailyImportsJob, grda_warehouse:daily, grda_warehouse:hourly, TaskQueue, queued_tasks, configuration, GrdaWarehouse::Config, known_configs, AppConfigProperty, Translation, BuildTranslationCacheJob, metric-tracking, MetricDefinition, CollectClientMetricsJob]
sources:
  - app/jobs/application_job.rb
  - app/jobs/base_job.rb
  - app/jobs/importing/run_daily_imports_job.rb
  - app/models/task_queue.rb
  - config/initializers/task_queue.rb
  - config/initializers/delayed_job.rb
  - config/initializers/delayed_job_plugins.rb
  - lib/tasks/delayed_job.rake
  - lib/tasks/grda_warehouse.rake
  - app/models/grda_warehouse/config.rb
  - app/controllers/admin/configs_controller.rb
  - app/models/app_config_property.rb
  - app/models/translation.rb
  - app/jobs/build_translation_cache_job.rb
  - app/models/grda_warehouse/monitoring/metric_definition.rb
  - app/jobs/collect_client_metrics_job.rb
related:
  - hud-reporting/service-history.md
  - conventions/house-style.md
  - conventions/do-not-repeat.md
---

## Purpose

How asynchronous work runs in the warehouse and where installation-specific settings live.
Every background job inherits `BaseJob` (`app/jobs/base_job.rb`) and executes on Delayed Job
with a small fixed set of queues and named priorities. The nightly `Importing::RunDailyImportsJob`
(`app/jobs/importing/run_daily_imports_job.rb`) is the ordered maintenance pipeline that
rebuilds derived data after imports. `TaskQueue` (`app/models/task_queue.rb`) runs a registered
lambda exactly once per deployment, which is the mechanism for data repairs and one-time
backfills. Settings have three homes, all in the database: `GrdaWarehouse::Config`
(`app/models/grda_warehouse/config.rb`) is a single-row model of typed columns edited on the
Site Configuration admin page; `AppConfigProperty` (`app/models/app_config_property.rb`) is a
JSON key-value store for settings that have no column; `Translation`
(`app/models/translation.rb`) overrides user-facing strings per deployment. Threshold metric
tracking (`GrdaWarehouse::Monitoring::MetricDefinition`) is a daily job that records integer
client metrics sparsely and alerts on large moves. An agent adding a job, a scheduled task, a
setting, or a repair should read this doc first to pick the right mechanism.

## Entry points

- Job base classes: `ApplicationJob` (`app/jobs/application_job.rb`, cancellation and
  SIGTERM handling), `BaseJob` (`app/jobs/base_job.rb`, priority constants, retry limits,
  `requeue_at`).
- Worker settings and `Delayed::Job` helpers (`queued?`, `running?`, `cancellable?`):
  `config/initializers/delayed_job.rb`. Worker plugins (job id propagation, SIGTERM stop, AWS
  credential preflight): `config/initializers/delayed_job_plugins.rb`.
- Schedules: `lib/tasks/grda_warehouse.rake` defines `grda_warehouse:daily` (runs
  `Importing::RunDailyImportsJob.new.perform` inline), `grda_warehouse:hourly` (hour-gated
  enqueues, `TaskQueue.queue_unprocessed!`), and `grda_warehouse:monthly`. The cron that
  invokes them lives outside this repository.
- Stale lock cleanup: `delayed_job:prune` in `lib/tasks/delayed_job.rake`, invoked from
  Kubernetes manifests in a separate repository; do not rename it.
- Run-once tasks: `TaskQueue.register_tasks` in `app/models/task_queue.rb`, wired by
  `config/initializers/task_queue.rb`. Drivers add entries to
  `Rails.application.config.queued_tasks` from their feature initializers.
- Installation settings: `GrdaWarehouse::Config.get(:key)`; admin form at
  `Admin::ConfigsController` (`app/controllers/admin/configs_controller.rb`) and the partials
  under `app/views/admin/configs/`.
- Generic key-value settings: `AppConfigProperty.find_by(key:)`; admin CRUD at
  `Admin::AppConfigPropertiesController`.
- Text overrides: `Translation.translate(text)`, exposed to views as `_(text)` in
  `app/helpers/application_helper.rb`; cache warm-up in `BuildTranslationCacheJob`
  (`app/jobs/build_translation_cache_job.rb`).
- Metric tracking: `CollectClientMetricsJob` (`app/jobs/collect_client_metrics_job.rb`),
  `GrdaWarehouse::Monitoring::MetricDefinition`
  (`app/models/grda_warehouse/monitoring/metric_definition.rb`), admin pages at
  `Admin::MetricDefinitionsController` and `Admin::ThresholdNotificationLogsController`.

## How it works

### Jobs

`ApplicationJob < ActiveJob::Base` defines two exceptions: `JobCancelled` (declared with
`discard_on`, so raising it ends the job without retry) and `JobInterrupted` (rescued and
re-enqueued after `RETRY_DELAY_ON_INTERRUPTION` seconds, default 60). A `before_perform` hook,
`check_halt_status!`, raises `JobInterrupted` when the worker is stopping on SIGTERM and
`JobCancelled` when the `Delayed::Job` row has `cancellation_requested_at` set. Only jobs
whose class overrides `self.interruptible?` to `true` can be cancelled after they start.

`BaseJob < ApplicationJob` is what application jobs inherit. It declares priority constants,
lower numbers first: `UI_IMMEDIATE_PRIORITY_NEG5`, `HIGH_IMPORTANCE_PRIORITY_0`,
`DEFAULT_BACKGROUND_PRIORITY_5`, `CLEANUP_BACKGROUND_PRIORITY_6`,
`PRE_BULK_PROCESSING_PRIORITY_9`, `BULK_PROCESSING_PRIORITY_10`, `CACHE_REFRESH_PRIORITY_12`,
`CLEANUP_CACHE_REFRESH_PRIORITY_13`, `MAINTENANCE_PRIORITY_15`. Set one with
`queue_with_priority` in the class or `SomeJob.set(priority: BaseJob::X).perform_later`.

Queues are fixed in `config/initializers/delayed_job.rb`: `short_running` (priority -5),
`default_priority` (0, the default), and `long_running` (5). Jobs choose one with
`queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)` or the `DJ_SHORT_QUEUE_NAME`
equivalent; the ENV lookup exists so deployments can rename queues, not so code reads
settings from ENV. Worker settings: `max_attempts = 3`, `max_run_time = 30.hours`,
`destroy_failed_jobs = false`.

Retries: Active Job ignores Delayed Job's `max_attempts`, so `BaseJob` has an `after_enqueue`
hook that writes the row's `attempts` from `calculated_attempts`. A job is retried up to the
worker limit only when `supports_idempotent_retry?` is true; that method asks the domain class
found by `JobDetail` (a report generator or export class) and defaults to true. Non-idempotent
jobs get one attempt. `requeue_at(timestamp, message)` clones the current `Delayed::Job` row
with cleared failure fields for a later `run_at`; it is used when an advisory lock is held by
another worker.

Errors bubble. On EKS a `rescue_from StandardError` records a Prometheus failure metric and
re-raises. Nothing swallows exceptions; Sentry sees failed jobs through Delayed Job. Long
jobs wrap phases in `instrument_as_maintenance_task(name:)` from
`MaintenanceTaskInstrumentation`, which records a `SystemMaintenanceTaskRun` and lets
`MaintenanceTasksLifecycleJob` alert when a task has not completed within its threshold.

### Daily pipeline

`grda_warehouse:daily` in `lib/tasks/grda_warehouse.rake` runs
`Importing::RunDailyImportsJob.new.perform` inline, not through the queue. `perform` takes the
`run_daily_imports_job` advisory lock on `GrdaWarehouse::DataSource` with a one-second timeout
and exits with a notifier ping if another run holds it. `settle_imports` then waits up to four
five-minute intervals while any importable data source holds a `hud_import_<id>` lock. Each
phase runs inside `run_maintenance_task(name)`, so every phase is a named
`SystemMaintenanceTask` with its own run history.

The phases in code order, each named as in the source: `Update Client ROIs`, `Update HMIS
forms`, `Sync with CAS`, `Identify Duplicates`, `Clean projects & clients`, `Generate service
history and related records`, `Maintain name search maintenance`, `Import Census`,
`Chronically Homeless at Entry`, `Finalize client history`, `Legacy reporting setup`, `Prune
HUD report data`, `System maintenance`. The per-phase detail of what each step calls and why
the ordering matters for service history is in `hud-reporting/service-history.md` under
"Daily pipeline order"; this doc does not restate it.

Two details matter for job authors. Several phases enqueue rather than run:
`ReportingSetupJob`, `Reporting::PopulationDashboardPopulateJob`, `PruneDocumentExportsJob`,
`YouthFollowUpsJob`, `SystemCohortsJob`, and others go to the queue with explicit priorities,
guarded by `Delayed::Job.queued?('ClassName')` so a slow previous night does not double-queue.
And the nightly job is already long; the hourly task comments say new daily work was moved
there for that reason. New scheduled work belongs in `grda_warehouse:hourly` behind an hour
check (`DateTime.current.hour == N`) and `safely_execute`, enqueuing a `BaseJob`, unless it must
be ordered relative to service history generation.

`grda_warehouse:monthly` runs `GrdaWarehouse::Tasks::ClientCleanup` over every destination
client in batches of 10,000 to catch merges and splits without open enrollments.

### TaskQueue

`TaskQueue` (`app/models/task_queue.rb`) runs a registered lambda once per deployment and
records that it ran. It is the mechanism for data repairs, backfills, index builds, and
one-time migrations of application state: the registry in `TaskQueue.register_tasks` holds
examples such as rebuilding `ChEnrollment` rows, migrating collection CoC codes, seeding
`HudListItem`, repairing `Cohort#column_state` rows poisoned by a leaked Active Record object,
backfilling `ActivityLog#reporting_path`, and building indexes with `CREATE INDEX CONCURRENTLY`
one table at a time.

Registration: `config/application.rb` initializes `config.queued_tasks = {}`.
`config/initializers/task_queue.rb` calls `TaskQueue.register_tasks(Rails.application.config)`
in `after_initialize`, which assigns `config.queued_tasks[:task_key] = -> { ... }` for each core
task. Drivers add their own keys in their feature initializers (for example
`drivers/hmis/config/initializers/hmis_feature.rb`). The key is a symbol; the value is a lambda.

Execution: `grda_warehouse:hourly` calls `TaskQueue.queue_unprocessed!`. For every registered
key it takes an advisory lock named `TaskQueue:<key>`, finds the newest active row for that key,
and skips it if `queued_at` is set. Otherwise it creates or reuses the row, stamps `queued_at`,
and enqueues `run!` on the `long_running` queue via `delay`. `run!` stamps `started_at`, calls
the lambda, and stamps `completed_at`. A failure inside the lambda raises to Delayed Job, which
owns retry and reporting.

Re-running a task: insert a new `task_queues` row for the key with `queued_at` nil; the next
hourly pass enqueues it. Keys are not unique across rows for this reason.

Unknown keys: a worker on older code can pick up a job whose key it does not have. `run!`
then clears `queued_at` so a newer worker re-queues it; if the row is older than three days
and never completed, it is marked `active: false` and a Sentry warning is sent.

Do not use `TaskQueue` for recurring work; it has no schedule. Do not delete old entries from
`register_tasks` casually: a deployment that has never run one still needs it.

### Config

`GrdaWarehouse::Config` (`app/models/grda_warehouse/config.rb`) is one row in the warehouse
database's `configs` table with one column per setting. It has `has_paper_trail`, so every
change is versioned, and `after_save :invalidate_cache`. Reads go through
`GrdaWarehouse::Config.get(:key)`, which memoizes the row in a class variable for 30 seconds and
then calls `public_send(key)`. There are around 200 call sites across `app/` and `drivers/`.
Helpers built on `get` include `implied_consent?`, `default_site_coc_codes`, `cas_sync_range`,
`active_consent_class`, and `active_supplemental_enrollment_importer_class`.

Adding a setting takes four steps, all verified from code:

1. Add a column with a migration under `db/warehouse/migrate/`, with a database default that
   preserves current behavior (`dob_selection_method` defaults to `legacy`).
2. Append the column name to `self.known_configs`. That array is the permit list in
   `Admin::ConfigsController#config_params`
   (`params.require(:grda_warehouse_config).permit(config_source.known_configs)`), so a setting
   missing from it is silently dropped on save. Array-valued settings are listed as
   `name: []` (for example `client_details: []`).
3. Add an `f.input :name` to the matching partial under `app/views/admin/configs/`
   (`_roi.haml`, `_cas.haml`, `_client_calculations.haml`, and others). Selects take a
   `collection:` from a class method on the model that returns a label-to-value hash, such as
   `available_release_durations` or `available_roi_models`, with `as: :select_two`.
4. Validate in the model only when one setting depends on another; the single example is
   `validates :cas_sync_project_group_id, presence: ..., if:` for the project-group CAS sync
   methods. A setter can normalize input, as `client_demographic_columns=` strips the hidden
   blank a multi-select posts.

`Admin::ConfigsController#update` assigns attributes, invalidates the class cache, saves, and
enqueues `GrdaWarehouse::Tasks::UpdateHousingReleaseStatusesJob` when `roi_model` changed.
The spec pattern for a new setting asserts `known_configs` includes it and that the default
matches prior behavior (`spec/models/grda_warehouse/config_spec.rb`). `relevant_state_codes`
is memoized in a class variable without the 30-second expiry and changes only on restart.

### AppConfigProperty

`AppConfigProperty` (`app/models/app_config_property.rb`) is a two-column key-value table in
the application database: `key` (string, unique, whitespace-stripped) and `value` (`jsonb`,
required). It exists for settings that have no natural home on a model and do not justify a
`GrdaWarehouse::Config` column: driver feature flags, external integration URLs, retention
knobs, and business-logic toggles.

The admin form edits `value_input`, a virtual attribute. The setter parses the string with
`JSON.parse` and stores the result in `value`; a parse error is kept and surfaced by the
`value_input_is_valid_json` validation. The getter pretty-prints enumerables and `to_json`s
scalars. Because the column is JSON, a stored number or boolean comes back typed; a consumer
does not cast strings.

Keys are namespaced with a slash prefix: `hmis_ce/eligibility_project_group_id`,
`reports/archival_grace_period_days`, `hopwa_caper/atc_tab_enabled`. The consumer pattern is a
small configuration class that loads its prefix once and exposes readers with defaults:
`Hmis::Ce::Configuration` (`drivers/hmis/app/models/hmis/ce/configuration.rb`),
`SoftDeleteRetentionConfiguration` (`app/models/soft_delete_retention_configuration.rb`),
`HopwaCaper::Configuration`. A single lookup with a default is also common:
`AppConfigProperty.find_by(key: 'reports/archival_grace_period_days')&.value || 60`. Specs
create rows directly with `AppConfigProperty.create!(key:, value:)`.

There is no read cache; each `find_by` is a query. Configuration classes memoize per instance,
which is fine for a request or a job and wrong for a long-lived object.

Admin CRUD is `Admin::AppConfigPropertiesController`, gated by `require_can_manage_config!`,
linked from the Site Configuration page sidebar. Unlike `GrdaWarehouse::Config`, there is no
paper trail on this table.

### Translation

`Translation` (`app/models/translation.rb`) lets a deployment override display strings. It is
not i18n: there is no locale. A row has `key` (the default English string that appears in
code) and `text` (the override, or blank). `Translation.translate(text)` returns `text` when
present and otherwise the key; `translate_if_present` returns the override or nil. Views call
`_(text)` from `app/helpers/application_helper.rb`; `translated?(text)` reports whether an
override exists.

Lookups go through `Rails.cache.fetch` keyed by `translations/<MD5 of key>` with an explicit
`expires_in: 8.hours`. On a cache miss, `translate` does `first_or_create` on the key, so an
unknown string is inserted into the table on first render and becomes translatable in the
admin UI. `BuildTranslationCacheJob` warms the whole cache in batches of 500 with
`write_multi` under an advisory lock and is limited to one attempt.

Invalidation is explicit, not a callback: `Admin::TranslationKeysController` and
`Admin::TranslationTextController` call `@translation.invalidate_cache` after saving, which
deletes that one cache key. `Translation.invalidate_translations_cache` deletes every
`translations/*` entry. Saving a `Translation` from a console or a migration without calling
`invalidate_cache` leaves the old value served for up to eight hours.

`Translation.known_translations` is a large static array of every key used in the app, kept
alphabetical, and `default_translations` maps keys that ship with pre-filled override text
(mostly CAS assessment labels). `Translation.maintain_keys` inserts any missing rows from
both; run it after adding keys. The registry is the only inventory of translatable strings, so
a new `_('Some Label')` should also be added to `known_translations`.

Admin editing is at `/admin/translation_keys`, an inline-edit list saved over AJAX.

### Metric tracking

Threshold monitoring records integer client metrics daily and creates a new row only when a
value moves past a configured threshold. `GrdaWarehouse::Monitoring::MetricDefinition`
(`app/models/grda_warehouse/monitoring/metric_definition.rb`) is the catalog: `name`,
`entity_type`, `calculator_class`, `category` (one of `client_services`,
`household_calculations`, `csv_import`), `active`, and admin-editable
`count_change_threshold` and `percent_change_threshold`. `MetricSnapshot` rows hold
`initial_observation_date`, `current_observation_date`, `initial_value`, and `current_value`;
a stable period is one row whose `current_*` fields advance daily.

Calculators live under `app/models/grda_warehouse/monitoring/metric_calculators/` and inherit
`BaseCalculator`. Each defines `metric_definition_attributes` (its own seed row, including an
optional `alert_code`), `calculate_batch(entities, calculation_date)`, and optionally
`change_metrics` to normalize change by elapsed days. `MetricDefinition.available_calculators`
lists the client calculators; `maintain!` seeds a row per calculator with `find_or_create_by!`
under an advisory lock, so admin edits to thresholds survive, and `maintain_csv_metrics!` adds
one `csv_row_count_*` definition per allowed HMIS CSV file for data-source monitoring.

Scheduling: `grda_warehouse:hourly` enqueues `CollectClientMetricsJob` when the current hour
equals `MetricDefinition::COLLECTION_HOUR` (2). The job runs
`MetricSnapshotCollector.run_daily_collection` under the `collect_client_metrics_job` advisory
lock. The collector calls `MetricDefinition.maintain!` first, enqueues
`NotifyMetricThresholdCrossingsJob` for the previous day, and then processes clients in batches
of 5,000 inside a `REPEATABLE READ` transaction. A calculator whose `data_stable?` returns false
is skipped and the job re-enqueues itself for the skipped metrics every five minutes until
`RETRY_DEADLINE_HOUR` (10), after which it logs and gives up for the day.

Adding a metric: create the calculator, add it to `available_calculators`, let the next
collection run seed the definition, then enable it on the admin Metric Definitions page. The
human design doc is `docs/features/warehouse/metric-tracking.md`; its statement that
definitions are initialized through `TaskQueue` is stale, the collector seeds them on every run.

## Key files

- `app/jobs/application_job.rb`: `JobCancelled`, `JobInterrupted`, `check_halt_status!`.
- `app/jobs/base_job.rb`: priority constants, `requeue_at`, `supports_idempotent_retry?`,
  `enforce_max_attempts`.
- `config/initializers/delayed_job.rb`: worker settings, queue names and priorities,
  `Delayed::Job.queued?` and `running?`.
- `config/initializers/delayed_job_plugins.rb`: `DelayedJobJobIdProvider` (sets
  `provider_job_id`), `SignalHandlerPlugin`, AWS credential preflight and failure plugins.
- `lib/tasks/grda_warehouse.rake`: `daily`, `hourly`, `monthly` tasks; the only schedule
  definitions in the repository.
- `lib/tasks/delayed_job.rake`: `delayed_job:prune`, driven by Kubernetes.
- `app/jobs/importing/run_daily_imports_job.rb`: the nightly pipeline.
- `app/models/task_queue.rb` and `config/initializers/task_queue.rb`: run-once tasks.
- `app/models/grda_warehouse/config.rb`: `known_configs`, `get`, `available_*` collections.
- `app/controllers/admin/configs_controller.rb`: the permit list is `known_configs`.
- `app/models/app_config_property.rb`: JSON key-value settings.
- `app/models/translation.rb`, `app/jobs/build_translation_cache_job.rb`: text overrides and
  cache warm-up.
- `app/models/grda_warehouse/monitoring/metric_definition.rb`,
  `app/jobs/collect_client_metrics_job.rb`: metric catalog and daily collection.

## Gotchas

- A running puma process caches each table's column list, so after adding a
  `GrdaWarehouse::Config` column the web process must restart or the new column is silently
  dropped from UPDATE statements.
- A setting missing from `GrdaWarehouse::Config.known_configs` is accepted by the form and
  discarded by strong parameters with no error.
- `GrdaWarehouse::Config.get` is cached for 30 seconds per process; `relevant_state_codes` is
  cached until restart. A spec that changes config must call
  `GrdaWarehouse::Config.invalidate_cache` or create the row before the first read.
- `Translation` cache entries live eight hours and are only invalidated by the admin
  controllers. Changing a row any other way serves stale text.
- `Translation.translate` inserts unknown keys into the database on a cache miss. Passing
  dynamic strings (names, ids) through `_()` fills the table with garbage rows.
- `AppConfigProperty.value` is JSON. A value entered as `"5"` is a string; `5` is an integer.
  Consumers read the parsed type and do not cast.
- The `long_running` queue is where most work goes; `RunDailyImportsJob` itself runs inline
  from the rake task, not from a worker, so its runtime is not visible in `Delayed::Job`.
- `Delayed::Job.queued?('ClassName')` matches on the serialized handler text with `LIKE`, so a
  class name that is a substring of another matches both.
- Jobs enqueued with `perform_later` get their `attempts` set from `calculated_attempts` after
  enqueue; a job class that is not idempotent should override `supports_idempotent_retry?` on
  the domain class `JobDetail` resolves, or accept one attempt.
- `TaskQueue` keys are strings in the table and symbols in the registry; `queue_unprocessed!`
  reads `Rails.application.config.queued_tasks` each hour, so a key must be registered from an
  initializer that runs in every process, not from a file that is only loaded on demand.
- `delayed_job:prune` defaults to failing, not unlocking, stale jobs so non-idempotent work is
  not re-run silently.

## Do not repeat

- Reading `ENV[...]` for a per-installation setting. Use a `GrdaWarehouse::Config` column for a
  known setting or an `AppConfigProperty` key otherwise. The only sanctioned ENV reads in job
  code are the queue-name lookups (`DJ_LONG_QUEUE_NAME`, `DJ_SHORT_QUEUE_NAME`). Catalogued in
  `conventions/do-not-repeat.md`.
- Bare `rescue` or `rescue StandardError` in a job that logs and continues. Let it raise so
  Delayed Job records the failure and Sentry sees it. The EKS `rescue_from StandardError` in
  `BaseJob` re-raises and is not a precedent for swallowing. Catalogued in
  `conventions/do-not-repeat.md`.
- Exceptions for control flow inside jobs. `JobCancelled` and `JobInterrupted` are the two
  sanctioned signals and are raised only by `check_halt_status!`; a job that wants to stop
  early returns.
- Inheriting from `ActiveJob::Base` or `ApplicationJob` directly. Inherit `BaseJob` so
  priorities, retry limits, and metrics apply.
- A new phase in `Importing::RunDailyImportsJob` for work that does not depend on service
  history ordering. Enqueue from `grda_warehouse:hourly` behind an hour check instead, as
  `Hmis::AutoExitJob`, `CollectClientMetricsJob`, and `GenerateClientRoiAuthorizationsJob` do.
- A migration that rewrites application data in Ruby. Register a `TaskQueue` lambda so it runs
  once on a worker with retry and reporting (example: `backfill_activity_log_reporting_path`).
- Saving a `Translation` without calling `invalidate_cache`, or calling `_()` on a string that
  is not a fixed key in `known_translations`.

## Related

- `hud-reporting/service-history.md`: per-step detail of the daily pipeline and why the order
  matters.
- `conventions/house-style.md`: job and configuration conventions in brief.
- `conventions/do-not-repeat.md`: the repo-wide deny-list, including ENV settings and broad
  rescue.
- `docs/features/warehouse/app-config-property.md`, `docs/features/warehouse/translation.md`,
  `docs/features/warehouse/metric-tracking.md`: human-facing feature docs.
