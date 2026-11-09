---
sources:
  - app/models/concerns/cas_client_data.rb
  - app/models/grda_warehouse/tasks/push_clients_to_cas.rb
  - app/models/cas_base.rb
  - app/controllers/warehouse_reports/manage_cas_flags_controller.rb
---

# CAS Sync: Active Clients with Optional Project Group

## Overview

The "Active clients within range" CAS sync method determines which clients are considered active for CAS based on service history in a configurable date range. Which projects count toward "active" can be controlled in two ways: by default (all homeless + CE + override projects) or by selecting a project group.

## How It Works

### Project Selection

The system uses `active_clients_project_ids_for_cas_sync` (in `CasClientData`) to get the set of project IDs whose enrollments count as active. Two modes:

**1. No project group selected** (`cas_sync_project_group_id` blank)

- Includes all homeless project types (ES, SO, TH, etc.)
- Includes CE (project type 14)
- Includes projects with `active_homeless_status_override` (Project → Edit → "Consider enrolled clients as actively homeless for CAS and Cohorts?")

**2. Project group selected**

- Uses only that project group's `effective_project_ids` (projects in the group after applying any exclusions)
- `active_homeless_status_override` projects are **not** auto-included; add them to the project group explicitly if needed

### Active Client Criteria

A client is active for CAS when they have at least one enrollment with service in the configured date range (`cas_sync_months`) at a project in the selected set. Service may be extrapolated or actual, depending on `ineligible_uses_extrapolated_days`.

### Project Group Exclusions

Project groups can exclude specific projects or project types. Excluded projects are removed from `effective_project_ids`. Clients whose only qualifying enrollment is in an excluded project will not sync to CAS.

## Configuration

- **Admin → Config → CAS**: "Project Group to sync" (optional for Active clients within range; required for Project group and Boston methods)
- **Project → Edit**: "Consider enrolled clients as actively homeless for CAS and Cohorts?" (`active_homeless_status_override`)

## Related Code

- `app/models/concerns/cas_client_data.rb`: `active_clients_project_ids_for_cas_sync`, `cas_active` scope, `active_in_cas?`
- `app/models/grda_warehouse/config.rb`: `cas_sync_project_group`, `cas_sync_project_group_id`
- `app/views/admin/configs/_cas.haml`: Project group selection UI

## Sync mechanics and gotchas

### Which clients are pushed
- Every `cas_available_method` except `cas_flag` is OR'd with the manual `sync_with_cas` flag, so the checkbox always adds a client.
- `cas_active` (who is pushed) and `active_in_cas?` (the `sync_with_cas` value in the payload) are parallel implementations. A new availability method must be added to both and to `GrdaWarehouse::Config.available_cas_methods`. `active_in_cas?` also excludes deceased clients and clients moved in with PH, which the scope does not, so a client can be pushed yet marked unavailable.
- The sync first sets `sync_with_cas: false` on every CAS `project_clients` row, then re-pushes. A client who drops out of the active set becomes unavailable in CAS on the next run even if no warehouse row changed.
- Columns pushed come from the CAS schema. A column added in CAS but missing from the warehouse column map is pushed as nil.
- A new payload column in `cas_columns_data` that is not also in `ignored_for_batch_maintenance` shows up as a bulk-editable flag in the manage CAS flags report.
- A manually flagged client housed through CAS can be made available again before the warehouse learns of the housing (see the note in `RunDailyImportsJob#sync_with_cas`).

### Release status in the payload
- `release_status_for_cas` sends `'None on file'` when no release is recorded, `'Expired'` when the release duration is time-limited and consent is not both valid and confirmed, and otherwise the installation's translated release label.
- It reads the destination client's consent columns, not `ClientRoiAuthorization`.
- Assessment contact details are omitted from the payload when consent is not valid.
- The bulk-flag report never clears the full or limited housing release flags; clearing a release is a consent decision, not a CAS flag.

### The CAS connection
- `CasBase` is chosen at class-load time from `DATABASE_CAS_DB`. With it unset, every `CasAccess::*` call returns nil (not an empty relation), and stubbing `CasBase.db_exists?` in a spec does not make `CasAccess` models real.
- Check `GrdaWarehouse::Config.cas_enabled?` before assuming a CAS result; do not gate UI on the env var.
- The connection is writable, but by convention only `PushClientsToCas` writes through it. CAS owns its schema; needs to change CAS state go to the CAS application.
- Run the sync through `Cas::SyncToCasJob`, not inline in a controller. The task holds an advisory lock and iterates every active client.

### Cohorts and confidentiality
- Cohort membership is sent to CAS only for cohorts flagged `visible_in_cas`, so confidential cohorts do not leak.

### CE data coming back
- The `cas_ce_data` driver turns CAS assessments and referral events into synthetic HUD CE records. It only runs when the CAS database exists, even though its source tables are on the warehouse connection.
- Each record attaches to the client's open, CoC-funded, CE-participating enrollment on the assessment date (within 90 days before the referral date for events).
