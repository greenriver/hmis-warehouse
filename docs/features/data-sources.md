# Data Sources

A **Data Source** (`GrdaWarehouse::DataSource`) represents a distinct origin of client and project data in the warehouse. Every HUD record (client, enrollment, project, etc.) belongs to exactly one data source via `data_source_id`.

Relevant scopes on `GrdaWarehouse::DataSource`:
- `destination` — the warehouse destination (typically there is only one)
- `source` — non-destination data sources (data may originate from an external vendor HMIS or OP HMIS)
- `importable` — sources that accept HUD CSV imports
- `hmis` – sources that are connected to an Open Path HMIS
- `authoritative` — system-of-record sources; encompasses OP HMIS sources and legacy sources where data is entered directly into the Warehouse
- `visible_in_window` — sources whose clients may appear in the Window into the Warehouse


## Source vs destination in practice

Most deployments have:

- **One destination** data source — the merged warehouse (`destination` scope)
- **One or more source** data sources — vendor HMIS exports, authoritative supplemental data (health, youth), or Open Path HMIS

HUD records retain their original `data_source_id` as source clients. The destination client is the deduplicated merge across sources, linked via `warehouse_clients`.

## Common data source types

| Pattern | Typical settings | Data entry |
|---------|------------------|------------|
| Warehouse destination | `authoritative: false`, `source_type: nil` | Populated by deduplication from other sources |
| Vendor HMIS (CSV import) | `authoritative: false`, `source_type: manual` or `sftp`/`s3` | HUD CSV upload or automated fetch |
| Open Path HMIS | `authoritative: true`, `hmis` hostname set | Data entered directly into HMIS application; may accept HUD CSV imports as well |
| Authoritative supplemental (youth, health, VI-SPDAT) | `authoritative: true`, `authoritative_type` set | Direct entry in warehouse. This is a legacy approach, plan to retire in favor of direct entry into OP HMIS. |


## Field reference

The table below documents columns on the `data_sources` table. "Admin UI" indicates where administrators can change a value today.

| Field | Admin UI | Description |
|-------|----------|-------------|
| `name` | Form | Full display name (e.g. agency or program name). Required. |
| `short_name` | Form | Short unique label (max 15 characters) shown in badges and compact UI. Required. |
| `hmis` | Form (when HMIS enabled) | Hostname of an Open Path HMIS installation. When present, `hmis?` is true and HMIS API requests for that host resolve to this data source. Must be chosen from available entries in the `HMIS_HOSTNAME` env (comma-separated). |
| `source_type` | Form (hidden default `manual` on create) | How data is ingested. Common values: `manual`, `sftp`, `s3`, `samba`, or `authoritative`. |
| `authoritative` | Form | When true, this data source is the system of record for its data. Normally excludes the source from `importable` unless `hmis` is set. Enables direct warehouse client creation via `available_for_new_clients`. Grants a direct client-visibility path in access control for users assigned to the data source. |
| `authoritative_type` | Form (when authoritative) | Sub-classification for authoritative sources. Values: `youth`, `vispdat`, `health`, `coordinated_assessment`, `other`, `synthetic`. Drives typed scopes (`.youth`, `.health`, etc.) used by features such as youth intake, health integrations, and VI-SPDAT reporting. Shown only when authoritative is checked and the source is not Open Path HMIS. |
| `source_id` | Form (Import settings) | Expected `SourceID` from `Export.csv`. On import, the loader compares this to the export file and rejects the import if they do not match. If blank, any `SourceID` in the export file is accepted. |
| `import_paused` | Form (Import settings) | When true, skips automated S3 daily imports (`hmis_import_config`) and suppresses stalled-import detection. Does **not** block manual HUD CSV uploads. |
| `disable_imports` | Form (Import settings) | When true, excludes the data source from `importable` and hides HUD CSV upload/import UI. Blocks manual uploads and queued import jobs. |
| `munged_personal_id` | Form | When true, displays Personal IDs with UUID-style dashes when the stored value has none. |
| `after_create_path` | Form | Path segment appended after creating a client in an authoritative data source via the warehouse UI. Only relevant for authoritative non-HMIS sources. |
| `visible_in_window` | Form | When true, clients from this source may appear in the Window into the Warehouse for users who do not have the data source assigned directly. |
| `obey_consent` | Form | When true, source client details are exposed when a client has a consent (ROI) on file. When false, only users with direct data-source access can see source client details (subject to other access rules). |
| `service_scannable` | Form | When true, this authoritative data source is available in the service-scanning workflow for creating clients. Only relevant for authoritative non-HMIS sources. |
| `import_aggregators` | Importer Extensions | JSON map of CSV file name → list of aggregator class names. Runs pre-import aggregation on staged data. Default `{}`. |
| `import_cleanups` | Importer Extensions | JSON map of CSV file name → list of cleanup class names. Runs post-load transformations during import. Default `{}`. |
| `file_path` | Not exposed | Legacy path segment for manual file drops (`manual_import_path`). Largely unused. |
| `last_imported_at` | Read-only | Timestamp of the last successful HUD CSV import; set by the importer. |
| `newest_updated_at` | Not exposed | Legacy column; not referenced by current application code. |
| `deleted_at` | Not exposed | Soft-delete timestamp (paranoia). Set when a data source is queued for removal. |

## See also

- [hmis-csv-importer.md](hmis-csv-importer.md) — import pipeline
- [multi-hmis-support.md](../architecture/multi-hmis-support.md) — Open Path HMIS hostname routing
- [warehouse-permissions.md](warehouse-permissions.md) — access control for data sources
- [import-csv-monitoring.md](import-csv-monitoring.md) — per-CSV import monitors
- `app/models/grda_warehouse/data_source.rb` — model, scopes, and behavior
