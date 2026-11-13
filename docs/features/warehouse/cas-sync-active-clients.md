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
