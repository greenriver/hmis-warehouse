---
sources:
  - drivers/hmis/lib/hmis_util/form_transfer/importer.rb
  - drivers/hmis/lib/hmis_util/form_transfer/form_importer.rb
  - drivers/hmis/lib/hmis_util/form_transfer/project_importer.rb
  - drivers/hmis/lib/hmis_util/form_transfer/project_config_importer.rb
  - drivers/hmis/lib/hmis_util/form_transfer/ce_importer.rb
  - drivers/hmis/lib/hmis_util/form_transfer/hud_key_resolver.rb
  - drivers/hmis/lib/hmis_util/form_transfer/exporter.rb
  - drivers/hmis/lib/hmis_util/form_transfer/form_exporter.rb
  - drivers/hmis/lib/hmis_util/form_transfer/project_exporter.rb
  - drivers/hmis/lib/hmis_util/form_transfer/project_config_exporter.rb
  - drivers/hmis/lib/hmis_util/form_transfer/ce_exporter.rb
  - drivers/hmis/lib/tasks/form_transfer.rake
---

# HMIS form transfer

`HmisUtil::FormTransfer` copies form definitions, and the configuration they depend on, from one installation to another as a JSON file. It exists so engineers can reproduce a staging or production form setup in development, where forms can be inspected, copied, and changed without going back to the source installation. It copies configuration and the projects that configuration points at. It never copies client data.

## Running it

```bash
# On the source installation
rails driver:hmis:form_transfer:export[tmp/hmis_forms.json]

# Locally, after copying the file over
DRY_RUN=true rails driver:hmis:form_transfer:import[tmp/hmis_forms.json]
rails driver:hmis:form_transfer:import[tmp/hmis_forms.json]
```

| Variable | Task | Effect |
|---|---|---|
| `IDENTIFIERS`, `ROLES` | export | Comma-separated form identifiers or roles to export. All forms when unset. |
| `PROJECT_IDS` | export | HUD ProjectIDs to export even when nothing references them. |
| `INCLUDE_PROJECTS=false`, `INCLUDE_CE=false` | export | Leave out projects and organizations, or Coordinated Entry configuration. |
| `DRY_RUN=true` | import | Run every save and callback, then roll back. |
| `CONFIRM_IMPORT_INTO` | import | Required outside development and test. Must equal the Rails environment name. |
| `DATA_SOURCE_ID` | both | Needed when the installation has more than one HMIS data source. Must be an HMIS data source. |

Outside development and test, the import refuses to run, dry run included, unless `CONFIRM_IMPORT_INTO` names the current environment. The error message doesn't print the expected value, so the name has to be typed rather than pasted.

## What the file contains

- Every version of the selected form definitions, plus the forms used by the exported workflow templates' steps, since a template can't be imported without them.
- The CDEDs those forms use. Older CDEDs may have no `form_definition_identifier`, so the exporter also walks each version's `custom_field_key` mappings and warns about mappings with no CDED.
- Active, non-system form rules (`Hmis::Form::Instance`), with projects and organizations referenced by HUD ID.
- All custom service types and categories, any HUD service types that form rules use, and all file tags (`GrdaWarehouse::AvailableFileTag`). These feed the `ALL_SERVICE_TYPES`, `ALL_SERVICE_CATEGORIES`, and `AVAILABLE_FILE_TYPES` pick lists.
- All project configs (`Hmis::ProjectConfig` subclasses), except a config whose project, organization, or `receives_direct_referrals_from` project is deleted. Without its scope a config can't be saved, and an emptied `receives_direct_referrals_from` accepts referrals from every project. The export warns about each one it leaves out.
- Coordinated Entry configuration: the `hmis_ce/*` settings, the CE eligibility project group, referral statuses, decline reasons, workflow templates with their swimlanes, nodes, and flows, unit types, project unit type mappings, unit groups, units with their active ranges, and match rules.
- The organizations and projects any of the above point at, with each project's funders, ProjectCoCs, and inventory. Rule matching reads a project's type, organization, and funders (`Hmis::Form::InstanceProjectMatch`), and creating an enrollment needs a ProjectCoC. An organization form rule brings every project in the organization. A project whose organization is deleted is left out with a warning.
- `pick_list_references`, a list of the server-side pick lists each form uses. Those lists are built from local data, so they can't be copied; the list is there to check against.

CE runtime data (candidate pools, opportunities, referrals, workflow executions) is left out. Candidate pools rebuild when the imported match rules, unit groups, and CE project configs are saved.

Several records store database ids, which differ between installations. The export writes them as HUD IDs or names, and the import maps them back: `receives_direct_referrals_from` on `Hmis::ProjectCeConfig`, the project and organization ids in project group criteria, the eligibility group id in `hmis_ce/eligibility_project_group_id`, and node ids inside workflow templates.

## How imported records are matched

The import sets only the columns the export writes, so a file can't move a record into another data source or set its id.

A record that would fail validation, or that conflicts with local data in a way the import can't resolve, is skipped and logged rather than aborting the import. The table lists those cases.

| Record | Matched by | When it already exists |
|---|---|---|
| Form definition | identifier and version | Overwritten. A different local version holding the published or draft slot is retired or soft-deleted, since only one of each is allowed per identifier. |
| CDED | owner type and key | Updated. A key held by another data source is skipped, because the key is unique across data sources. A `reporting_key` used by a different local CDED is replaced with a new one, and later imports keep that replacement. |
| Organization, project, funder, ProjectCoC, inventory | HUD ID | Updated if it is the same record; otherwise the copy gets a new HUD ID (see below). |
| Form rule | all of its attributes | Left alone. |
| Project config | type and scope (project, organization, or project type) | Updated. Skipped when it has no scope, or when a `receives_direct_referrals_from` project isn't found locally. |
| CE setting | key | Updated. A blank or `false` value is skipped, because `AppConfigProperty` requires a present value. |
| Referral status, decline reason | key | Updated. |
| Workflow template | identifier and version | Left alone, because referrals point at the template's database id. Skipped when a soft-deleted local copy or another data source holds that version, or when it fails validation. |
| Unit group | project and name | Updated, except template identifiers and unit type, which can't change once set. A differing local value is kept and logged. A soft-deleted match is restored. Skipped when it fails validation, along with its units. |
| Unit | count of identical units | Units usually have no name, so for each distinct unit the import creates however many the project is missing. Extra local units are left alone. |
| Match rule | owner and name | Updated. Skipped when the rule type differs, which can't change, or when another local rule on the owner holds its `priority_rank`. |

## Projects whose HUD IDs are taken

In development, the import prefixes organization and project names with `REAL - ` so copies of real records stand out. A local record with the same HUD ID counts as the same record only if its name matches; for funders, ProjectCoCs, and inventory, only if it belongs to the same project. Otherwise the HUD ID belongs to unrelated local data, and the copy is saved as `R1-<id>`, then `R2-<id>`, and so on. The choice is deterministic, so importing the same file again finds the same copies. A project renamed on the source is created again on the next import.

HUD records are saved without validation. HUD validators can reject historical data the source installation already accepted.

## Transactions and global settings

CE settings (`AppConfigProperty`) are in the primary database and everything else is in the warehouse database. The import wraps both, so a dry run or a failure rolls back both.

CE settings, file tags, and unit types are shared by every data source in the installation. Importing into one HMIS data source changes them for all of them, including pointing `hmis_ce/eligibility_project_group_id` at that data source's project group.

## Related

- [Form definitions](hmis-form-definitions.md) — roles, versions, and the publish lifecycle the import works within
- [Form seeding](hmis-form-seeding.md) — seeded forms are overwritten on the next seed run, including ones the import replaced
- [Form resolution](hmis-form-resolution.md) — how form rules pick a definition for a project
- [CE workflow builders](ce-workflow-builders.md) — how workflow templates are normally created
- [HMIS permissions](hmis-permissions.md) — imported projects are visible only through a collection that covers them
