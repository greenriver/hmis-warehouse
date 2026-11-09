# Project Groups

A project group is a named, maintained list of warehouse projects. Administrators build groups such as "HUD Funded Projects" or "Downtown Shelters" and reuse them across the warehouse: report filters, auto-maintained cohorts, the CAS sync, the Project Data Quality report, and project access grants.

This doc covers the warehouse `GrdaWarehouse::ProjectGroup`. HMIS has its own `Hmis::ProjectGroup`, which isn't covered here.

## Key Concepts

- **Options:** A group stores its definition in `options`, a serialized filter. The options can include projects picked by name, organizations, data sources, and project types. These choices add together: picking one project and the ES project type gives every emergency shelter plus that project. Excluded projects and excluded project types are removed afterward.
- **Membership:** The group's projects are stored in the `project_project_groups` join table, rebuilt from the options by `ProjectGroup#maintain_projects!`.
- **Maintenance:** `ProjectGroup#maintain_projects!` runs when a group is saved through the project group form. The hourly `MaintainProjectGroupListsJob` calls `ProjectGroup.maintain_project_lists!`, which rebuilds every group so that new projects that match a group's options are added.
- **Import:** `ProjectGroup.import_csv` creates or replaces groups from a CSV or Excel file of `ProjectGroupName`, `ProjectName`, `ProjectID`, and `data_source_id`. Imported projects replace the group's projects picked by name.

## How Membership Is Resolved

`ProjectGroup#filter` builds a `Filters::SystemProjectHudFilter` from the options. `SystemProjectHudFilter` resolves the options against every project, so who edits a group doesn't change how its options resolve, and resolution doesn't depend on the system user's access being current. The only rule is about confidential projects (a project is confidential when it or its organization has `confidential` set):

- Projects picked by name are added, including confidential ones.
- Organization, data source, and project type selections leave confidential projects out.

The project group form tells editors this: confidential projects must be added individually.

The form's project picker shows only projects the editor can see, so saving the form drops picks the editor can't see. The form warns about this.

## Using a Group

### In reports

A project group narrows which projects a report covers. It doesn't grant access to them. A report run on a group includes only the group's projects the user can already report on, and `Project.viewable_by` leaves confidential projects out unless the user has `can_report_on_confidential_projects`.

This lets an administrator build one group and assign it to users in different organizations or CoCs, each of whom gets their own slice of the group. If seeing a group widened a report to all of its projects, assigning a group would grant project access, which is not what groups are for. Report filters apply this narrowing, so code that runs a report for a group should leave it to them rather than add back projects the user can't see.

The Project Data Quality report is an exception: it keeps one report per group, shared by everyone who can see the group, so it covers all of the group's projects.

### In auto-maintained cohorts

An auto-maintained cohort adds the clients enrolled in its project group's projects (see [Cohorts](./cohorts.md)). `Cohort#maintain` runs with `Filters::SystemProjectFilter`, which resolves the group against every project, so the automation includes enrollments in every project in the group, including confidential ones.

Clients enrolled in a confidential project that was picked into the group are added to the cohort. Anyone who can see the cohort sees those clients, whether or not they can report on the project. An editor who picks a confidential project into a group decides that its clients belong in any cohort maintained from that group. Picking an organization never pulls in its confidential projects.

### In the CAS sync

When `cas_available_method` is `project_group`, `boston`, or `active_clients`, the group set in `cas_sync_project_group_id` limits which projects count toward syncing a client to CAS (see [CAS Sync: Active Clients](./cas-sync-active-clients.md)). A group used for the CAS sync or by a cohort can't be deleted (`ProjectGroup#available_for_delete?`).

## Access

There are two kinds of access to a group, and the admin UI labels both "Project Groups", so the collection type is what tells them apart:

- **Seeing the group:** Adding a group to a Project Groups collection lets users see and pick the group in reports (`ProjectGroup.viewable_by`). It grants no project access.
- **Access to the group's projects:** Adding a group to a Projects collection (`ProjectAccessGroup`) grants access to its projects the same as listing each project, including confidential projects picked into the group. Reports still leave confidential projects out unless the user can report on them.

Editing groups needs `can_edit_project_groups`, or `can_edit_assigned_project_groups` for groups the user is an editor of (`ProjectGroup.editable_by`). Importing needs `can_import_project_groups`.

See [Warehouse Auth Policies](./warehouse-auth-policies.md) and [Warehouse Permissions](./warehouse-permissions.md) for the wider access model.

## Related Code

- **Model:** `app/models/grda_warehouse/project_group.rb`
- **Project access grant:** `app/models/grda_warehouse/project_access_group.rb`
- **Membership filter:** `app/models/filters/system_project_hud_filter.rb`
- **Cohort automation filter:** `app/models/filters/system_project_filter.rb`
- **Controller and form:** `app/controllers/project_groups_controller.rb`, `app/views/project_groups/_form.haml`
- **Hourly maintenance:** `app/jobs/maintain_project_group_lists_job.rb`
- **Report filter narrowing:** `Filters::FilterBase#effective_project_ids_from_project_groups`
