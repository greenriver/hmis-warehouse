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

`Hmis::File` inherits from `GrdaWarehouse::File`. All classes share the same `files` table.

## Storage Mechanisms

Three storage mechanisms exist across the codebase at different stages of migration.

### 1. Database (`content` bytea column)
Raw file bytes stored directly in the database row. Still actively written by:
- `GrdaWarehouse::PublicFile` — via `Admin::PublicFilesController#create`
- `GrdaWarehouse::ReportResultFile` — via LSA report generators (`fy2019`, `fy2021`)

### 2. CarrierWave (`file` varchar column)
`FileUploader` mounts on several subclasses and stores to `Rails.root/tmp/uploads/`. No subclass currently uses this as its primary read/write path for persistent files:
- `GrdaWarehouse::ClientFile` — mount declared but superseded by ActiveStorage
- `GrdaWarehouse::ReportResultFile` — mount declared but reads/writes use `content` column
- `GrdaWarehouse::DashboardExportFile` — mount declared; feature is unreachable (no controller)

### 3. ActiveStorage (`client_file` attachment)
Current target storage, configured via `Rails.application.config.active_storage.service`. Used by:
- `GrdaWarehouse::ClientFile`
- `Hmis::File`

Both include `ClientFileBase`, which declares `has_one_attached :client_file`.

## Migration State

`GrdaWarehouse::ClientFile` contains a `copy_to_s3!` method that migrates existing `content` bytea records to ActiveStorage. The `unprocessed_s3_migration` scope identifies unmigrated records.

The `active_storage_url` column caches S3 pre-signed URLs to avoid repeated API calls. It is cleared on save (via `before_save :clear_active_storage_url`) and repopulated by the `maintain_urls` class method.

`GrdaWarehouse::PublicFile` and `GrdaWarehouse::ReportResultFile` have not been migrated to ActiveStorage and continue to write to the `content` column.
