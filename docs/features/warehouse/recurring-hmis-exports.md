---
sources:
  - app/models/grda_warehouse/recurring_hmis_export.rb
  - app/models/grda_warehouse/tasks/process_recurring_hmis_exports.rb
  - app/jobs/export_base_job.rb
  - app/services/zip_cloak.rb
  - app/services/seven_zip.rb
  - config/schedule.rb
---

# Recurring HMIS Exports

This feature automates the delivery of HMIS CSV exports on a rolling schedule. It is designed for automated data exchange via S3.

## User Flow
- Navigate to `Warehouse Reports → HMIS Exports` and configure the export filter as usual.
- Expand **Recurring export options** to specify the cadence (`every_n_days`) and optional delivery settings.
- Submitting the form creates a `GrdaWarehouse::RecurringHmisExport` record and schedules the initial export job.
- Each completed run stores a `GrdaWarehouse::HmisExport` and links it back to the recurring definition via `GrdaWarehouse::RecurringHmisExportLink`.

## Scheduling Model
- `every_n_days` controls the cadence. Runs skip the day the recurrence is created to avoid duplicate output.
- A run is due when the last successful export finished at least `every_n_days` ago; otherwise the system waits.
- A definition that has never run waits until the day after it was last saved, so editing a never-run definition pushes its first run to the next day. Editing one that has run does not change its schedule.
- Scheduled runs pass no report URL, so no completion email is sent.
- Reporting ranges are recalculated before each run using the saved filter options (fixed dates, rolling days, prior month, prior year).

## Storage and Delivery
- Each export produces an ActiveStorage-backed zip file (see [HMIS CSV Export](./hmis-csv-export.md#archive-and-storage)).
- When S3 credentials are provided (`s3_region` + `s3_bucket`, optionally access keys) the system uploads the encrypted artifact using `GrdaWarehouse::RecurringHmisExport#store`.
- Supported encryption options:
  - `nil`: deliver the raw zip created by the export job.
  - `zip`: re-wrap the archive using `zipcloak` with the supplied `zip_password`.
  - `7z`: expands the zip and rebuilds it as a `.7z` archive protected by the password.
- Only the S3 copy is encrypted. The stored `GrdaWarehouse::HmisExport` keeps the unencrypted zip, and in-app downloads still work if the S3 step fails.
- `zip` and `7z` need their binaries on the worker image. Without them the S3 upload fails or is empty.
- `zipcloak` reads the password from a pseudo-terminal, so the model rejects passwords over 80 characters or containing control characters at save time rather than mid-export. A password and an encryption type must be given together.
- `zipcloak` will not take a password longer than 80 characters, so `zip_password` is length-validated for the `zip` type and the user sees the error on the form. The `7z` type has no such limit.

## Background Processing
- The rake task `grda_warehouse:process_recurring_hmis_exports` iterates all recurrence definitions and calls `run` for those that return `should_run?`.
- In production this task should execute on a schedule (cron, Delayed Job recurring task, or equivalent). Without it, no follow-up runs occur.
- Each `run` rebuilds the `Filters::HmisExport` object from the stored options, adjusts reporting periods, and queues the export job via `schedule_job`.

## Operations and Monitoring
- Verify that the Delayed Job queue responsible for exports is active; recurring runs rely on the same queues as manual exports.
- Watch for `Invalid S3 Configuration` flashes when users submit the form. Invalid credentials block scheduling until corrected.
- For S3 uploads, ensure `ENV['ENCRYPTION_KEY']` is configured to support the encrypted credential fields.
- Use the HMIS Exports index to edit or cancel recurring definitions; cancellations delete the `RecurringHmisExport` record.

## Related Code
- Controller: `app/controllers/warehouse_reports/hmis_exports_controller.rb`
- Model: `app/models/grda_warehouse/recurring_hmis_export.rb`
- Task runner: `app/models/grda_warehouse/tasks/process_recurring_hmis_exports.rb`
- Zip encryption: `app/services/zip_cloak.rb`
