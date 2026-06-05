# Data Sources

A **Data Source** (`GrdaWarehouse::DataSource`) represents a distinct origin of client and project data in the warehouse. Every HUD record (client, enrollment, project, etc.) belongs to exactly one data source via `data_source_id`.

The warehouse distinguishes three roles for data sources:

| Role | How it is identified | Purpose |
|------|----------------------|---------|
| **Source** | `source_type` is set, *or* `authoritative` is true | Holds imported or directly-entered HMIS data from an external or local system |
| **Destination** | `source_type` is null and `authoritative` is false | The merged warehouse view (typically one per deployment) used for deduplication and reporting |
| **Authoritative source** | `authoritative` is true | Data entered directly in the warehouse (or owned by a connected application); CSV imports are normally blocked |

Relevant scopes on `GrdaWarehouse::DataSource`:

- `source` — non-destination data sources
- `destination` — the warehouse destination
- `importable` — sources that accept HUD CSV imports (see [Import control](#import-control))
- `authoritative` — system-of-record sources
- `visible_in_window` — sources whose clients may appear in the Window into the Warehouse

Data sources are managed at `/data_sources` (requires `can_edit_data_sources` to create or edit). Access to clients and projects within a data source is controlled separately via Collections; see [warehouse-permissions.md](warehouse-permissions.md).

For Open Path HMIS installations specifically, see [multi-hmis-support.md](../architecture/multi-hmis-support.md).

## Field reference

The table below documents columns on the `data_sources` table. "Admin UI" indicates where administrators can change a value today.

| Field | Admin UI | Description |
|-------|----------|-------------|
| `id` | Read-only | Primary key. |
| `name` | Form | Full display name (e.g. agency or program name). Required. |
| `short_name` | Form | Short unique label (max 15 characters) shown in badges and compact UI. Required. |
| `source_type` | Form (hidden default `manual` on create) | How data is ingested. Common values: `manual`, `sftp`, `s3`, `samba`, or `authoritative` (set automatically when the authoritative checkbox is checked on create). Determines membership in `source` scope and, for `sftp`/`s3`/`samba`, eligibility for channel-specific automated import scopes. |
| `authoritative` | Form | When true, this data source is the system of record for its data. Normally excludes the source from `importable` (see exception below). Enables direct warehouse client creation via `available_for_new_clients`. Grants a direct client-visibility path in access control for users assigned to the data source. |
| `authoritative_type` | Form (when authoritative) | Sub-classification for authoritative sources. Values: `youth`, `vispdat`, `health`, `coordinated_assessment`, `other`, `synthetic`. Drives typed scopes (`.youth`, `.health`, etc.) used by features such as youth intake, health integrations, and VI-SPDAT reporting. |
| `source_id` | Form | Expected `SourceID` from `Export.csv`. On import, the loader compares this to the export file and rejects the import if they do not match (unless `source_id` is blank). |
| `import_paused` | Form | When true, skips automated S3 daily imports (`hmis_import_config`) and suppresses stalled-import detection. Shown only when the data source is importable. |
| `disable_imports` | Form | When true, excludes the data source from `importable` and hides HUD CSV upload/import UI. Blocks manual uploads and queued import jobs. |
| `munged_personal_id` | Form | When true, displays Personal IDs with UUID-style dashes (e.g. `5011A79B-04E3-4BB9-…`) when the stored value has none. Use when the source system stores UUIDs without dashes. |
| `after_create_path` | Form | Path segment appended after creating a client in an authoritative data source via the warehouse UI (e.g. redirect to a specific client tab). Blank redirects to the client dashboard. |
| `visible_in_window` | Form | When true, clients from this source may appear in the Window into the Warehouse for users who do not have the data source assigned directly. |
| `obey_consent` | Form | When true, source client details are exposed when a client has a consent (ROI) on file. When false, only users with direct data-source access can see source client details (subject to other access rules). |
| `service_scannable` | Form | When true, this authoritative data source is available in the service-scanning workflow for creating clients. |
| `hmis` | Form | Hostname of an Open Path HMIS installation. When present, `hmis?` is true and HMIS API requests for that host resolve to this data source. Must be chosen from available entries in `HMIS_HOSTNAME` env. Unique among active records. Requires `ENABLE_HMIS_API=true`. Can be assigned or changed on create and edit. |
| `import_aggregators` | Importer Extensions | JSON map of CSV file name → list of aggregator class names. Runs pre-import aggregation on staged data. Default `{}`. |
| `import_cleanups` | Importer Extensions | JSON map of CSV file name → list of cleanup class names. Runs post-load transformations during import. Default `{}`. |
| `file_path` | Not exposed | Legacy path segment for manual file drops (`manual_import_path`). Largely unused. |
| `last_imported_at` | Read-only | Timestamp of the last successful HUD CSV import; set by the importer. |
| `newest_updated_at` | Not exposed | Legacy column; not referenced by current application code. |
| `deleted_at` | Not exposed | Soft-delete timestamp (paranoia). Set when a data source is queued for removal. |

## Import control

Whether a data source accepts HUD CSV imports is determined by several overlapping mechanisms:

### `importable` scope and `importable?`

```ruby
scope :importable, -> do
  source.
    where(disable_imports: false).
    where(authoritative.eq(false).or(hmis.not_eq(nil)))
end

def importable?
  self.class.importable.where(id: id).exists?
end
```

A data source is **importable** when it is a source, `disable_imports` is false, and either:

- `authoritative` is false (typical imported vendor HMIS), **or**
- `hmis` is present (Open Path HMIS)

The `importable` scope gates:

- Manual upload access (`UploadsController` uses `importable.directly_viewable_by`)
- Upload and import buttons on the data source show page
- Several reporting and admin import lists

### `disable_imports` flag

When `disable_imports` is true, the data source is excluded from `importable` regardless of `authoritative` or `hmis`. Upload buttons, import configuration links, and `UploadsController#create` are blocked.

### `authoritative` flag

When `authoritative` is true and `hmis` is null, the data source is **not** in `importable` (unless `disable_imports` is the only blocker for sources that would otherwise import).

Authoritative sources with `hmis` set are importable when `disable_imports` is false.

### `import_paused` flag

When `import_paused` is true:

- Automated S3 imports (`Importers::HmisAutoMigrate::S3.available_connections`) skip this data source
- `stalled_date` returns nil (no stalled-import alert)

When `import_paused` is false, automated imports may run if `hmis_import_config` is configured and the data source is importable.

### Open Path HMIS form

When `ENABLE_HMIS_API=true` and the `:hmis` driver is loaded, the data source form includes an **Open Path HMIS hostname** dropdown. Options come from available entries in the `HMIS_HOSTNAME` environment variable (comma-separated). Hostnames already assigned to another data source are excluded; leave blank for a non-HMIS data source.

### `source_id` validation

During load, the importer reads `SourceID` from `Export.csv` and compares it to `data_source.source_id`. A mismatch fails the import.

## Source vs destination in practice

Most deployments have:

- **One destination** data source — the merged warehouse (`destination` scope)
- **One or more source** data sources — vendor HMIS exports, authoritative supplemental data (health, youth), or Open Path HMIS

HUD records retain their original `data_source_id` as source clients. The destination client is the deduplicated merge across sources, linked via `warehouse_clients`.

## Related configuration

These are not columns on `data_sources` but are configured from the data source show page:

| Configuration | Purpose |
|---------------|---------|
| `hmis_import_config` | Automated daily CSV fetch (S3/SFTP). Respects `import_paused`. |
| `import_threshold` | Pause or alert on import error / record-count thresholds. |
| `import_csv_monitors` | Per-CSV row-count monitoring. See [import-csv-monitoring.md](import-csv-monitoring.md). |
| `external_hmis_configuration` | Deep links from warehouse records to an external vendor HMIS UI. |
| Importer Extensions | UI for `import_aggregators` and `import_cleanups`. |
| Import Overrides | Per-field overrides during CSV import. |

For how imports process data once accepted, see [hmis-csv-importer.md](hmis-csv-importer.md).

## Common data source types

| Pattern | Typical settings | Data entry |
|---------|------------------|------------|
| Vendor HMIS (CSV import) | `authoritative: false`, `source_type: manual` or `sftp`/`s3` | HUD CSV upload or automated fetch |
| Authoritative supplemental (youth, health, VI-SPDAT) | `authoritative: true`, `authoritative_type` set | Direct entry in warehouse |
| Open Path HMIS | `authoritative: true`, `hmis` hostname set | HMIS application; CSV import optional during migration |
| Warehouse destination | `authoritative: false`, `source_type: null` | Populated by deduplication, not directly configured |

## See also

- [hmis-csv-importer.md](hmis-csv-importer.md) — import pipeline
- [multi-hmis-support.md](../architecture/multi-hmis-support.md) — Open Path HMIS hostname routing
- [warehouse-permissions.md](warehouse-permissions.md) — access control for data sources
- [import-csv-monitoring.md](import-csv-monitoring.md) — per-CSV import monitors
- `app/models/grda_warehouse/data_source.rb` — model, scopes, and behavior
