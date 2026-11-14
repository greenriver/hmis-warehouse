---
sources:
  - app/models/concerns/has_pii_attributes.rb
  - app/models/concerns/pii_display.rb
  - app/models/grda_warehouse/hidden_clients.rb
  - app/controllers/concerns/activity_logger.rb
  - app/models/activity_log.rb
  - app/models/grda_warehouse/tasks/scrub_pii/scrub_all_pii_task.rb
  - app/models/pii/scrubber/scrub_model_pii.rb
  - app/models/pii/scrubber/static_scrubber.rb
---

# PII Cataloging, Access Logging, and Scrubbing

How the warehouse catalogs client PII, records who viewed which client, and scrubs PII for non-production copies. Who may see PII, how restriction hides a client, and search and export exclusion are in [Warehouse Auth Policies](warehouse-auth-policies.md#pii-redaction). Aging out inactive clients is in [Client Data Retention](client-data-retention.md).

## Restriction sources

A client is hidden in the warehouse when it is restricted in HMIS, restricted in the warehouse (`DestinationClientRestriction`), or retention-inactive. `GrdaWarehouse::HiddenClients` is the single definition of the restricted and inactive sets, and everything that hides clients (policy loader, search, report drilldowns, CSV export transform, `analytics.client_piis`) reads it or repeats it in SQL.

- The restricted set is the directly restricted ids, the destinations linked to them through live `WarehouseClient` rows, and every sibling source of those destinations. It is one hop only, so a row that is both a source and a destination does not pull in its grandparent.
- The inactive set is the marked source ids plus their live destinations. It does not include unmarked sibling sources; the job marks every live source of an identity, so a sibling stays unmarked only until the next run after a merge.
- `analytics.client_piis` repeats both sets in SQL and must be kept in step with `HiddenClients`.
- Building a hidden-id list in Ruby and passing it to `where.not(id:)` does not scale. Use `HiddenClients.not_hidden(column)` in the query, or `client_restricted?` after a preload. Checking a list without a preload runs one query per client, and past the miss threshold raises `PreloadMissError` in development and test.
- Hiding covers name and SSN matches only. Do not extend it to DOB or id lookups.

## Cataloging PII

`pii_attr` (from `HasPiiAttributes`) records which columns hold PII, of what type, and at what level. Levels run from 1 (direct identifiers: names, SSN) through 2 (DOB, email, phone, street, postal code), 3 (age, locality, administrative area) to 4 (free text, URLs, attached files, JSON).

- The catalog is used by the scrubbers only. Display decisions (`PiiProvider`, `PiiDisplay`) work from method names and column labels, so a column declared with `pii_attr` is protected in scrubs but not automatically redacted on screen.
- Subclasses deep-copy the parent's config when defined, so a `pii_attr` added to a parent afterward is not seen by existing subclasses.
- A new column holding name, SSN, DOB, contact, or address data needs a `pii_attr` declaration, or the scrub tasks will not see it.
- `PiiDisplay#pii_value` dispatches on the lowercased column label, and any label ending in `name` is treated as a client name. A column such as `project_name` or `Organization Name` is redacted when the policy denies client names.

## Access logging

- One `ActivityLog` row is written per warehouse request, except `poll`, `active`, `rollup`, and `image`, so a client dashboard visit produces one row, not one per lazily loaded section. Controllers attach the viewed client with `log_client`. The log records the real user when impersonating.
- Activity logs are not id-only. `path` is the full request path with query string and `title` for a client page is the client's name as the logging user saw it. They are a secondary PII store. Titles are stored at visit time, so a page that renders `title` must go through `ActivityLog#display_title` with the client's current restriction. Do not add PII to the log beyond what the default title stores; log identifiers and resolve names at render time.
- `reporting_path` is a 200-character copy of `path`, kept because `path` is unbounded and cannot be indexed. `client_id` is derived from the first `/clients/<id>` path segment before any query string, so `/source_clients/<id>` and `?return_to=/clients/<id>` do not match.
- The User Access Logs reports read the log tables with no join to users or access controls. Users whose grants were revoked, or who were deleted, still appear. That is the audit intent. Report Usage and User Access Summary results are cached for 15 minutes.
- The Excel export has one sheet each for the warehouse, CAS, and (when HMIS is enabled) HMIS, capped at the spreadsheet row limit per sheet.
- The HMIS side has its own activity log, written by the GraphQL controller and the client files controller, and processed later into per-client and per-enrollment tables.

## Scrubbing for non-production copies

`ScrubClientPiiTask` and `ScrubAllPiiTask` overwrite cataloged PII and delete related free-text records. They are console-only: nothing schedules them or exposes them in the UI. `ScrubAllPiiTask` is the tool for turning a production copy into a staging database.

- Level 1 and 2 fields are overwritten with nil, or a placeholder when the column is required. A DOB moves to a random date in the same five-year age bracket. Level 3 and 4 fields (free text, attached files, JSON, locality) are cataloged but not overwritten.
- `ScrubClientPiiTask` also deletes custom data elements whose label looks like PII, files, custom names, addresses, contact points, and case notes for the client, and prunes version history. Deletion is `delete_all`, bypassing soft delete and callbacks.
- Both tasks take a zero-timeout advisory lock, so a concurrent run fails immediately.
- Scrubbing acts on the live database only. Backups and S3 copies are untouched.
- `ScrubAllPiiTask` uses a hand-maintained list of models, not the catalog. A new snapshot table with PII needs both a `pii_attr` declaration and an entry in that list. Several models that declare PII are currently missing from it, including newer SPM enrollment tables and the newest HMIS CSV loader and importer tables.
- The `:static` custom scrubber raises because it omits a required argument. Use `:fake` or no custom scrubber.

## Other gotchas

- Warehouse client search stores the typed criteria (name, SSN, DOB) in `ClientSearchQuery` rows under a UUID. Those rows hold PII until a scheduled cleanup task deletes them after two years.
- `ClientRetentionLogEntry` and `ClientRetentionExpiringClient` must hold identifiers only, never name, SSN, or DOB.
- Do not implement retention by deleting or nulling client rows. Extend `ClientRetentionJob` and `HiddenClients` instead.
