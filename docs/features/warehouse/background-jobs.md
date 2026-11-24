---
sources:
  - app/jobs/application_job.rb
  - app/jobs/base_job.rb
  - app/jobs/importing/run_daily_imports_job.rb
  - app/models/task_queue.rb
  - config/initializers/delayed_job.rb
  - lib/tasks/grda_warehouse.rake
  - lib/tasks/delayed_job.rake
---

# Background Jobs and the Daily Pipeline

Background work runs on Delayed Job. Application jobs inherit `BaseJob` (not `ActiveJob::Base` or `ApplicationJob` directly) so priorities and retry limits apply. This doc covers the choices that are not obvious from the job classes: queues and retries, the nightly import pipeline, and `TaskQueue` for one-off repairs.

## Queues and retries

- Three queues are fixed in `config/initializers/delayed_job.rb`: `short_running`, `default_priority` (the default), and `long_running`. Jobs pick one with `queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)` (or the `DJ_SHORT_QUEUE_NAME` equivalent). The ENV lookup exists so a deployment can rename a queue; it is the only sanctioned ENV read in job code. For per-installation settings, see [App Config Property](app-config-property.md).
- `BaseJob` defines named priority constants (lower runs first). Use these rather than bare numbers.
- Active Job ignores Delayed Job's `max_attempts`, so `BaseJob` writes the attempt count after enqueue. A job is retried up to the worker limit only when `supports_idempotent_retry?` is true (the default). A non-idempotent job gets one attempt.
- `JobCancelled` and `JobInterrupted` are the two sanctioned control-flow signals, raised by `check_halt_status!` when a worker is stopping or a cancellation was requested. Other jobs that want to stop early return. Only jobs that override `interruptible?` to true can be cancelled after they start.
- Errors bubble to Delayed Job and Sentry. Don't `rescue StandardError` and continue.
- `delayed_job:prune` (`lib/tasks/delayed_job.rake`) is invoked from deployment manifests in another repository; don't rename it or change its interface. It fails stale locked jobs by default instead of unlocking them, so non-idempotent work is not re-run silently.

## Nightly pipeline

`grda_warehouse:daily` runs `Importing::RunDailyImportsJob` inline (not through the queue), so its runtime does not show in `Delayed::Job`. It takes an advisory lock and exits if another run holds it, then waits up to four five-minute intervals while any importable data source is mid-import before starting.

Every phase runs inside `run_maintenance_task(name)`, so each is a named `SystemMaintenanceTask` with its own run history. The phases run in this order: ROIs, HMIS forms, CAS sync, duplicate identification, project and client cleanup, service history generation, name search, census, chronically homeless at entry, client history finalization, legacy reporting setup, HUD report pruning, system maintenance. Why the order matters for service history is in [Service History](service-history.md).

Things to know when changing it:

- `ClientRetentionJob` is queued between service history generation and name search. It must run after duplicate identification and client cleanup have finished rewriting `warehouse_clients`, and it does nothing when `client_retention_years` is unset.
- Several phases enqueue rather than run, guarded by `Delayed::Job.queued?('ClassName')` so a slow night doesn't double-queue. That helper matches the serialized handler text with `LIKE`, so a class name that is a substring of another matches both.
- The job is already long. Work that does not depend on service history ordering gets its own rake task and a `config/schedule.rb` entry, not a new phase. Don't add hour-gated blocks (`if DateTime.current.hour == N`) to `grda_warehouse:hourly`; it enqueues through `enqueue_unless_queued` so a backed-up queue doesn't stack copies.
- `grda_warehouse:monthly` runs client cleanup over every destination client to catch merges and splits without open enrollments.

## TaskQueue: run-once repairs

`TaskQueue` runs a registered lambda once per deployment and records that it ran. Use it for data repairs, backfills, one-time state migrations, and index builds. Don't use it for recurring work (it has no schedule), and don't write a migration that rewrites application data in Ruby; register a task so it runs on a worker with retry and error reporting.

- Core tasks are registered in `TaskQueue.register_tasks`; drivers add keys to `Rails.application.config.queued_tasks` from their feature initializers. Register from an initializer that runs in every process, because `grda_warehouse:hourly` reads the registry each hour.
- Each hourly pass enqueues any registered key that has no active row already queued, on the `long_running` queue.
- To re-run a task, insert a new `task_queues` row for the key with `queued_at` nil. Keys are not unique across rows for this reason.
- A worker on older code can pick up a key it does not know. It clears `queued_at` so a newer worker re-queues it. A row older than three days that never completed is marked inactive and reported to Sentry.
- Don't delete old entries from `register_tasks` casually. A deployment that has never run one still needs it.
- For an index on a large or heavily written table, don't use `algorithm: :concurrently` in a migration; it can fail to get its lock during a deploy. Add an idempotent `ensure_*_index!` class method (valid: no-op; invalid: drop and rebuild; missing: create) and call it from a task lambda. `ActivityLog.ensure_client_id_index!` is the model.

See also [App Config Property](app-config-property.md), [Metric Tracking](metric-tracking.md).
