# External Data Sharing Exclusion

Agencies can mark individual clients to be excluded from exports. When a client is flagged, they are omitted from both the client and enrollment rows of every affected export.

The feature is toggled per-installation by the `:enable_external_data_sharing_exclusion` config flag.

## How It Works

### Setting the Flag

Staff with appropriate permissions set the exclusion flag on the client profile page. The flag is persisted to `GrdaWarehouse::ClientAttribute` via `ClientExternalDataSharing#set_exclusion!`. Both the setting user's id and a domain-level timestamp are stored alongside the flag.

The flag can also be set during **new client creation** — the clients controller checks a form param and calls the service if the box is checked.

### Flag States

The `external_data_sharing_exclusion_flag` column in `client_attributes` is a nullable boolean with three meaningful states:

| Value | Meaning |
|-------|---------|
| `nil` | Never explicitly set — client is not excluded |
| `true` | Client is excluded from external data sharing |
| `false` | Explicitly unchecked after a prior exclusion — not excluded |

A row may exist in `client_attributes` for reasons unrelated to the exclusion flag (the table holds future per-client attributes too). Code must guard on the flag value, not on row presence.

### Merge and Split Carry-Forward

When two destination clients are **merged**, the surviving client inherits the exclusion flag if either client was excluded (conservative carry-forward).

When a destination client is **split**, the new split-off destination inherits the exclusion status of the original.

Both operations go through `GrdaWarehouse::Hud::Client#merge_from` and `#split`, which call `ClientExternalDataSharing` directly.

### Auto-Embargo (New Clients)

In addition to the manual flag, any destination client whose warehouse record was created **within the last 7 days** is automatically withheld from affected exports (`embargoed_client_ids` in `Export::Scopes`). This gives staff a window to review and flag newly-imported clients before they appear in shared outputs.

## Affected Exports

The exclusion is applied through the `Export::Scopes` concern, which filters `client_scope` and `enrollment_scope`. Every exporter that includes `Export::Scopes` respects the flag.

| Exporter | HUD CSV version | Driver path |
|----------|----------------|-------------|
| `HmisCsvTwentyTwentySix::Exporter::Base` | 2026 | `drivers/hmis_csv_twenty_twenty_six/` |
| `HmisCsvTwentyTwentyFour::Exporter::Base` | 2024 | `drivers/hmis_csv_twenty_twenty_four/` |
| `HmisCsvTwentyTwentyTwo::Exporter::Base` | 2022 | `drivers/hmis_csv_twenty_twenty_two/` |

All three versions produce HUD-compliant HMIS CSV zip files (see [hmis-csv-export.md](hmis-csv-export.md)). Excluded clients and their enrollments are omitted from every file in the export — Client.csv, Enrollment.csv, Exit.csv, and all assessment/service records that join through the filtered enrollment scope.

## Key Files

| File | Role |
|------|------|
| `app/services/client_external_data_sharing.rb` | Service — reads and writes the exclusion flag |
| `app/models/grda_warehouse/client_attribute.rb` | Model — warehouse DB table holding the flag |
| `app/models/concerns/export/scopes.rb` | Concern — applies exclusion to exporter scopes |
| `app/controllers/clients/external_data_sharing_controller.rb` | Controller — `show` / `update` for the flag; requires `can_edit_clients` and loads the client through `destination_visible_to`, so a client outside the user's visibility returns 404 |
| `app/views/clients/external_data_sharing/show.haml` | View — form for editing the flag |
| `app/views/clients/_external_sharing_flag.haml` | Partial — badge shown on client profile |
| `db/warehouse/migrate/20260624000001_create_client_attributes.rb` | Migration — creates the `client_attributes` table |

## Enabling the Feature

Set the config flag in the admin Config UI or directly in the database:

```ruby
GrdaWarehouse::Config.first.update!(enable_external_data_sharing_exclusion: true)
```

When the flag is disabled, `Export::Scopes#external_data_sharing_restricted_destination_ids` returns `[]` immediately and the exclusion query is never run. The UI controls on the client profile are also hidden.
