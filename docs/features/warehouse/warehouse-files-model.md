---
sources:
  - app/models/grda_warehouse/file.rb
  - app/models/grda_warehouse/client_file.rb
  - app/models/concerns/client_file_base.rb
  - app/models/grda_warehouse/available_file_tag.rb
  - app/models/grda_warehouse/secure_file.rb
  - app/jobs/purge_soft_deleted_client_files_job.rb
  - app/models/soft_delete_retention_configuration.rb
  - app/controllers/clients/files_controller.rb
---

# Files Table

The `files` table is a single-table inheritance (STI) model. The `type` column determines the subclass. It is used for client-associated documents (consent/ROI forms, housing release forms, headshot images, homeless history verifications, CE certifications, enrollment attachments) and some report output files. Other file storage mechanisms exist in the application (e.g. `GrdaWarehouse::DocumentExport`, `GrdaWarehouse::HmisExport`) and are not covered here.

## Class Hierarchy

| Class | Used by |
|---|---|
| `GrdaWarehouse::ClientFile` | Warehouse client document uploads |
| `Hmis::File` | HMIS front-end client document uploads |
| `GrdaWarehouse::ReportResultFile` | LSA report zip output |
| `GrdaWarehouse::PublicFile` | Admin-managed document templates and forms |
| `GrdaWarehouse::DashboardExportFile` | Unused (controller is missing) |
| `TxClientReports::ResearchExports::Export` | TX client reports research export output |

`Hmis::File` inherits from `GrdaWarehouse::File`. All classes share the same `files` table.

## Storage Mechanisms

Two storage mechanisms exist across the codebase. (CarrierWave was a third, legacy
mechanism — it has been fully removed.)

### 1. Database (`content` bytea column)
Raw file bytes stored directly in the database row. No longer actively written by any
current code path — `Admin::PublicFilesController#create` and the LSA report generators
that used to populate `GrdaWarehouse::ReportResultFile` both write via ActiveStorage now
— but historical rows still exist and are read via each class's `file_data` fallback
method.

### 2. ActiveStorage
Current and only storage mechanism for new files, configured via
`Rails.application.config.active_storage.service`. Every subclass in the table above
declares its own `has_one_attached` attachment:

| Class | Attachment |
|---|---|
| `GrdaWarehouse::ClientFile` | `client_file` (via `ClientFileBase`) |
| `Hmis::File` | `client_file` (via `ClientFileBase`) |
| `GrdaWarehouse::PublicFile` | `public_file` |
| `GrdaWarehouse::DashboardExportFile` | `dashboard_export_file` |
| `GrdaWarehouse::ReportResultFile` | `report_result_file` |
| `TxClientReports::ResearchExports::Export` | `research_export_file` |

`has_one_attached` (and `has_many_attached`) shows up throughout the rest of the app too —
e.g. `GrdaWarehouse::HmisExport`, `GrdaWarehouse::NonHmisUpload`, `GrdaWarehouse::AdHocBatch`,
`GrdaWarehouse::SecureFile`, `GrdaWarehouse::Upload`, `GrdaWarehouse::Theme`, and the HUD
report archival CSVs. Those models aren't part of the `files` table and are out of scope
for this doc, but `client_file` above is one attachment among many, not a special case.

`ClientFile#active_storage_url` caches the blob URL for external analytics. It is cleared on save only when the service is `:amazon` or `:local_s3`, and `ClientFile.maintain_urls` back-fills it.

## Tags drive behavior

Behavior on a `ClientFile` comes from its tags. Tags match rows in `GrdaWarehouse::AvailableFileTag`, and the boolean flags on that row decide what uploading the file does: consent form (writes consent onto the client; see [Client ROI and Consent](client-roi-and-consent.md)), verified homeless history, notification trigger, document ready, CE self-report certification, and required effective or expiration dates. `included_info` powers lookups such as verification of disability, which feeds the CAS `disability_verified_on` sync.

- Use the `AvailableFileTag` flag scopes (`verified_homeless_history`, `consent_forms`, `tag_includes(...)`) or `ClientFileBase.headshot_tag_name` rather than hard-coding tag names in code. A few legacy call sites still do.
- Taggings are stored with the STI base class name (`GrdaWarehouse::File`) as `taggable_type`, so direct `Tagging` queries must filter on the base class.
- The consent, verified-homeless-history, and CE-certification scopes resolve `Tagging` ids directly and cache them for two minutes, because `tagged_with` misbehaves in tests. A tag-flag change is not reflected until the cache expires.
- `ClientFile#callbacks_skipped = true` disables the notification and consent callbacks. A bulk writer that sets it leaves the client's consent columns and ROI row stale.

## Visibility

`ClientFile.visible_by?(user, client:)` is the single visibility scope for warehouse files; every `Clients::FilesController` scope starts from it. Users who manage client files see everything; window-file managers see files of clients with a full housing release that are marked visible in the window; users with only the own-uploads permissions (including `can_use_separated_consent`) see only their own uploads. Verified homeless histories and consent forms can be opened to all by `GrdaWarehouse::Config`.

`confidential` files are a separate axis. `visible_by?` does not filter on `confidential`; the index view uses `confidential_visible_by` to decide what to show, and any new endpoint that serves file bytes must apply it itself. A confidential file needs either a data source or an enrollment. `Hmis::File` has no such rule: its `data_source_id` is a plain accessor.

`can_use_separated_consent` alone lets a user update their own releases but not delete them.

## Size limits and content checks

Both `ClientFileBase` and `GrdaWarehouse::ClientFile` enforce 100 bytes to 12 MB. Content checks are size and type only: `PublicFile` checks the content type ActiveStorage detected from the bytes against an allow-list. There is no virus scanning.

## Soft delete and purge

Client files are soft-deleted. `has_one_attached :client_file, dependent: false` stops `acts_as_paranoid` from enqueuing a blob purge, and `soft_delete!` updates `deleted_at` without running `destroy` callbacks, which would let `acts_as_taggable` hard-delete the taggings and make restore impossible. Never `destroy` a `ClientFile` or `Hmis::File`. The files controller, not the model, invalidates consent and rebuilds the client's ROI authorization when the active consent form is deleted; a new deletion path must do both (see [Client ROI and Consent](client-roi-and-consent.md)).

`PurgeSoftDeletedClientFilesJob` later purges blobs and hard-deletes rows older than the retention period (`AppConfigProperty` keys `purge_soft_deleted_records/enabled`, `retention_period_days`, default 365, and `max_deleted_per_run`). Purging is enabled by default only in staging. Elsewhere the job runs and completes its maintenance-task record but purges nothing, so soft-deleted files and blobs persist indefinitely.

`ClientImageConsumer` caches headshots as `Client Headshot Cache` files and replaces them with `really_destroy!`, not `soft_delete!`; they are not user documents and are excluded from file notifications.

`Admin::PublicFilesController#destroy` calls `destroy`, not `soft_delete!`, so a public file's taggings are hard-deleted.

## Other file-like models

- `GrdaWarehouse::PublicFile` rows are blank forms linked from the files tab. `url_for_location` matches `name` exactly, so an admin must upload with the literal key (for example `client/hmis_consent`) or the link silently disappears.
- `GrdaWarehouse::SecureFile` is user-to-user transfer in its own table, with a one-month expiry. Visibility follows the role, not ownership: losing `can_view_assigned_secure_uploads` hides a user's own past uploads. `expired` and `unexpired` use slightly different cutoffs (date versus timestamp), so a row created on the boundary day matches neither. The developer upload rake task refuses recipients outside the organization's email domain, except in development.
- New client-document storage should be a `GrdaWarehouse::File` subclass with `has_one_attached ..., dependent: false` and a `file_data` fallback for legacy bytes, as `ReportResultFile` does.
- Async report downloads use a separate table; see [Document Export](document-export.md).

## Gotchas

- `ClientFile.maintain_urls` (back-fills the cached blob URL for external analytics) re-raises blob errors outside development, so one missing S3 object fails the whole batch.
- `Clients::FilesController#create` rescues `StandardError` and re-renders `new` with no flash, so an unexpected exception inside the block is swallowed. It predates the no-bare-rescue convention.
