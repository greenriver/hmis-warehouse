---
sources:
  - app/models/grda_warehouse/data_source.rb
  - app/models/hmis_enforcement.rb
  - app/jobs/delete_item_job.rb
  - app/models/grda_warehouse/tasks/service_history/purge_for_deleted_data_sources.rb
  - app/models/grda_warehouse/custom_imports/import_file.rb
  - drivers/custom_imports_boston_service/app/models/custom_imports_boston_service/import_file.rb
  - app/models/eto_api/tasks/update_eto_data.rb
---

# Data Sources

A **Data Source** (`GrdaWarehouse::DataSource`) represents a distinct origin of client and project data in the warehouse. Every HUD record (client, enrollment, project, etc.) belongs to exactly one data source via `data_source_id`.

Relevant scopes on `GrdaWarehouse::DataSource`:
- `destination` — the warehouse destination; there is only one
- `source` — non-destination data sources (data may originate from an external vendor HMIS or OP HMIS)
- `importable` — sources that accept HUD CSV imports
- `hmis` – sources that are connected to an Open Path HMIS
- `authoritative` — system-of-record sources; encompasses OP HMIS sources and legacy sources where data is entered directly into the Warehouse
- `visible_in_window` — sources whose clients may appear in the Window into the Warehouse


## Source vs destination in practice

Installations have:

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
| `hmis` | Form (when HMIS enabled) | Hostname of an Open Path HMIS installation. When present, `hmis?` is true and HMIS API requests for that host resolve to this data source. Must be chosen from available entries in the `HMIS_HOSTNAME` env (comma-separated). Cannot be changed after it is set. |
| `source_type` | Form (hidden default `manual` on create) | How data is ingested. Common values: `manual`, `sftp`, `s3`, `samba`, or `authoritative`. |
| `authoritative` | Form | When true, this data source is the system of record for its data. Normally excludes the source from `importable` unless `hmis` is set. Enables direct warehouse client creation via `available_for_new_clients`. Grants a direct client-visibility path in access control for users assigned to the data source. |
| `authoritative_type` | Form (when authoritative) | Sub-classification for authoritative sources. Values: `youth`, `vispdat`, `health`, `coordinated_assessment`, `other`, `synthetic`. Drives typed scopes (`.youth`, `.health`, etc.) used by features such as youth intake, health integrations, and VI-SPDAT reporting. Shown only when authoritative is checked and the source is not Open Path HMIS. |
| `source_id` | Form (Import settings) | Expected `SourceID` from `Export.csv`. Manual uploads compare it before queuing and route a blank or differing value to a confirmation screen; the loader compares it again on import and rejects a mismatch unless the upload was confirmed. If blank, a manual upload still needs confirmation, and the loader accepts any `SourceID`. See [Manual Upload Source Check](hmis-csv-importer.md#manual-upload-source-check). |
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
- [multi-hmis-support.md](../hmis/multi-hmis-support.md) — Open Path HMIS hostname routing
- [warehouse-permissions.md](warehouse-permissions.md) — access control for data sources
- [import-csv-monitoring.md](import-csv-monitoring.md) — per-CSV import monitors
- [client-roi-and-consent.md](client-roi-and-consent.md) — how `obey_consent` and ROIs control client visibility
- `app/models/grda_warehouse/data_source.rb` — model, scopes, and behavior

## Gotchas

### Identity and caching
- A data source is the unit of identity scoping. `PersonalID`, `ProjectID`, and every other HUD id repeat across data sources, so always pair them with `data_source_id`.
- The data source id lists (source, destination, authoritative, window) are cached for an hour and cleared only on create. Changing `visible_in_window` also waits for the system-group maintenance before the window collection changes.

### Flags
- `obey_consent` off disables every ROI-based path for that source's clients, including supplemental data sets, even when the destination client has a valid ROI.
- `hmis` cannot be changed once set, and every validation of an HMIS data source silently rewrites `authoritative`, `authoritative_type`, `source_type`, `munged_personal_id`, `after_create_path`, and `service_scannable`.
- `HmisEnforcement.hmis_enabled?` is an environment variable (`ENABLE_HMIS_API`), not a data source property. A deployment can hold data sources with `hmis` set while HMIS is off. Gate HMIS behavior on `hmis_enabled?` combined with `hmis?`, not on `hmis?` alone.
- `hmis_go_live_at` blocks everyone but HMIS administrators until it passes.
- `health_authoritative_id` matches `short_name == 'Health'`, not `authoritative_type: 'health'`.
- A per-source `client_retention_years` overrides the global setting only when global retention is on. See [client-data-retention.md](client-data-retention.md).
- Legacy window and `AccessGroup`-based readers are marked for removal after the ACL migration. New code uses `viewable_by` with an explicit `permission:`.

### Non-CSV data
- **ETO API.** `UpdateEtoData#run!` checks the `eto_api_available` config, but the scheduled jobs call the update methods directly and skip that check. To disable ETO, deactivate the `EtoApiConfig` rows or unschedule the rake task. Fetched rows are compared by date only. Consent coming through ETO is stored on `HmisClient` and reconciled, never written to the client by an importer.
- **Eccovia.** Fetches run only as the last step of the ETO rake task and iterate every `EccoviaData::Fetch`, ignoring its `active` column.
- **Manual project data.** Funders, inventories, and project CoCs entered through the manual HMIS data driver carry `manual_entry: true`. The importer's `importable` scope excludes them; a row created without the flag would be treated as import-owned and soft-deleted on the next HUD CSV import.
- **Custom S3 imports.** A new import type is a `drivers/custom_imports_<name>` driver that registers its `ImportFile` subclass in `Rails.application.config.custom_imports`. `check_hour` is always true in development and test. The importer takes the last key in the S3 listing, so it re-imports the same newest file every day. The Boston service import deletes and re-creates services for the file's reporting period, so a partial file removes services it does not contain.

### Deleting a data source
Deletion is asynchronous and soft. Use `DeleteItemJob` (not `destroy` from a console or controller) so dependents are cleaned up. Organizations are marked deleted without callbacks or paper trail. Service history is not touched by the job; the nightly `PurgeForDeletedDataSources` removes it for data sources deleted at least 24 hours earlier, so rows for a data source deleted today are purged the following night.
