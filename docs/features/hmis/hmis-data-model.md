---
sources:
  - drivers/hmis/app/models/hmis/hud/base.rb
  - drivers/hmis/app/models/hmis/hud/enrollment.rb
  - drivers/hmis/app/models/hmis/hud/client.rb
  - drivers/hmis/app/models/hmis/hud/custom_data_element_definition.rb
  - drivers/hmis/app/models/hmis/hud/processors/base.rb
  - drivers/hmis/app/models/hmis/project_config.rb
  - drivers/hmis/app/models/hmis/hud/user.rb
---

# HMIS data model

How `Hmis::Hud::*` models relate to the warehouse's HUD models and to the Open Path `Custom*` tables. For units and beds see [Units](hmis-units.md); for assessments see [HMIS assessments](hmis-assessments.md).

## Shared tables

`Hmis::Hud::*` and `GrdaWarehouse::Hud::*` models read and write the same HUD CSV tables (`Client`, `Enrollment`, and so on). Rails `id` remains the primary key and is what GraphQL, PaperTrail, and the `Hmis::` side tables (`hmis_units`, `hmis_project_configs`) reference. Relationships between HUD records use a HUD ID plus `data_source_id`, built with `hmis_relation` and `hmis_enrollment_relation`; a HUD ID alone is not unique.

- **Enrollment to project uses a Rails key.** `Hmis::Hud::Enrollment belongs_to :project` through `project_pk`, not `ProjectID`. A work-in-progress (WIP) enrollment has `ProjectID` NULL until it is saved as not in progress, so joining on `ProjectID` loses WIP enrollments. Use the association or `Enrollment.with_project`.
- **WIP enrollments are included by default.** `Client#enrollments` and `Client#projects` include them; use `Enrollment.not_in_progress` when reporting.
- **Scope HUD-ID lookups by `data_source_id`.** `Enrollment#household_members` is the model to copy.
- **Three "user" classes.** `User` (warehouse `users` table), `Hmis::User` (same table, HMIS request context), and `Hmis::Hud::User` (HUD `User.csv`, table `User`). `UserID` joins to the last one; `Hmis::Hud::User.from_user` bridges them.
- **`viewable_by` defaults to none.** `Hmis::Hud::Base` returns an empty scope, so each model must replace it.
- **Timestamps.** `DateCreated` is filled on create only when blank; `DateUpdated` is set on every change. To backdate a saved record use `update_columns`.
- **Warehouse side effects.** Client create/update callbacks enqueue warehouse work (duplicate identification); bulk callers enqueue one full run instead.

## Why the `Custom*` tables exist

Every `Custom*` model is an Open Path addition for data HUD does not define. The PascalCase table names follow the HUD CSV custom-file convention, but none is a HUD record type.

- **Custom data elements.** `CustomDataElementDefinition` describes one custom field (owner type, key, field type, whether it repeats); `CustomDataElement` holds one value in the column matching the field type. A definition's `key` is unique per owner type across all data sources, so one key cannot mean different fields in two HMIS installations on one warehouse. Definitions are generated when a form definition is published or seeded, one per form item with no HUD field mapping.
- **`CustomAssessment`** is the envelope for HUD data-collection stages and fully custom assessments; see [HMIS assessments](hmis-assessments.md).
- **`CustomService`, `CustomServiceType`, `CustomServiceCategory`.** Services that are not HUD services. A type with `hud_record_type` and `hud_type_provided` names a HUD service; one without is custom. `Hmis::Hud::HmisService` is a view over both.
- **`CustomClientName`, `CustomClientAddress`, `CustomClientContactPoint`.** Multiple dated names, addresses, and contact points per client. The primary name is copied into `Client.FirstName`/`LastName`. An address with `enrollment_address_type: 'move_in'` belongs to an enrollment, and `Client#addresses` excludes it; read it from `Enrollment#move_in_addresses`.
- **`CustomCaseNote`** attaches to a client and optionally an enrollment.

## Writing form input into records

Form submissions pass through one processor per record type (`Hmis::Hud::Processors::*`); see [Form processing](hmis-form-processing.md). Conversion rules shared by all of them:

- A blank enum value is stored as the field's data-not-collected code.
- The hidden-field marker (`_HIDDEN`) is stored as nil.
- Custom fields are written as custom data elements, resolved by owner type and key.

## Project configuration

`Hmis::ProjectConfig` attaches one behavior setting (auto-exit, auto-enter, staff assignment, coordinated entry, direct CE referrals) to a project, an organization, or a project type. `detect_best_config_for_project` picks the most specific: project, then organization, then project type. Options are stored as a JSON string; an unparsable value reads as nil rather than raising.
