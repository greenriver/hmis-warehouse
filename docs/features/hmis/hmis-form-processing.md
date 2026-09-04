# HMIS form processing

What happens between a user pressing Submit and data landing in database records. The central class is `Hmis::Form::FormProcessor`, which is both an ActiveRecord model (table `hmis_form_processors`) and the engine that turns a submitted payload into HUD records.

Out of scope here:

- Statuses and roles — [Form definitions](hmis-form-definitions.md)
- Form rules and which definition applies — [Form resolution](hmis-form-resolution.md)
- The shape of the definition JSON, including `mapping`, `link_id`, and pick lists — [HMIS form authoring](hmis-form-authoring.md)
- Loading definitions from JSON files on disk — [HMIS form seeding](hmis-form-seeding.md)

## Overview

Every submission path converges on the same sequence.

1. **Resolve the definition.** Looked up by ID and scoped to the user's data source. Must have a submittable status (`submit_form.rb:28-30`).
2. **Find or build the owner record.** The "owner" is the primary record the form is about: a `Client`, `Project`, `CustomAssessment`, and so on. For creates, `Hmis::Form::SubmitFormRecordInitializer` builds an unsaved record and resolves associations from the input (`submit_form_record_initializer.rb:79-100`).
3. **Authorize.** `Hmis::Form::SubmitFormAuthorizer` checks a policy chosen by owner class and action (`submit_form_authorizer.rb:30-89`).
4. **Attach the payload.** The owner's `FormProcessor` is found or built, pointed at the definition, and given both `values` and `hud_values` (`submit_form.rb:45-48`).
5. **Validate the form values** against the definition — required fields, numeric formats, warnings (`form_processor.rb:542-544`).
6. **Run the processor.** `run!` assigns attributes onto in-memory records. Nothing is saved yet (`form_processor.rb:76-132`).
7. **Validate the records.** ActiveRecord validations plus HMIS validator classes (`form_processor.rb:552-579`).
8. **Return early on errors**, or save. The mutation saves the owner, then the `FormProcessor`, which autosaves the related HUD records (`submit_form.rb:66-97`).

Steps 5 through 8 all happen inside one transaction (`submit_form.rb:18-22`).

## Submission approaches

There is no single submit mutation. Which one the front-end calls depends on the form's role.

| Approach | Mutation | Owner | Uses `FormProcessor` |
| --- | --- | --- | --- |
| Record forms | `SubmitForm` | Whatever `FORM_ROLE_CONFIG` says for the role | Yes |
| Assessments | `SubmitAssessment`, `SaveAssessment` | `Hmis::Hud::CustomAssessment` | Yes |
| Household assessments | `SubmitHouseholdAssessments` | Several `CustomAssessment`s at once | Yes |
| CE referral steps | `Ce::SubmitCeReferralStep` | `Hmis::WorkflowExecution::Step` | Yes |
| Static admin forms | Bespoke mutations per role | The config record itself | No |

**Record forms** (`submit_form.rb`) are the general case. `SubmitForm` derives the owner class from the definition's role, builds or finds the record, authorizes, processes, and saves. It is the only path that runs the record initializer and the authorizer, and the only one that validates against a role-specific validation context in addition to `:form_submission` (`submit_form.rb:58`).

**Assessments** (`submit_assessment.rb`) skip both of those classes. The owner is always a `CustomAssessment`, so authorization is a single enrollment `can_edit?` check performed while finding or creating the assessment (`assessment_input.rb:49`). In exchange, `SubmitAssessment` carries assessment-specific business rules that no other path has: head-of-household exit constraints, non-HoH intake constraints, and a block on exiting an incomplete enrollment (`submit_assessment.rb:56-82`). Saving is delegated to `CustomAssessment#save_submitted_assessment!`, which also saves the enrollment, flips the enrollment out of work-in-progress on intake, releases units on exit, and fires referral integrations (`custom_assessment.rb:172-200`).

**Household assessments** (`submit_household_assessments.rb`) submit assessments for multiple household members together. It re-runs the same per-assessment validation loop, but passes `household_members:` into `collect_processing_validations` so that unsaved entry and exit dates on sibling enrollments are visible to date validation (`submit_household_assessments.rb:98-105`). Note that it does not accept `values`/`hud_values`; it processes what is already stored on each assessment's `FormProcessor` from a prior save. Both assessment mutations support `validate_only`, which runs everything and returns without saving.

**CE referral steps** (`ce/submit_ce_referral_step.rb`) build a `FormProcessor` on a workflow step, run it to produce Custom Data Elements, and hand off to the workflow engine to complete the step. Validation comes from the engine, not from `collect_form_validations` (`submit_ce_referral_step.rb:42-53`).

**Static forms** — `FORM_RULE`, `PROJECT_CONFIG`, `CLIENT_ALERT`, `FORM_DEFINITION` — use a form definition only to render the admin UI. Their mutations assign input straight onto the config record and never touch a `FormProcessor` (`create_form_rule.rb:20-33`, `create_project_config.rb:23-31`). Nothing in this document after this point applies to them.

**External forms** are a fifth path. `HmisExternalApis::ExternalForms::FormSubmission` runs the processor at review time, deliberately skipping both validation phases because the submitter is long gone and cannot fix anything (`form_submission.rb:141-148`).

## `values` and `hud_values`

A submission carries the same answers twice, in two differently keyed JSON blobs. Both are stored on `hmis_form_processors` as `jsonb`.

| | `values` | `hud_values` |
| --- | --- | --- |
| Keyed by | `link_id` | `Container.fieldName`, or bare `fieldName` |
| Example | `{"ssn": "123456789"}` | `{"Client.ssn": "123456789"}` |
| Used for | Validating against the definition; finding the assessment date; re-rendering | Writing to the database |

`collect_form_validations` and `find_assessment_date_from_values` read `values` (`form_processor.rb:502-510`, `540-544`). Everything in `run!` reads `hud_values`. If `hud_values` is blank, `run!` returns immediately and no record is touched (`form_processor.rb:81`).

The front-end computes `hud_values` from the definition's `mapping` before submitting; the server does not derive one from the other.

## Container processors

`run!` splits `hud_values` into containers, then routes each field to a processor.

### Routing

`hud_values_by_container` turns `{"HealthAndDv.field1" => nil, "IncomeBenefit.field1" => 3}` into `{"HealthAndDv" => {"field1" => nil}, "IncomeBenefit" => {"field1" => 3}}` (`form_processor.rb:138-146`). A key with no dot belongs to the owner's own container, named after the owner class with two exceptions: `Hmis::Hud::Assessment` becomes `CeAssessment`, and `Hmis::WorkflowExecution::Step` becomes `WorkflowStep` (`form_processor.rb:156-177`).

The container name maps to a processor class through the frozen `valid_containers` hash (`form_processor.rb:401-435`). There are 27 entries pointing at the classes in `drivers/hmis/app/models/hmis/hud/processors/`; consult that hash rather than reproducing it. `Hmis::Form::RecordType` is the other half of the mapping: it translates a definition's `mapping.record_type` (for example `HEALTH_AND_DV`) into the same container name (`record_type.rb:22-85`, `form_processor.rb:646-655`).

Each field must be recognized before it is processed. `mapped_record_form_fields` and `mapped_custom_form_fields` walk the definition's items and collect, per container, the set of `field_name`s and `custom_field_key`s it declares (`form_processor.rb:599-627`). A field in the first set goes to `process`; a field in the second goes to `process_custom_field`; anything else raises (`form_processor.rb:98-106`). The definition's mappings are, in effect, the allowlist for what a submission may write.

### The base processor and name translation

`Hmis::Hud::Processors::Base#process` is three lines and does the whole translation (`base.rb:24-29`):

```ruby
def process(field, value)
  attribute_name = ar_attribute_name(field)
  attribute_value = attribute_value_for_enum(graphql_enum(field), value)

  @processor.send(factory_name)&.assign_attributes(attribute_name => attribute_value)
end
```

The name path has three hops:

1. **GraphQL camelCase to AR attribute.** `ar_attribute_name` is `field.underscore`, so `veteranStatus` becomes `veteran_status` (`base.rb:62-64`).
2. **AR attribute to HUD column.** The HUD models alias every CSV column to its snake_case form. `HmisStructure::Shared` iterates the HMIS CSV configuration for each supported spec year and calls `alias_attribute col.underscore, col`, so `veteran_status` resolves to `VeteranStatus` (`shared.rb:15-25`). `Hmis::Hud::Base.alias_to_underscore` does the same for a few common fields and for non-CSV models (`base.rb:75-82`).
3. **Value translation.** `graphql_enum(field)` looks the field up on the subclass's `schema` — the GraphQL type for that record, such as `Types::HmisSchema::HealthAndDv` — and returns the enum type if the field is one (`base.rb:67-91`). `attribute_value_for_enum` then converts (`base.rb:100-117`):

| Input | Stored |
| --- | --- |
| `'CLIENT_PREFERS_NOT_TO_ANSWER'` | `9` |
| `['PH', 'ES_NBN']` | `[10, 1]` |
| `nil` or `''` | the enum's data-not-collected value, usually `99` |
| `'_HIDDEN'` | `nil` |
| anything with no enum | passed through unchanged |

`'_HIDDEN'` is `Base::HIDDEN_FIELD_VALUE`, the sentinel the front-end sends for a question that `enable_when` hid (`base.rb:15-16`). Interpreting it is centralized in `attribute_value_for_enum`, so hiding a question clears the underlying column. Several processors special-case that, notably `ClientProcessor` for SSN and DOB, which are hidden for lack of permission rather than by conditional logic and so must be left alone (`client_processor.rb:19-20`, `33-40`).

The record being assigned comes from `factory_name`, a method on the `FormProcessor` that finds or builds the record and stores it on the association — `health_and_dv_factory`, `income_benefit_factory`, and so on (`form_processor.rb:265-384`). Subclasses supply only `factory_name`, `relation_name`, and `schema`; `HealthAndDvProcessor` is 23 lines and typical (`health_and_dv_processor.rb`).

Subclasses override `process` when a field is not a simple column assignment. Examples: `ClientProcessor` fans race and gender out to individual HUD columns and builds nested name, address, and contact records; `IncomeBenefitProcessor` forces dependent income fields to match the overarching "from any source" answer (`income_benefit_processor.rb:39-92`); `DisabilityGroupProcessor` routes one container across six different disability factories (`disability_group_processor.rb:52-75`); `GeolocationProcessor` parses coordinates and destroys the location record when they are absent.

### Metadata and the second pass

After every field is assigned, `run!` makes a second pass over the containers to call `assign_metadata`, `information_date`, and `post_process` on each processor (`form_processor.rb:114-129`). `assign_metadata` sets the HUD user and data source; `information_date` stamps the assessment date onto related records. `post_process` is where cross-field work lands, such as `ClientProcessor` reconciling `RaceNone`/`GenderNone` and `CustomAssessmentProcessor` recalculating the Alt-AHA score to confirm the submitted one is still current.

Finally, if the owner is a `CustomAssessment`, its enrollment is reattached so the mutation can save it (`form_processor.rb:131`).

### Custom data elements

A field mapped with `custom_field_key` goes to `process_custom_field` (`base.rb:146-201`). The processor looks up the `CustomDataElementDefinition` by key and owner type, normalizes the value against the definition's `field_type`, then builds `custom_data_elements_attributes` on the record — updating a single-valued element in place, or diffing submitted against existing values for a repeating one. The elements save when the owner record saves, via `accepts_nested_attributes_for` in `Hmis::Hud::Concerns::FormSubmittable` (`form_submittable.rb:17-22`). An unknown key raises.

The definitions themselves are created at form-authoring time, not at submission time, by `Hmis::Form::CustomDataElementGenerator` (`custom_data_element_generator.rb:43-102`). By the time a form is submitted, every `custom_field_key` in it is expected to already exist.

## Validation

Three phases run in order, and they answer different questions.

| Phase | Method | Reads | Catches |
| --- | --- | --- | --- |
| Form validation | `collect_form_validations` | `values` | Missing required answers, numeric format, empty-but-expected warnings |
| Record validation | `record.valid?(...)` | in-memory records | ActiveRecord validations on the owner and, via `hmis_records_are_valid`, on every related record |
| Processing validation | `collect_processing_validations` | in-memory records | AR errors as user-facing errors, assessment date rules, HMIS validator classes, errors raised by processors |

Phase one delegates to `Hmis::Form::Definition#validate_form_values`, which walks the definition in order so errors come back sorted the way the form reads (`definition.rb:476-518`). Phase three collects ActiveRecord errors, filtering out ID fields, relation errors, and information-date errors on assessments, then adds `CustomAssessmentValidator` date checks and any `Hmis::Hud::Validators::BaseValidator` results for the current role (`form_processor.rb:514-579`).

Processors can contribute to phase three directly by calling `add_processing_error` (`form_processor.rb:58-62`). The Alt-AHA score check is the example in the tree.

### Who enforces what

Much of a form definition is interpreted only in the browser. The server is a genuine second line of defense for some properties and no defense at all for others, so do not assume that a valid submission implies the client honored the definition.

| Property | Client | Server |
| --- | --- | --- |
| `required` | Blocks submit | Re-checked in phase one (`definition.rb:476-518`) |
| Numeric format, `INTEGER` / `CURRENCY` | Input type only | Re-checked by `NumericInputValidator` |
| `bounds` | Sets the input's `min` / `max` | Only bounds with a literal `value_number` and non-warning severity; bounds against another question or a local constant are **not** checked (`numeric_input_validator.rb:44-45`) |
| `enable_when` visibility | Authoritative | Never re-evaluated. The server trusts the omission, or `_HIDDEN` for a mapped field |
| `autofill_values`, `initial` | Computed continuously | Never recomputed |
| Item-level `data_collected_about` | Applied per client for household assessments | Not applied; the full definition is returned |
| Pick list answer codes | Renders the options | Checked when the form is published, not on submit |

The practical consequence is that the shape of a submission is decided client-side. A caller that is not the HMIS front-end — a script, a test, or a hand-built payload — can write values for questions the definition would have hidden, and only ActiveRecord validations stand in the way.

### Warnings and `confirmed`

Every error carries a `severity`, defaulting to `:error` (`error.rb:11`). Warnings come from two places: an item with `warn_if_empty` that was left blank or answered "data not collected" (`definition.rb:507-508`), and HMIS validator classes that flag a value as suspicious but legal.

The front-end shows warnings in a confirmation dialog. If the user accepts them, it resubmits with `confirmed: true`, and the mutation calls `errors.drop_warnings!` before deciding whether to abort (`submit_form.rb:64`, `submit_assessment.rb:109`, `submit_household_assessments.rb:109`). Errors converted from ActiveRecord are always `:error` and can never be confirmed away (`error.rb:60`).

`deduplicate!` runs last, preferring the copy of an error that carries a `link_id` because it has more context for the UI (`errors.rb:53-65`).

## Work-in-progress assessments

Only assessment roles can be saved in progress, and only if the form contains no `FILE` or `IMAGE` item (`definition.rb:430-438`).

`SaveAssessment` assigns `values` and `hud_values` onto the `FormProcessor`, validates only the assessment date, and saves with `as_wip: true` (`save_assessment.rb:27-43`). It never calls `run!`. The answers exist solely as JSON in the two columns; no `IncomeBenefit`, `HealthAndDv`, `Exit`, or other related record has been created, and none of the `*_id` columns on `hmis_form_processors` are populated (`form_processor.rb:9-11`).

That is the whole difference between a WIP and a submitted assessment. On the WIP save path, `save_submitted_assessment!` saves the processor and marks the assessment `wip: true`, skipping the enrollment save, the CE assessment questions job, and all the intake and exit side effects (`custom_assessment.rb:172-200`).

Two consequences worth internalizing:

- WIP answers are invisible to reporting, HUD exports, and any query against HUD tables. They are searchable only as JSON.
- Warnings do not gate a WIP save, and required-field validation does not run at all. A half-finished assessment saves cleanly.

When the assessment is finally submitted, the front-end re-sends the full payload and `SubmitAssessment` runs the processor for the first time, creating all the related records at once.

## Footguns

**An unmapped `hud_values` key is a 500.** Any field not declared in the definition's mappings raises (`form_processor.rb:105`). A front-end that caches a definition across a form change, or a hand-written payload, produces a server error rather than a validation error.

**An unrecognized container also raises, despite appearances.** `container_processor` looks like it degrades gracefully in production — it captures a Sentry message and returns `nil` (`form_processor.rb:389-395`) — but the only caller in the field loop raises immediately on a nil processor (`form_processor.rb:90`). Since the metadata loop iterates the same container set, the production fallback is unreachable. Treat an invalid container as fatal in every environment.

**`editor_user_ids` skips silently.** When an item restricts editing to specific users, a submission from anyone else has that field dropped with no error and no record of the attempt (`form_processor.rb:92-96`). The comment explains why: the front-end sends all values regardless, so raising would break legitimate submissions. The user sees a successful save that did not save their edit.

**Hiding every field of a container can delete a record.** On a `CustomAssessment`, if all of a container's fields came in as `_HIDDEN` and its processor is `dependent_destroyable?`, the related record is destroyed rather than updated (`form_processor.rb:118-122`, `150-154`). Only four processors opt in: CE event, CE assessment, current living situation, and geolocation. This is how a conditionally collected record disappears when its condition goes false — and how one gets deleted unintentionally by an `enable_when` change.

**Empty and hidden are not the same.** Empty becomes `99` when the field has an enum type, hidden becomes `nil` (`base.rb:100-117`). Adding an `enable_when` that hides an already-populated question will null the column on the next submission.

**Enrollment is not one of the processor's associations.** It is reached through `enrollment_factory`, which infers it from the owner (`form_processor.rb:214-233`), so `form_processor.save!` does not save it. Every caller has to save the enrollment itself (`submit_form.rb:92-97`, `custom_assessment.rb:187-189`). A new submission path that forgets this will silently drop enrollment changes.

**A form that submits only `values` writes nothing.** `run!` returns early when `hud_values` is blank (`form_processor.rb:81`), without error.

**`collect_processing_validations` does not run every relevant validator.** It picks the validator off each *related* record, in the context of the definition's role. An enrollment form that also creates a client will not run the client validator, as the TODO in the code says (`form_processor.rb:564-572`).

**Two mutations duplicate household business rules.** `SubmitAssessment` and `SubmitHouseholdAssessments` each carry their own copy of the HoH exit and non-HoH intake checks, with slightly different wording, and both are marked `FIXME` to move into `CustomAssessmentValidator` (`submit_assessment.rb:54`, `submit_household_assessments.rb:53`).

## Related

- [Form definitions](hmis-form-definitions.md) — the definition model, roles, and the status lifecycle
- [Form resolution](hmis-form-resolution.md) — form rules, and which definition is used for a new or existing record
- [HMIS form authoring](hmis-form-authoring.md) — the definition JSON, including `mapping`
- [HMIS form seeding](hmis-form-seeding.md) — loading definitions from disk
- [HMIS assessments](hmis-assessments.md) — what the assessment record types are
- [HMIS auth policies](hmis-auth-policies.md) — the policies `SubmitFormAuthorizer` consults
