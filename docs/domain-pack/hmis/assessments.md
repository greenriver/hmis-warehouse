---
title: HMIS assessments
summary: "CustomAssessment is the envelope for both HUD data-collection stages (intake, update, annual, exit) and fully custom assessments; Hmis::Hud::Assessment is the HUD CE assessment. Covers the GraphQL naming inversion, submit and household-submit mutations, WIP vs submitted state, and the assessment migration job."
area: hmis
tags: [hmis, assessments, CustomAssessment, Hmis::Hud::Assessment, CeAssessment, data-collection-stage, intake, exit, annual, SubmitAssessment, SubmitHouseholdAssessments, wip, MigrateAssessmentsJob]
sources:
  - drivers/hmis/app/models/hmis/hud/custom_assessment.rb
  - drivers/hmis/app/models/hmis/hud/assessment.rb
  - drivers/hmis/app/models/hmis/hud/validators/custom_assessment_validator.rb
  - drivers/hmis/app/jobs/hmis/migrate_assessments_job.rb
  - drivers/hmis/app/graphql/mutations/submit_assessment.rb
  - drivers/hmis/app/graphql/mutations/submit_household_assessments.rb
  - drivers/hmis/app/graphql/mutations/save_assessment.rb
  - drivers/hmis/app/graphql/types/hmis_schema/assessment.rb
  - drivers/hmis/app/graphql/types/hmis_schema/ce_assessment.rb
  - drivers/hmis/app/graphql/types/hmis_schema/assessment_input.rb
  - drivers/hmis/app/graphql/types/hmis_schema/has_assessments.rb
related:
  - hmis/forms.md
  - hmis/data-model.md
  - hud-reporting/hud-utility-versions.md
---

## Purpose

"Assessment" names two unrelated models in `drivers/hmis`. `Hmis::Hud::CustomAssessment` (table `CustomAssessments`, an Open Path table, not HUD CSV) is an envelope: one row per performed assessment, pointing through an `Hmis::Form::FormProcessor` at the HUD records the form wrote (`IncomeBenefits`, `HealthAndDV`, `Disabilities`, `Exit`, and so on) and at custom data elements. `DataCollectionStage` says which kind: HUD stages 1 intake, 2 update, 3 exit, 5 annual, 6 post-exit, or 99 fully custom. `Hmis::Hud::Assessment` (table `Assessment`) is the HUD Coordinated Entry assessment from `Assessment.csv`, with `AssessmentQuestion` and `AssessmentResult` children.

GraphQL names are inverted from the models: type `Assessment` (`Types::HmisSchema::Assessment`) wraps `Hmis::Hud::CustomAssessment`; type `CeAssessment` (`Types::HmisSchema::CeAssessment`) wraps `Hmis::Hud::Assessment`. This doc covers the envelope model, the submit / save / household-submit mutations, WIP state, and `Hmis::MigrateAssessmentsJob`, which rebuilds envelopes for imported CSV data. Form definitions, processors, and resolution are in `hmis/forms.md`.

## Entry points

- `Mutations::SubmitAssessment` (`drivers/hmis/app/graphql/mutations/submit_assessment.rb`): create or update one `CustomAssessment`, run its `FormProcessor`, save it as submitted. Input is `Types::HmisSchema::AssessmentInput` (`form_definition_id`, `enrollment_id`, optional `assessment_id`, `values`, `hud_values`, `confirmed`, `validate_only`).
- `Mutations::SaveAssessment` (`drivers/hmis/app/graphql/mutations/save_assessment.rb`): same input, saves as WIP. Raises unless `definition.supports_save_in_progress?`.
- `Mutations::SubmitHouseholdAssessments` (`drivers/hmis/app/graphql/mutations/submit_household_assessments.rb`): submits several existing (usually WIP) assessments from one household, same stage, in one transaction. Input is `[VersionedRecordInput]` (id plus `lock_version`).
- `Mutations::DeleteAssessment` deletes a `CustomAssessment`; `Mutations::DeleteCeAssessment` deletes an `Hmis::Hud::Assessment`.
- Query `householdAssessments(householdId, assessmentRole, assessmentId)` on `Types::HmisSchema::QueryType` calls `Hmis::Hud::CustomAssessment.group_household_assessments` to find the household members' matching intake/exit/annual assessments (annuals within a 3-month threshold).
- `assessments_field` from `Types::HmisSchema::HasAssessments` (`drivers/hmis/app/graphql/types/hmis_schema/has_assessments.rb`): paginated list on `Client`, `Enrollment`, etc. with `viewable_by`, `apply_filters`, `with_role`, `in_progress`, and `sort_by_option`.
- Model scopes on `Hmis::Hud::CustomAssessment`: `intakes`, `exits`, `updates`, `annuals`, `post_exits`, `in_progress`, `not_in_progress`, `with_role(role)`, `with_project`, `with_project_type`, `with_form_definition_identifier`.
- `Hmis::Hud::Enrollment` associations: `custom_assessments`, `intake_assessment` (has_one, `intakes`), `exit_assessment` (has_one, `exits`), `post_exit_assessments`.
- `Hmis::MigrateAssessmentsJob.perform(data_source_id:, project_ids:, enrollment_ids:, upsert:, delete_dangling_records:, preferred_source_hash:, generate_empty_intakes:)`. Enqueued by `HmisCsvImporter::Importer::Importer#queue_hmis_assessment_migration` after an import into an HMIS data source with `upsert: true, generate_empty_intakes: true`.

## How it works

### Envelope and stages

`Hmis::Hud::CustomAssessment.new_with_defaults(enrollment:, user:, form_definition:)` copies `data_source_id`, `personal_id`, `enrollment_id` from the enrollment, sets `data_collection_stage` from `Hmis::Form::Definition::FORM_DATA_COLLECTION_STAGES[role]` (`INTAKE: 1, UPDATE: 2, EXIT: 3, ANNUAL: 5, POST_EXIT: 6, CUSTOM_ASSESSMENT: 99`), and builds the `form_processor`. The processor holds one FK per related HUD record; the model exposes them as `has_one ... through: :form_processor` (`income_benefit`, `exit`, `ce_assessment`, `ce_event`, six disability records, `clh_location`, others). `hud_assessment?` is true when the stage is a `HudHelper.util.data_collection_stages` key.

### Submission

`AssessmentInput#find_or_create_assessment` runs under `enrollment.with_lock`, loads the definition in the user's data source (`valid_status_for_submit?`), loads the assessment or enrollment through `viewable_by`, requires the enrollment policy's `can_edit?`, and refuses a second intake or exit per enrollment. `SubmitAssessment` assigns `values`/`hud_values` and `assessment_date`, runs `form_processor.run!`, validates with context `:form_submission`, collects form and processing validations, drops warnings when `confirmed`, and returns early on errors or `validate_only`. `save_submitted_assessment!` then, in one transaction: saves the processor, sets `wip: false`, enqueues `Hmis::AssessmentQuestionsJob` when a CE assessment was written, saves the enrollment, moves it out of WIP for an intake, releases the unit and closes the LINK referral for an exit, accepts the LINK referral for an intake.

### Household submission

`SubmitHouseholdAssessments` loads all ids through `viewable_by`, sets each `lock_version`, checks `can_edit?` on the first enrollment, and raises unless all share one `household_id` and one `data_collection_stage`. It applies household rules (HoH exit blocked while other members are open; exit blocked for WIP enrollments; non-HoH intake blocked while the HoH intake is WIP), runs every processor, validates each with `household_members:` so entry-date checks see unsaved sibling changes, then calls `save_submitted_assessment!` for each inside one `Hmis::Hud::CustomAssessment.transaction`. `SubmitAssessment` carries its own copy of those rules; both files flag the duplication with a FIXME pointing at `Hmis::Hud::Validators::CustomAssessmentValidator`.

### WIP records

`wip` is a boolean column set by `save_in_progress` / `save_not_in_progress`. `SaveAssessment` calls `save_submitted_assessment!(as_wip: true)`: the processor's `values` and `hud_values` persist, enrollment side effects are skipped. `Types::HmisSchema::Assessment#wip_values` returns them only while in progress; `upgraded_definition_for_editing` returns nil for WIP so the original form is used.

### Migration job

`Hmis::MigrateAssessmentsJob` walks `not_in_progress` enrollments in batches of 5,000. For each `RELATED_RECORDS` class (`IncomeBenefit`, `HealthAndDv`, `EmploymentEducation`, `YouthEducationStatus`, `Disability`, `Exit`) it groups rows by `enrollment_id, personal_id, data_collection_stage`, plus `information_date` for stages 2/5/6. Each group becomes one `CustomAssessment` (`wip: false`, earliest `DateCreated`, latest `DateUpdated`, `UserID` from the latest-updated row or the system user) and a `FormProcessor` pointing at the chosen rows; `Disability` fans out by `DisabilityType` into six columns. Duplicates pick the latest `date_updated` (or `preferred_source_hash`); the rest, and exit-stage rows on open enrollments, are soft-deleted when `delete_dangling_records`. Without `upsert` existing keys are skipped; with it, metadata and `FORM_PROCESSOR_HUD_COLUMNS` are reconciled in place and WIP assessments are skipped. `generate_empty_intakes` adds `build_synthetic_intake_assessment` for enrollments lacking one. Stage 99 rows are never touched.

## Key files

- `drivers/hmis/app/models/hmis/hud/custom_assessment.rb:19` class; `:69` `in_progress`/stage scopes; `:77` `with_role`; `:108` `save_in_progress`; `:172` `save_submitted_assessment!` (enrollment side effects, LINK hooks); `:206` `new_with_defaults`; `:221` `group_household_assessments`; `:262` `deletion_would_cause_conflicting_enrollments?`.
- `drivers/hmis/app/models/hmis/hud/assessment.rb:10` `Hmis::Hud::Assessment` (CE); `:30` `assessment_questions`, `assessment_results`.
- `drivers/hmis/app/models/hmis/hud/validators/custom_assessment_validator.rb:23` `validate_assessment_date` (future, >20 years, before entry, after exit, duplicate annual/update warnings).
- `drivers/hmis/app/graphql/mutations/submit_assessment.rb:44` `resolve`; `:54` FIXME on duplicated household rules; `:116` save.
- `drivers/hmis/app/graphql/mutations/submit_household_assessments.rb:41` same-household check; `:45` same-stage check; `:53` FIXME; `:124` single transaction.
- `drivers/hmis/app/graphql/mutations/save_assessment.rb:23` `supports_save_in_progress?` guard; `:43` `as_wip: true`.
- `drivers/hmis/app/graphql/types/hmis_schema/assessment_input.rb:20` `find_or_create_assessment` under `with_lock`; `:54` second intake/exit refusal; `:67` `new_with_defaults`.
- `drivers/hmis/app/graphql/types/hmis_schema/assessment.rb:35` "object is a Hmis::Hud::CustomAssessment"; `:44` `access_field` (one `bool_field`, three deprecated `can`); `:76` `role`; `:81` `definition` (expensive); `:96` `upgraded_definition_for_editing`; `:176` `form_processor` raises when missing.
- `drivers/hmis/app/graphql/types/hmis_schema/ce_assessment.rb:10` `CeAssessment` wraps `Hmis::Hud::Assessment`; `:32` `form_definition_id` via `form_processor`.
- `drivers/hmis/app/graphql/types/hmis_schema/has_assessments.rb:15` `assessments_field`; `:36` `scoped_assessments`.
- `drivers/hmis/app/jobs/hmis/migrate_assessments_job.rb:27` `RELATED_RECORDS`; `:39` disability column map; `:86` `perform`; `:155` `build_assessments`; `:280` WIP skip on upsert; `:326` write transaction; `:339` `generate_empty_intakes`.

## Gotchas

- Naming inversion: GraphQL `Assessment` is `Hmis::Hud::CustomAssessment`; GraphQL `CeAssessment` is `Hmis::Hud::Assessment`. The `Assessment.ceAssessment` field is the CE record the custom assessment's form wrote. In code comments "HUD assessment" usually means a stage 1/2/3/5/6 `CustomAssessment`, not a row in HUD `Assessment.csv`.
- A household submit touches every member's enrollment in one transaction: each `save_submitted_assessment!` saves the enrollment, may flip it out of WIP, release a unit, and call LINK `accept_referral!` / `close_referral!`. A failure on the last member rolls back all of them; external LINK calls that already ran do not roll back.
- Every `CustomAssessment` must have a `FormProcessor`; `Types::HmisSchema::Assessment#form_processor` raises otherwise. Build with `new_with_defaults` or `build_form_processor`.
- `Assessment.definition` and `upgradedDefinitionForEditing` are marked expensive (`find_definition_for_role` fallback for migrated rows); do not request them in list queries.
- Migrated assessments have no definition on the processor; the type falls back to `find_definition_for_role`. Submitted assessments edit with the newest published version of a retired form (`hmis/forms.md`), WIP ones keep the original.
- Stage scopes hard-code 1/2/3/5/6 while `hud_assessment?` reads `HudHelper.util.data_collection_stages`; keep both in sync if HUD adds a stage.
- `AssessmentInput#find_or_create_assessment` refuses a second intake or exit per enrollment; `SubmitAssessment` allows re-submitting an existing one (`has_already_been_submitted` skips the HoH checks).
- Deleting a submitted exit assessment can leave two open enrollments in one project; `deletion_would_cause_conflicting_enrollments?` detects it.
- `MigrateAssessmentsJob` with `upsert: true` (the importer default) resets `FORM_PROCESSOR_HUD_COLUMNS` before reapplying, so a HUD record deleted upstream is unlinked, but custom data element and definition references are untouched. `project_ids` and `enrollment_ids` are row pks, not HUD IDs, and are mutually exclusive.
- `SubmitHouseholdAssessments` checks `can_edit?` on the first enrollment only; it relies on all enrollments sharing a household in the user's data source.

## Do not repeat

Repo-wide entries: `conventions/do-not-repeat.md` 13 (`BaseMutation`, which all three assessment mutations still extend) and 14 (raw-permission access helpers).

- A third copy of the household business rules (HoH exit with open members, exit of a WIP enrollment, non-HoH intake before the HoH intake). Two copies exist: `drivers/hmis/app/graphql/mutations/submit_assessment.rb:54` and `drivers/hmis/app/graphql/mutations/submit_household_assessments.rb:53`, each with a FIXME. Instead: add the rule to `Hmis::Hud::Validators::CustomAssessmentValidator` (`drivers/hmis/app/models/hmis/hud/validators/custom_assessment_validator.rb`) so both mutations pick it up through `validates_with`.
- Exposing `Hmis::Hud::Assessment` as a GraphQL type or field named `Assessment`, or wrapping `CustomAssessment` in anything named `CeAssessment`. Instead: `Types::HmisSchema::CeAssessment` (`drivers/hmis/app/graphql/types/hmis_schema/ce_assessment.rb`) for the HUD CE record, `Types::HmisSchema::Assessment` for the envelope.
- `can :x` inside `access_field` (`drivers/hmis/app/graphql/types/hmis_schema/assessment.rb:49`, three deprecated entries). Instead: `bool_field(:can_x) { policy.can_x? }` as at `:47`; see `authorization/hmis-graphql-authorization.md`.
- Creating a `CustomAssessment` without a `FormProcessor` (a data migration that inserts envelopes alone). Instead: `Hmis::Hud::CustomAssessment.new_with_defaults` (`drivers/hmis/app/models/hmis/hud/custom_assessment.rb:206`) or let `Hmis::MigrateAssessmentsJob` build both.

## Related

- `hmis/forms.md`: form definitions, `FormProcessor`, field processors, definition resolution and the retired-form upgrade.
- `hmis/data-model.md`: `Hmis::Hud::*` base classes, `hmis_relation`, data-source scoping.
- `hud-reporting/hud-utility-versions.md`: `HudHelper.util` and data collection stage codes.
- `authorization/hmis-graphql-authorization.md`: `viewable_by`, `access_field`, `bool_field` vs deprecated `can`.
- `docs/features/hmis/hmis-assessments.md`: human-facing walkthrough with UI paths and the custom-CE-assessment JSON example.
