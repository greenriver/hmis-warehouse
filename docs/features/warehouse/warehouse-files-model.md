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
