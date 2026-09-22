---
title: HMIS data model
summary: "Hmis::Hud::* models share HUD CSV tables with GrdaWarehouse::Hud::*, keyed by data_source_id plus HUD IDs. Covers Hmis::Hud::Base aliasing, association helpers, the Custom* tables that hold non-HUD data (custom data elements, custom assessments, services, names, addresses, case notes), processors that write form input into records, and project configs, units, and beds."
area: hmis
tags: [hmis, data-model, Hmis::Hud::Base, alias_to_underscore, data_source_id, PersonalID, EnrollmentID, project_pk, hmis_relation, hmis_enrollment_relation, CustomDataElement, CustomDataElementDefinition, CustomAssessment, CustomService, CustomServiceType, CustomClientName, CustomClientAddress, CustomCaseNote, processors, FormProcessor, ProjectConfig, Unit, UnitOccupancy, UnitType]
sources:
  - drivers/hmis/app/models/hmis/hud/base.rb
  - drivers/hmis/app/models/hmis/hud/concerns/shared.rb
  - app/models/concerns/hmis_structure/shared.rb
  - drivers/hmis/app/models/hmis/hud/client.rb
  - drivers/hmis/app/models/hmis/hud/enrollment.rb
  - drivers/hmis/app/models/hmis/hud/custom_data_element.rb
  - drivers/hmis/app/models/hmis/hud/custom_data_element_definition.rb
  - drivers/hmis/app/models/hmis/hud/custom_assessment.rb
  - drivers/hmis/app/models/hmis/hud/custom_service.rb
  - drivers/hmis/app/models/hmis/hud/custom_service_type.rb
  - drivers/hmis/app/models/hmis/hud/custom_service_category.rb
  - drivers/hmis/app/models/hmis/hud/custom_client_name.rb
  - drivers/hmis/app/models/hmis/hud/custom_client_address.rb
  - drivers/hmis/app/models/hmis/hud/custom_client_contact_point.rb
  - drivers/hmis/app/models/hmis/hud/custom_case_note.rb
  - drivers/hmis/app/models/hmis/hud/processors/base.rb
  - drivers/hmis/app/models/hmis/hud/processors/client_processor.rb
  - drivers/hmis/app/models/hmis/hud/processors/enrollment_processor.rb
  - drivers/hmis/app/models/hmis/project_config.rb
  - drivers/hmis/app/models/hmis/unit.rb
  - drivers/hmis/app/models/hmis/unit_occupancy.rb
  - drivers/hmis/app/models/hmis/unit_type.rb
  - drivers/hmis/app/models/hmis/project_unit_type_mapping.rb
related:
  - hmis/forms.md
  - hmis/assessments.md
  - hud-reporting/hud-utility-versions.md
  - warehouse/client-identity.md
  - authorization/hmis-permissions.md
  - conventions/do-not-repeat.md
---

## Purpose

How records in the HMIS (`drivers/hmis`) are shaped and related. `Hmis::Hud::*` models read and
write the same HUD CSV tables as `GrdaWarehouse::Hud::*` (`Client`, `Enrollment`, `Project`, ...)
plus the Open Path `Custom*` tables that hold data HUD does not define. Read this before adding a
model, association, column, or query that touches an HMIS record; before changing how form input is
written into records; and before touching project configs, units, or beds.

Out of scope: how a form is defined, resolved, and processed end to end (`hmis/forms.md`),
assessment stages and household submission (`hmis/assessments.md`), and warehouse client identity
(`warehouse/client-identity.md`).

## Entry points

- `Hmis::Hud::Base` (`drivers/hmis/app/models/hmis/hud/base.rb`): abstract parent of every HMIS
  HUD and `Custom*` model. Inherits `GrdaWarehouseBase`; sets `acts_as_paranoid(column: :DateDeleted)`;
  adds `DateCreated`/`DateUpdated` to Rails' timestamp columns; fills the HUD key with a UUID before
  validation (`ensure_id`, `generate_uuid`); default `viewable_by` scope returns `none`, so each
  model replaces it.
- `Hmis::Hud::Base.hmis_relation(col, model_name)`: association options for a
  `(data_source_id, <HUD ID>)` composite key. `belongs_to :client, **hmis_relation(:PersonalID, 'Client')`.
- `Hmis::Hud::Base.hmis_enrollment_relation(model_name)`: `(EnrollmentID, PersonalID, data_source_id)`
  composite key for enrollment children. `has_many :services, **hmis_enrollment_relation('Service')`.
- `Hmis::Hud::Concerns::Shared` (`drivers/hmis/app/models/hmis/hud/concerns/shared.rb`): included by
  HUD-shaped models. Pulls in `HmisStructure::Shared`, which `alias_attribute`s every PascalCase HUD
  column to snake_case (`project_id` for `ProjectID`); `WithStrictAttributes`, which validates
  numericality on every numeric column; `as_warehouse`, which loads the `GrdaWarehouse::Hud::*` twin
  by `id`; and the class lists `hud_class_names` and `enrollment_personal_id_keyed_class_names`.
- `Hmis::Hud::Base.alias_to_underscore(cols)`: the same aliasing for columns outside the HUD
  structure (`CustomCaseNoteID`, `DataCollectionStage`).
- `Hmis::Hud::CustomDataElementDefinition.for_type(owner_sti_name).find_by(key:)`: how a custom
  field is resolved from a form field name.
- `Hmis::ProjectConfig.detect_best_config_for_project(project)`; `Hmis::Unit`, `Hmis::UnitOccupancy`,
  `Hmis::UnitType`; `Hmis::Hud::Enrollment#assign_unit` and `#release_unit!`.

## How it works

### Shared tables and identity

`Hmis::Hud::Client` and `GrdaWarehouse::Hud::Client` both map to table `Client`; the same holds for
every HUD model. Rails `id` stays the primary key (each model sets `self.sequence_name`) and is
what GraphQL, `has_paper_trail`, and the `Hmis::` side tables (`hmis_units`, `hmis_project_configs`)
reference. Relationships between HUD records use a HUD ID plus `data_source_id`, through
`hmis_relation` and `hmis_enrollment_relation`; a HUD ID alone is not unique. One exception:
`Hmis::Hud::Enrollment belongs_to :project, foreign_key: :project_pk`, a plain PK reference, so an
in-progress ("WIP") enrollment can have `ProjectID` NULL and still reach its project.
`save_not_in_progress!` copies `project.project_id` into `ProjectID`; `in_progress?` is
`ProjectID.nil?`. Soft deletion is `acts_as_paranoid` on `DateDeleted`; `Enrollment#client_including_deleted`
shows the `with_deleted` idiom.

### Custom data elements

`Hmis::Hud::CustomDataElementDefinition` (table `CustomDataElementDefinitions`) describes one custom
field: `owner_type` (an STI name such as `Hmis::Hud::CustomAssessment`), `key`, `label`,
`field_type` (one of `FIELD_TYPES`), `repeats`, and an optional `form_definition_identifier`. The
database enforces `(owner_type, key)` unique across all data sources. `Hmis::Hud::CustomDataElement`
(table `CustomDataElements`) holds one value in the `value_<field_type>` column matching its
definition (`value_file_id` for `file`) and `belongs_to :owner, polymorphic: true`. Validations
require exactly one value column and an owner type equal to the definition's; a uniqueness
validation on `owner_id` enforces `repeats: false`. Definitions are created by
`Hmis::Form::CustomDataElementGenerator` when a form definition is published
(`Mutations::PublishFormDefinition`) or seeded (`HmisUtil::JsonForms`), one per form item that has no
HUD field mapping.

### Custom records

Every `Custom*` model is an Open Path addition; PascalCase table names follow the HUD CSV custom-file
convention, but none is a HUD record type. `Hmis::Hud::CustomAssessment` (`CustomAssessments`) is
the envelope for HUD data-collection stages (`data_collection_stage` 1 intake, 2 update, 3 exit,
5 annual, 6 post-exit) and for fully custom assessments; it `has_one :form_processor`, through which
the related HUD records are reached, and `wip` marks an unsubmitted assessment. In GraphQL the
`Assessment` type wraps `Hmis::Hud::CustomAssessment`; `CeAssessment` wraps the HUD
`Hmis::Hud::Assessment`. `Hmis::Hud::CustomService` (`CustomServices`) `belongs_to :custom_service_type`;
`Hmis::Hud::CustomServiceType` carries `hud_record_type`/`hud_type_provided` when it names a HUD
service and nil when custom; `Hmis::Hud::CustomServiceCategory` groups types. `Hmis::Hud::HmisService`
is a view over HUD and custom services. `CustomClientName`, `CustomClientAddress`, and
`CustomClientContactPoint` key to the client by `PersonalID`; each `has_one :active_range`
(`Hmis::ActiveRange`) and an `active(date)` scope. The name with `primary: true` is copied into
`Client.FirstName`/`LastName` (`Client#assign_primary_name_fields`, `ClientProcessor#process_names`).
An address with `enrollment_address_type: 'move_in'` belongs to an enrollment, and `Client#addresses`
excludes it. `CustomCaseNote` attaches to a client and optionally an enrollment.

### Processors

`Hmis::Hud::Processors::Base` is the parent of one processor per form record type
(`ClientProcessor`, `EnrollmentProcessor`, `ExitProcessor`, ...). `Hmis::Form::FormProcessor` calls
`process(field, value)` per form field; the processor converts the GraphQL enum string to the stored
HUD code (`attribute_value_for_enum`: blank becomes the data-not-collected code, `_HIDDEN` becomes
nil) and assigns it to the record returned by its `factory_name`. `process_custom_field` resolves the
definition by owner type and key and writes `custom_data_elements_attributes` (add, update,
`_destroy`). `construct_nested_attributes` does the same for nested records such as names and
addresses. `assign_metadata` sets `user` and `data_source_id` from the HUD user. Subclasses override
`process` for fields with special handling: `ClientProcessor` for race and gender multi-fields, SSN
and DOB hidden by permission, and MCI; `EnrollmentProcessor` for `current_unit`, move-in addresses,
`EnrollmentCoC` inference, and `HouseholdID` generation.

### Project configuration and units

`Hmis::ProjectConfig` (`hmis_project_configs`, STI on `type`) attaches one behavior setting to
exactly one of project, organization, or project type; subclasses are listed in
`CONFIG_TYPE_FACTORIES` (auto-exit, auto-enter, staff assignment, coordinated entry, direct CE
referrals). `detect_best_config_for_project` picks the most specific match: project, then
organization, then project type. Options live as a JSON string in `config_options`.

`Hmis::Unit` (`hmis_units`) is a generic unit of capacity in a project: a bed, room, apartment,
voucher, or service slot. It is separate from HUD `Inventory`. A unit `belongs_to :project`,
optionally a `unit_type` (`Hmis::UnitType`, descriptive; `bed_type` mirrors HUD inventory bed types)
and a `unit_group` (`Hmis::UnitGroup`, required to build a CE opportunity). `Hmis::UnitOccupancy`
(`hmis_unit_occupancy`) links one enrollment to one unit for the date range in `occupancy_period`
(`Hmis::ActiveRange`). Each household member has its own occupancy and a household may hold several
units; `Enrollment#assign_unit` refuses a unit occupied by a different household or tied to an open
or locked CE opportunity for someone else. `Enrollment#release_unit!` ends the period; a submitted
exit assessment calls it. `Hmis::ProjectUnitTypeMapping` creates and destroys units from an
external capacity feed.

## Key files

- `drivers/hmis/app/models/hmis/hud/base.rb`: `hmis_relation`, `hmis_enrollment_relation`, `alias_to_underscore`, `ensure_id`, HUD timestamp columns, default `viewable_by`.
- `drivers/hmis/app/models/hmis/hud/concerns/shared.rb`: `as_warehouse`, `hmis` scope, HUD and custom class name lists.
- `app/models/concerns/hmis_structure/shared.rb`: PascalCase to snake_case aliasing from `hmis_configuration`.
- `drivers/hmis/app/models/hmis/hud/client.rb`: names, addresses, contact points, `visible_to`/`viewable_by`, `client_search`, warehouse duplicate callbacks, `set_source_hash`.
- `drivers/hmis/app/models/hmis/hud/enrollment.rb`: `project_pk`, WIP save methods, enrollment children, `household_members`, `assign_unit`, `release_unit!`, `build_synthetic_intake_assessment`.
- `drivers/hmis/app/models/hmis/hud/custom_data_element_definition.rb`, `custom_data_element.rb`: `FIELD_TYPES`, `for_type`, value column validations.
- `drivers/hmis/app/models/hmis/hud/custom_assessment.rb`: stage scopes, `wip`, `form_processor`, `save_submitted_assessment!`.
- `drivers/hmis/app/models/hmis/hud/custom_service.rb`, `custom_service_type.rb`, `custom_service_category.rb`: service hierarchy; `hud`/`custom` scopes.
- `drivers/hmis/app/models/hmis/hud/custom_client_name.rb`, `custom_client_address.rb`, `custom_client_contact_point.rb`, `custom_case_note.rb`: client-keyed custom records, `active` scopes, `equal_for_merge?`.
- `drivers/hmis/app/models/hmis/hud/processors/base.rb`: `process`, `attribute_value_for_enum`, `process_custom_field`, `construct_nested_attributes`.
- `drivers/hmis/app/models/hmis/hud/processors/client_processor.rb`, `enrollment_processor.rb`: the two most-overridden processors.
- `drivers/hmis/app/models/hmis/project_config.rb`: `CONFIG_TYPE_FACTORIES`, `for_project`, `detect_best_config_for_project`.
- `drivers/hmis/app/models/hmis/unit.rb`, `unit_occupancy.rb`, `unit_type.rb`, `project_unit_type_mapping.rb`: units, occupancy periods, unit types, bulk unit creation.

## Gotchas

- Scope every HUD-ID lookup by `data_source_id`. `Enrollment#household_members` is the model:
  `where(household_id:, data_source_id:)`.
- `DateCreated` is filled on create when blank; `DateUpdated` is set on every save with changes and
  on `touch`. A value assigned before the first save survives. To backdate a saved record use
  `update_columns`, as `drivers/hmis/spec/jobs/merge_clients_job_spec.rb` does with `update_column`.
- Three "user" classes: `User` (warehouse, table `users`), `Hmis::User` (same `users` table, HMIS
  request context), and `Hmis::Hud::User` (HUD `User.csv`, table `User`), whose `UserID` is what
  `hmis_relation(:UserID, 'User')` joins. `Hmis::Hud::User.from_user(hmis_user)` bridges them.
- `Hmis::Hud::Base` `viewable_by` returns `none`; models replace it with `replace_scope`.
  `Hmis::Hud::Concerns::EnrollmentRelated` supplies one through the enrollment;
  `Client.viewable_by` is an alias of `visible_to`.
- `CustomDataElementDefinition.key` is unique per `owner_type` across all data sources, so one
  key cannot mean different fields in two HMIS installations on one warehouse.
- `Client#enrollments` and `Client#projects` include WIP enrollments; use
  `Enrollment.not_in_progress` when reporting.
- `Client#addresses` excludes move-in addresses; read those from `Enrollment#move_in_addresses`.
- `WithStrictAttributes` reads the table's columns at class load, so a model including `Shared`
  must set `table_name` before the include and the table must exist.
- `Client` and `Enrollment` callbacks enqueue warehouse work (`IdentifyDuplicates`, service history
  processing) when identity or enrollment columns change; `import!` skips them.
- `Hmis::ProjectConfig#options` returns nil on unparsable JSON instead of raising.

## Do not repeat

- Joining HUD tables on a HUD ID alone, such as `where(PersonalID: client.PersonalID)` or a hand-written
  `ON "Enrollment"."PersonalID" = ...`. Replace with an association built from `hmis_relation` or
  `hmis_enrollment_relation` (`Hmis::Hud::Client has_many :enrollments`), or add `data_source_id` to
  the condition as `Enrollment#household_members` does.
- Rails `enum` or literal integers on a HUD-coded column. `Hmis::UnitType` `enum :bed_type` is the
  existing legacy example. New code uses `HudHelper.util` and `Hmis::Hud::Concerns::HasEnums.use_enum`
  (`Hmis::Hud::Client.gender_enum_map`). Entry 7 in `conventions/do-not-repeat.md`.
- Relating an enrollment to its project by `ProjectID`. WIP enrollments have `ProjectID` NULL; use
  `belongs_to :project` (`project_pk`) and the `Enrollment.with_project(project_pks)` scope.

## Related

- `hmis/forms.md`: form definitions, instances, and `FormProcessor`, which drives the processors.
- `hmis/assessments.md`: `CustomAssessment` stages, household submission, migration.
- `hud-reporting/hud-utility-versions.md`: `HudHelper.util` for HUD-coded values.
- `warehouse/client-identity.md`: `Hmis::WarehouseClient`, `destination_client`, `IdentifyDuplicates`.
- `authorization/hmis-permissions.md`: what `viewable_by` and `with_access` enforce.
- `conventions/do-not-repeat.md`: entry 7 (HUD enums), entry 11 (`is_a?`).
- Human-facing source docs: `docs/features/hmis/hmis-units.md`, project `CLAUDE.md`
  "Unconventional HMIS HUD models".
