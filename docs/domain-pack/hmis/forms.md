---
title: "HMIS forms: definitions, rules, processing, seeding"
summary: "The form system behind every HMIS data-entry screen. Hmis::Form::Definition versions and roles, Hmis::Form::Instance rules and how the best rule is resolved for a project or enrollment, FormProcessor writing values into HUD and custom records, the JSON schema for definitions, and how HUD-compliance forms are seeded from version control."
area: hmis
tags: [hmis, forms, Hmis::Form::Definition, Hmis::Form::Instance, form-rule, FormProcessor, DefinitionValidator, DefinitionItemFilter, RecordType, SubmitFormRecordInitializer, SubmitFormAuthorizer, CustomDataElementGenerator, JsonForms, seed_definitions, form_data, managed_in_version_control, PublishFormDefinition, CreateNextDraftFormDefinition, OccurrencePointFormCollection]
sources:
  - drivers/hmis/app/models/hmis/form/definition.rb
  - drivers/hmis/app/models/hmis/form/instance.rb
  - drivers/hmis/app/models/hmis/form/instance_project_match.rb
  - drivers/hmis/app/models/hmis/form/instance_enrollment_match.rb
  - drivers/hmis/app/models/hmis/form/form_processor.rb
  - drivers/hmis/app/models/hmis/form/definition_validator.rb
  - drivers/hmis/app/models/hmis/form/definition_item_filter.rb
  - drivers/hmis/app/models/hmis/form/numeric_input_validator.rb
  - drivers/hmis/app/models/hmis/form/record_type.rb
  - drivers/hmis/app/models/hmis/form/submit_form_record_initializer.rb
  - drivers/hmis/app/models/hmis/form/submit_form_authorizer.rb
  - drivers/hmis/app/models/hmis/form/custom_data_element_generator.rb
  - drivers/hmis/app/models/hmis/form/occurrence_point_form_collection.rb
  - drivers/hmis/app/models/hmis/hud/processors/base.rb
  - drivers/hmis/app/graphql/mutations/submit_form.rb
  - drivers/hmis/app/graphql/mutations/create_next_draft_form_definition.rb
  - drivers/hmis/app/graphql/mutations/publish_form_definition.rb
  - drivers/hmis/app/graphql/types/forms/form_definition.rb
  - drivers/hmis/app/graphql/types/hmis_schema/query_type.rb
  - drivers/hmis_external_apis/public/schemas/form_definition.json
  - drivers/hmis/lib/hmis_util/json_forms.rb
  - drivers/hmis/lib/hmis_util/hud_compliance_form_instance_maintainer.rb
  - drivers/hmis/lib/tasks/setup.rake
related:
  - hmis/assessments.md
  - hmis/data-model.md
  - hmis/external-apis.md
---

## Purpose

Nearly every data-entry screen in the HMIS front-end renders a form definition served by this
repo. Four models carry the system: `Hmis::Form::Definition` (table `hmis_form_definitions`), a
versioned JSON questionnaire with a `role` and a `status`; `Hmis::Form::Instance` (table
`hmis_form_instances`, "Form Rule" in the UI), which binds a definition `identifier` to a
project, organization, project type, funder, or service type; `Hmis::Form::FormProcessor`
(table `hmis_form_processors`), which stores a submission and writes it into HUD and custom
records; and `Hmis::Hud::CustomDataElementDefinition`, which holds answers with no HUD column.

This doc covers the definition model and lifecycle, rule resolution, the processing pipeline,
the definition JSON and its validator, and seeding from `drivers/hmis/lib/form_data/`.
Assessment-specific behavior (the `CustomAssessment` envelope, `SubmitAssessment`,
`SubmitHouseholdAssessments`, work-in-progress saves, upgrading a retired definition on
unlock) is in `hmis/assessments.md`. Public external forms are in `hmis/external-apis.md`.

## Entry points

- `Mutations::SubmitForm` (`drivers/hmis/app/graphql/mutations/submit_form.rb`): the general
  record-form path. Resolves the definition by id within the user's data source, requires
  `valid_status_for_submit?`, builds a new owner with `Hmis::Form::SubmitFormRecordInitializer`
  or finds one with `viewable_by`, authorizes with `Hmis::Form::SubmitFormAuthorizer`, then
  runs the processor inside one `Hmis::Hud::Base.transaction`. Extends `Mutations::BaseMutation`.
- `Hmis::Form::FormProcessor#run!(user:)`: the only writer from `hud_values` to records.
  `collect_form_validations` and `collect_processing_validations` are the two server-side
  validation phases.
- `Hmis::Form::Definition.find_definition_for_role(role, project:, data_source_id:)` and
  `.for_project(project:, role:, service_type:)`: pick the published definition for new data
  entry. `Hmis::Form::Instance.detect_best_instance_for_project` and
  `.detect_best_instance_for_enrollment` do the ranking.
- GraphQL queries `recordFormDefinition`, `assessmentFormDefinition`, `serviceFormDefinition`,
  `staticFormDefinition` in `drivers/hmis/app/graphql/types/hmis_schema/query_type.rb`. They
  set `definition.filter_context = { project:, active_date: }`, which
  `Types::Forms::FormDefinition#definition` feeds to `Hmis::Form::DefinitionItemFilter`.
- `Mutations::CreateNextDraftFormDefinition` and `Mutations::PublishFormDefinition`: the
  Form Builder lifecycle. `DeleteFormDefinition` and `CreateFormDefinition` exist alongside.
- `rake driver:hmis:seed_definitions` (`drivers/hmis/lib/tasks/setup.rake`) calls
  `HmisUtil::JsonForms.seed_all(data_source_id:)` per HMIS data source. `db/seed_maker.rb`
  `load_hmis_data` runs the same call on `db:seed` when `ENV['ENABLE_HMIS_API'] == 'true'`.

## How it works

### Definitions

`identifier` is the stable key across versions and is what rules reference. `version` is an
integer; `identifier` + `version` is unique per `data_source_id`. `status` is `draft`,
`published`, or `retired` (`STATUSES`). `valid_status_for_submit?` accepts `published` or
`retired`, so records collected with a retired form stay editable. `before_destroy` aborts
unless `draft?`; `form_processors` is `dependent: :restrict_with_exception`.

Roles are grouped in constants: `ASSESSMENT_FORM_ROLES` (own a `CustomAssessment`),
`SYSTEM_FORM_ROLES` (required; `find_definition_for_role` raises when none is found),
`DATA_COLLECTION_FEATURE_ROLES` (optional, enabled per project by an active rule; includes
deprecated `REFERRAL` and `REFERRAL_REQUEST`), `STATIC_FORM_ROLES` (admin config forms, no
rules, bespoke mutations), plus `OCCURRENCE_POINT`, `CLIENT_DETAIL`, `FILE`, `CE_REFERRAL_STEP`.
`FORM_ROLE_CONFIG` maps a role to its `owner_class`; `owner_class_for_role` returns
`Hmis::Hud::CustomAssessment` for assessment roles. `NEW_CLIENT_ENROLLMENT` is create-only via
`allowed_form_record_actions`.

`CreateNextDraftFormDefinition` dups the latest version with `version + 1` and `status: draft`,
returning an existing draft if one exists. `PublishFormDefinition` requires `draft?`, calls
`set_hud_requirements`, then in one transaction retires the currently published version, runs
`CustomDataElementGenerator` with `create_missing_mappings: true`, saves the new CDEDs, runs
`validate_json_form`, and rolls back if it returns errors.

Definitions with `managed_in_version_control: true` are the deliberate exception:
`HmisUtil::JsonForms#load_definition` upserts one row per identifier at `version: 0`, replaces
`definition` from the file, and forces `status` to `published` on every run.
`validates_uniqueness_of :identifier` applies only to these.

### Rules and resolution

An `Instance` scopes a definition through optional columns `entity_type`/`entity_id`
(Project or Organization), `project_type`, `funder`/`other_funder`,
`custom_service_type_id`/`custom_service_category_id`, and `data_collected_about`. All blank
means a default rule (`Instance.defaults`). `system: true` rules come from seeding; deletion
is `active: false`. Validation: a `SERVICE` rule must name a type or category in the same data
source; an `EXTERNAL_FORM` rule must be Project-scoped and only one may be active.

`Definition.for_project` takes published definitions for the role in the project's data source
that have at least one active rule (`Definition.active`), collects their active instances, and
calls `Instance.detect_best_instance_for_project`. `Hmis::Form::InstanceProjectMatch` ranks
`RANKED_MATCHES`: `project`, `organization`, `project_type_and_funder`, `project_type`,
`project_funder`, `default`, `default_system`. Sort is stable by index, so ties fall to scope
order. A system default ranks last so a community default beats it. Funder matching reads
`project.funders` without an active filter (TODO in source).

`Hmis::Form::InstanceEnrollmentMatch` evaluates the rule's `data_collected_about`
(`ALL_CLIENTS` when nil, `HOH_AND_ADULTS`, `HOH`, `ALL_VETERANS`, `VETERAN_HOH`) against the
enrollment; `Instance#project_and_enrollment_match` requires both matches.

Exclusive-vs-inclusive is decided in `query_type.rb`, not the model: `recordFormDefinition`
returns one definition; service and custom-assessment resolvers return every match.
`recordFormDefinition` and `serviceFormDefinition` (HUD service types only) fall back to any
published `managed_in_version_control` definition for the role when no rule matches, so a
misconfigured project still renders. `Hmis::Form::OccurrencePointFormCollection` returns
occurrence-point forms enabled for an enrollment plus `HUD_DEFAULT_FORMS` (`move_in_date`,
`date_of_engagement`, `path_status`) as `legacy` when the enrollment holds that field with no
active rule.

### Processing

A submission carries `values` (keyed by `link_id`, used for form validation and the
assessment date) and `hud_values` (keyed by `Container.fieldName` or bare `fieldName`, used
for writing). The server never derives one from the other.

`FormProcessor#run!` groups `hud_values_by_container`. A bare key belongs to
`owner_container_name`: the owner class demodulized, except `Hmis::Hud::Assessment` becomes
`CeAssessment` and `Hmis::WorkflowExecution::Step` becomes `WorkflowStep`. The frozen
`valid_containers` hash maps a container to an `Hmis::Hud::Processors::*` class;
`Hmis::Form::RecordType` maps a `mapping.record_type` to the same `processor_name`
(`DISABILITY_GROUP` has no `owner_type`; `GEOLOCATION` owns `Hmis::Hud::Enrollment`). The
definition is the allow-list: `mapped_record_form_fields` and `mapped_custom_form_fields`
collect declared `field_name`s and `custom_field_key`s per container, and any other field
raises `unknown_field_error`. A field whose item sets `editor_user_ids` not containing the
user is skipped with no error.

`Hmis::Hud::Processors::Base#process` underscores the field, looks up the GraphQL enum on the
subclass `schema`, and converts with `attribute_value_for_enum`: `nil`/`''` becomes the enum's
data-not-collected value, `'_HIDDEN'` (`HIDDEN_FIELD_VALUE`) becomes `nil`, arrays map
element-wise, unknown values pass through. `process_custom_field` finds the CDED by
`owner_type` and key (raises when missing), normalizes by `field_type`, and assigns
`custom_data_elements_attributes`. A second pass calls `assign_metadata`, `information_date`
(assessment date, or `submitted_at` for external submissions), and `post_process`. On a
`CustomAssessment`, a container whose fields are all `_HIDDEN` and whose processor is
`dependent_destroyable?` (CE assessment, CE event, current living situation, geolocation)
has its record destroyed instead.

Validation phases: `collect_form_validations` (`Definition#validate_form_values`: required,
`warn_if_empty`, `Hmis::Form::NumericInputValidator`), `record.valid?` with contexts
`:form_submission` and `:<role>_form`, then `collect_processing_validations` (AR errors on
related records, `CustomAssessmentValidator.validate_assessment_date`, one
`Hmis::Hud::Validators::BaseValidator` subclass per related record, `processing_errors`).

### Authoring

The JSON shape is defined by `drivers/hmis_external_apis/public/schemas/form_definition.json`,
applied through `Definition.validate_schema` and `HmisExternalApis::JsonValidator`. Top level
allows only `item` (required) and `name`. Items are a recursive tree; only `GROUP` nests.
`Definition#link_id_item_hash` excludes groups.

`Hmis::Form::DefinitionValidator.perform(document, role, skip_cded_validation:,
data_source_id:)` runs on publish and on seed: schema, missing or duplicate `link_id`,
references in `bounds`, `enable_when`, `autofill_values`, `autofill_when`, mutually exclusive
keys, `enable_when` answer codes against the referenced pick list, HUD-required link ids for
the role (`check_hud_requirements`), and CDED type and `repeats` compatibility
(`validate_cded`). `Definition#validate_json_form` skips CDED checks for drafts.

`mapping` names either `field_name` (camelCase GraphQL field) or `custom_field_key`, plus an
optional `record_type`. A CDED's owner is `RecordType.find(record_type).owner_type` or the
role's `owner_class`; keys are unique per owner type, not globally.
`Hmis::Form::CustomDataElementGenerator#run` walks non-group, non-display items without a
`field_name`, validates existing CDED mappings, and when `create_missing_mappings` is true
builds a CDED keyed from `link_id` (`ensure_unique_key`), sets `reporting_key`, and rewrites
the item's `mapping`. It maps an `HmisService` owner to `Hmis::Hud::Service` for the stock
`service` form and `Hmis::Hud::CustomService` otherwise.

Server-side item filtering is `Hmis::Form::DefinitionItemFilter`: `rule` (HUD, written by
`Definition#set_hud_requirements` from `HmisUtil::HudAssessmentFormRules2026`) or
`custom_rule`; either passing keeps the item; no project means everything passes; a group
whose children are all filtered is dropped. Variables: `projectType`, `projectId`,
`projectFunders`, `projectFunderComponents`, `projectOtherFunders`; operators `EQUAL`,
`NOT_EQUAL`, `INCLUDE`, `NOT_INCLUDE`, `ANY`, `ALL`. `enable_when`, `autofill_values`,
`initial`, and item-level `data_collected_about` are front-end only.

### Seeding

`HmisUtil::JsonForms` reads `drivers/hmis/lib/form_data/`. `env_key` is `test` in the test
env, `ENV['CLIENT']` when set, `qa_hmis` in development, else nil. `seed_all` runs in one
transaction: `seed_record_form_definitions` (`default/records/*.json`, file name is the role;
`default/services`, `default/ce_referral_steps`, `default/occurrence_point_forms` for
`SERVICE`, `CE_REFERRAL_STEP`, `OCCURRENCE_POINT`), `seed_assessment_form_definitions`
(`base_<role>.json`, identifier `base-<role>`), `seed_custom_assessment_form_definitions`
(`<env>/custom_assessments/`, only if the directory exists; a no-op in production), `seed_static_forms`
(`static/<role>.json`), then `HmisUtil::HudComplianceFormInstanceMaintainer#ensure_all_system_instances_exist!`.

Per file, `load_definition` resolves `fragment` references from `default/fragments` (env
overrides replace by name), applies `<env>/fragments/patches/*.json` (item patches by
`link_id` merge attributes and `append_items`/`prepend_items`; form patches by
`form_identifier`), upserts the `version: 0` row, calls `set_hud_requirements`, runs
`CustomDataElementGenerator` with `create_missing_mappings: false` when `generate_cdeds`
(default off in test), validates, and raises `JsonFormException` on the first error.

The maintainer creates `system: true, active: true` instances: a default rule per
`SYSTEM_FORM_ROLES` identifier and per base assessment (post-exit by
`post_exit_aftercare_plans_funders`), project-type and funder rules for `move_in_date`
(`HOH`), `date_of_engagement`, `path_status`, `current_living_situation`, and per-category
rules for the `service` form from `HudHelper.util.service_form_funder_applicability_requirements`.
Changes are logged and pinged through `NotifierConfig`.

## Key files

- `drivers/hmis/app/models/hmis/form/definition.rb`: role constants, `FORM_ROLE_CONFIG`,
  `STATUSES`, `for_project`, `find_definition_for_role`, `validate_form_values`,
  `link_id_item_hash`, `set_hud_requirements`, `supports_save_in_progress?`.
- `drivers/hmis/app/models/hmis/form/instance.rb`: scope columns, `defaults`, validations,
  `detect_best_instance_for_project`, `detect_best_instance_for_enrollment`.
- `drivers/hmis/app/models/hmis/form/instance_project_match.rb`: `RANKED_MATCHES`.
- `drivers/hmis/app/models/hmis/form/instance_enrollment_match.rb`: `MATCHES`.
- `drivers/hmis/app/models/hmis/form/form_processor.rb`: `run!`, `valid_containers`,
  factories, `collect_form_validations`, `collect_processing_validations`,
  `destroy_related_records!`.
- `drivers/hmis/app/models/hmis/hud/processors/base.rb`: `HIDDEN_FIELD_VALUE`,
  `attribute_value_for_enum`, `process_custom_field`, `dependent_destroyable?`.
- `drivers/hmis/app/models/hmis/form/record_type.rb`: `record_type` to container mapping.
- `drivers/hmis/app/models/hmis/form/submit_form_record_initializer.rb`,
  `submit_form_authorizer.rb`: create-path record build and policy choice by owner class.
- `drivers/hmis/app/models/hmis/form/definition_validator.rb`,
  `definition_item_filter.rb`, `numeric_input_validator.rb`: validation and filtering.
- `drivers/hmis/app/models/hmis/form/custom_data_element_generator.rb`: CDED creation.
- `drivers/hmis/app/models/hmis/form/occurrence_point_form_collection.rb`: `HUD_DEFAULT_FORMS`.
- `drivers/hmis/app/graphql/mutations/submit_form.rb`, `create_next_draft_form_definition.rb`,
  `publish_form_definition.rb`: submit and lifecycle mutations.
- `drivers/hmis/app/graphql/types/forms/form_definition.rb`: `definition` (filtered) vs
  `raw_definition`. `drivers/hmis/app/graphql/types/hmis_schema/query_type.rb`: resolvers and
  the version-controlled fallback.
- `drivers/hmis_external_apis/public/schemas/form_definition.json`: JSON schema.
- `drivers/hmis/lib/hmis_util/json_forms.rb`,
  `drivers/hmis/lib/hmis_util/hud_compliance_form_instance_maintainer.rb`,
  `drivers/hmis/lib/tasks/setup.rake`: seeding.

## Gotchas

- Empty and hidden differ: `nil`/`''` becomes the enum's data-not-collected value, `_HIDDEN`
  becomes `nil`, so adding `enable_when` to a populated question nulls the column on resubmit.
- `ClientProcessor` ignores `_HIDDEN` for `ssn` and `dob` because those are hidden by
  permission, not by conditional logic.
- Enrollment is not a `FormProcessor` association; `enrollment_factory` infers it, so
  `form_processor.save!` does not save it and every submit path must save the enrollment.
- `editor_user_ids` drops the field silently for other users; the save reports success.
- On a `CustomAssessment`, a container with every field `_HIDDEN` and a `dependent_destroyable?`
  processor has its record destroyed, so an `enable_when` change can delete CE events, CE
  assessments, current living situations, or geolocation.
- `collect_processing_validations` runs the validator of each related record in the definition
  role's context, so an enrollment form that creates a client does not run the client
  validator.
- `NumericInputValidator` checks only `INTEGER` and `CURRENCY`, only non-warning bounds with a
  literal `value_number`; `DATA_NOT_COLLECTED` and `_HIDDEN` bypass it.
- `enable_when`, `autofill_values`, `initial`, and item-level `data_collected_about` are never
  re-evaluated server-side; a non-UI caller can write hidden questions.
- An input item with no `mapping` is valid JSON and its answer is discarded.
- `set_hud_requirements` overwrites hand-written `rule` on HUD assessment forms and only
  relaxes `data_collected_about`, never tightens it.
- A definition whose items are all filtered out for a project makes the non-null
  `FormDefinition.definition` field fail at query time.
- Two `OCCURRENCE_POINT` rules collecting the same enrollment field both apply and the field
  shows twice; `OccurrencePointFormCollection` has no per-field exclusivity.
- Funder matching in `InstanceProjectMatch` uses all of `project.funders`, including ended
  ones.
- `recordFormDefinition` falls back to any version-controlled form for the role, so a broken
  rule set looks like it works.
- `filter_context` is a plain `attr_accessor` set by resolvers; definitions exercised outside
  GraphQL have no filtering.
- Form Builder edits to a `managed_in_version_control` form are overwritten on the next seed;
  adding a JSON file for a retired identifier republishes it.
- `HmisUtil::JsonForms` `generate_cdeds` defaults to false in the test environment, so
  `custom_field_key` CDED validation is skipped there.
- `drivers/hmis/lib/form_data/static/external_form_submission_review.json` has no matching
  `STATIC_FORM_ROLES` entry, so `seed_static_forms` never loads it.

## Do not repeat

- Editing a published `Hmis::Form::Definition` in place. Use `CreateNextDraftFormDefinition`
  then `PublishFormDefinition`; the only sanctioned in-place overwrite is
  `HmisUtil::JsonForms#load_definition` for `managed_in_version_control` rows.
- Committing customer-specific service forms, custom assessments, case-note, or client-detail
  forms under `drivers/hmis/lib/form_data/`. Those belong in the Form Builder;
  `<env>/custom_assessments/` is for test and QA data only.
- Extending `Hmis::Form::OccurrencePointFormCollection` (`HUD_DEFAULT_FORMS`). It is a
  compatibility shim for showing HUD occurrence-point data with no active rule, not a
  resolution API; add a rule via the maintainer instead.
- Referencing a definition by `id` from a rule or config. Rules reference
  `definition_identifier`; `FormProcessor#definition_id` is the one place an `id` is stored.
- Deriving `hud_values` from `values` on the server, or writing HUD records from anything but
  `FormProcessor#run!` and the `Hmis::Hud::Processors::*` classes.
- Reproducing the container list or record-type list outside `FormProcessor#valid_containers`
  and `Hmis::Form::RecordType`.
- Naming `HudUtility2026` directly for applicability requirements; use `HudHelper.util`.

## Related

- `hmis/assessments.md`: `CustomAssessment` envelope, `SubmitAssessment`,
  `SubmitHouseholdAssessments`, WIP saves, upgrading a retired definition on unlock.
- `hmis/data-model.md`: `Hmis::Hud::*` aliasing and `CustomDataElement` storage.
- `hmis/external-apis.md`: `EXTERNAL_FORM` role, `FormSubmission` processing that skips both
  validation phases, and why the JSON schema lives in `drivers/hmis_external_apis`.
- Human-facing sources: `docs/features/hmis/hmis-form-definitions.md`,
  `hmis-form-resolution.md`, `hmis-form-processing.md`, `hmis-form-authoring.md`,
  `hmis-form-seeding.md`; `drivers/hmis/lib/form_data/README.md`.
