# HMIS form processing

What happens between a user pressing Submit and data landing in database records. The central class is `Hmis::Form::FormProcessor`, which is both an ActiveRecord model (table `hmis_form_processors`) and the engine that turns a submitted payload into HUD records.

Out of scope here:

- Statuses and roles — [Form definitions](hmis-form-definitions.md)
- Form rules and which definition applies — [Form resolution](hmis-form-resolution.md)
- The shape of the definition JSON, including `mapping`, `link_id`, and pick lists — [HMIS form authoring](hmis-form-authoring.md)
- Loading definitions from JSON files on disk — [HMIS form seeding](hmis-form-seeding.md)

## Overview

Every submission path converges on the same sequence.

1. **Resolve the definition**, by ID, scoped to the user's data source. It must have a submittable status.
2. **Find or build the owner record** — the primary record the form is about: a `Client`, `Project`, `CustomAssessment`, and so on. For creates, `SubmitFormRecordInitializer` builds an unsaved record and resolves associations from the input.
3. **Authorize.** `SubmitFormAuthorizer` checks a policy chosen by owner class and action.
4. **Attach the payload.** The owner's `FormProcessor` is found or built, pointed at the definition, and given both `values` and `hud_values`.
5. **Validate the form values** against the definition: required fields, numeric formats, warnings.
6. **Run the processor.** `run!` assigns attributes onto in-memory records. Nothing is saved yet.
7. **Validate the records** — ActiveRecord validations plus HMIS validator classes.
8. **Return early on errors**, or save. The mutation saves the owner, then the `FormProcessor`, which autosaves the related HUD records.

Steps 5 through 8 happen inside one transaction.

## Submission approaches

There is no single submit mutation. Which one the front-end calls depends on the form's role.

| Approach | Mutation | Owner | Uses `FormProcessor` |
| --- | --- | --- | --- |
| Record forms | `SubmitForm` | Whatever `FORM_ROLE_CONFIG` says for the role | Yes |
| Assessments | `SubmitAssessment`, `SaveAssessment` | `Hmis::Hud::CustomAssessment` | Yes |
| Household assessments | `SubmitHouseholdAssessments` | Several `CustomAssessment`s at once | Yes |
| CE referral steps | `Ce::SubmitCeReferralStep` | `Hmis::WorkflowExecution::Step` | Yes |
| Static admin forms | Bespoke mutations per role | The config record itself | No |

**Record forms** are the general case, and the only path that runs the record initializer and the authorizer. It is also the only one that validates against a role-specific validation context in addition to `:form_submission`.

**Assessments** skip both of those classes. The owner is always a `CustomAssessment`, so authorization reduces to an enrollment `can_edit?` check while finding or creating the assessment. In exchange, `SubmitAssessment` carries assessment-specific business rules no other path has: head-of-household exit constraints, non-HoH intake constraints, and a block on exiting an incomplete enrollment. Saving goes through `CustomAssessment#save_submitted_assessment!`, which also saves the enrollment, flips it out of work-in-progress on intake, releases units on exit, and fires referral integrations.

**Household assessments** submit for several household members together, re-running the per-assessment validation loop with `household_members:` passed into `collect_processing_validations` so unsaved entry and exit dates on sibling enrollments are visible to date validation. It does not accept `values`/`hud_values`; it processes what each assessment's `FormProcessor` already holds from a prior save.

**CE referral steps** build a `FormProcessor` on a workflow step, run it to produce Custom Data Elements, and hand off to the workflow engine. Validation comes from the engine rather than `collect_form_validations`.

**Static forms** — use a definition only to render the admin UI. Their mutations assign input straight onto the config record and never touch a `FormProcessor`. Nothing below applies to them.

**External forms** are a fifth path: `HmisExternalApis::ExternalForms::FormSubmission` runs the processor at review time and deliberately skips both validation phases, because the submitter is long gone and cannot fix anything.

## `values` and `hud_values`

A submission carries the same answers twice, in two differently keyed JSON blobs, both stored on `hmis_form_processors` as `jsonb`.

| | `values` | `hud_values` |
| --- | --- | --- |
| Keyed by | `link_id` | `Container.fieldName`, or bare `fieldName` |
| Example | `{"firstName": "Example"}` | `{"Client.firstName": "Example"}` |
| Used for | Validating against the definition; finding the assessment date; re-rendering | Writing to the database |

Form validation and assessment-date lookup read `values`. Everything in `run!` reads `hud_values`. The front-end computes `hud_values` from the definition's `mapping` before submitting; the server does not derive one from the other.

## Container processors

`run!` splits `hud_values` into containers, then routes each field to a processor.

**Routing.** `hud_values_by_container` turns `{"HealthAndDv.field1" => nil}` into `{"HealthAndDv" => {"field1" => nil}}`. A key with no dot belongs to the owner's own container, named after the owner class with two exceptions: `Hmis::Hud::Assessment` becomes `CeAssessment`, and `Hmis::WorkflowExecution::Step` becomes `WorkflowStep`. The container name maps to a processor class through the frozen `valid_containers` hash in `FormProcessor`; consult that hash rather than any list reproduced elsewhere. `Hmis::Form::RecordType` is the other half of the mapping, translating a definition's `mapping.record_type` into the same container name.

**The definition is the allowlist.** `mapped_record_form_fields` and `mapped_custom_form_fields` walk the definition's items and collect, per container, the `field_name`s and `custom_field_key`s it declares. A submission can only write what its definition declares.

### Name translation

`Hmis::Hud::Processors::Base#process` does the whole translation in a few lines, and the name path has three hops:

1. **GraphQL camelCase to AR attribute.** `ar_attribute_name` is `field.underscore`, so `veteranStatus` becomes `veteran_status`.
2. **AR attribute to HUD column.** The HUD models alias every CSV column to its snake_case form — `HmisStructure::Shared` iterates the HMIS CSV configuration for each supported spec year and calls `alias_attribute`, so `veteran_status` resolves to `VeteranStatus`. `Hmis::Hud::Base.alias_to_underscore` does the same for a few common fields and for non-CSV models.
3. **Value translation.** `graphql_enum` looks the field up on the subclass's `schema` — the GraphQL type for that record — and returns the enum type if the field is one. `attribute_value_for_enum` then converts:

| Input | Stored |
| --- | --- |
| `'CLIENT_PREFERS_NOT_TO_ANSWER'` | `9` |
| `['PH', 'ES_NBN']` | `[10, 1]` |
| `nil` or `''` | the enum's data-not-collected value, usually `99` |
| `'_HIDDEN'` | `nil` |
| anything with no enum | passed through unchanged |

`'_HIDDEN'` is `Base::HIDDEN_FIELD_VALUE`, the sentinel the front-end sends for a question that `enable_when` hid. Interpreting it centrally means hiding a question clears the underlying column. Some processors special-case it, notably `ClientProcessor` for SSN and DOB, which are hidden for lack of permission rather than by conditional logic and so must be left alone.

The record being assigned comes from `factory_name`, a method on the `FormProcessor` that finds or builds the record and stores it on the association. Subclasses supply only `factory_name`, `relation_name`, and `schema`; `HealthAndDvProcessor` is the minimal example. They override `process` when a field is not a simple column assignment — `ClientProcessor` fans race and gender out to individual HUD columns and builds nested name, address, and contact records; `IncomeBenefitProcessor` forces dependent income fields to match the overarching "from any source" answer; `DisabilityGroupProcessor` routes one container across six disability factories; etc.

After every field is assigned, `run!` makes a second pass to call `assign_metadata`, `information_date`, and `post_process` on each processor. `assign_metadata` sets the HUD user and data source; `information_date` stamps the assessment date onto related records; `post_process` is where cross-field work lands, such as `ClientProcessor` reconciling `RaceNone`/`GenderNone`.

### Custom data elements

A field mapped with `custom_field_key` goes to `process_custom_field`. The processor looks up the `CustomDataElementDefinition` by key and owner type, normalizes the value against the definition's `field_type`, then builds `custom_data_elements_attributes` on the record — updating a single-valued element in place, or diffing submitted against existing values for a repeating one. The elements save when the owner saves. An unknown key raises.

The definitions themselves are created at form-authoring time by `Hmis::Form::CustomDataElementGenerator`, not at submission time. By the time a form is submitted, every `custom_field_key` in it is expected to exist.

## Validation

Three phases run in order, and they answer different questions.

| Phase | Method | Reads | Catches |
| --- | --- | --- | --- |
| Form validation | `collect_form_validations` | `values` | Missing required answers, numeric format, empty-but-expected warnings |
| Record validation | `record.valid?(...)` | in-memory records | ActiveRecord validations on the owner |
| Processing validation | `collect_processing_validations` | in-memory records | AR errors as user-facing errors, assessment date rules, HMIS validator classes, errors raised by processors |

### Who enforces what

Much of a form definition is interpreted only in the browser. The server is a genuine second line of defense for some properties and no defense at all for others, so do not assume a valid submission implies the client honored the definition.

| Property | Client | Server |
| --- | --- | --- |
| `required` | Blocks submit | Re-checked in phase one |
| Numeric format, `INTEGER` / `CURRENCY` | Input type only | Re-checked by `NumericInputValidator` |
| `bounds` | Sets the input's `min` / `max` | Only bounds with a literal `value_number` and non-warning severity; bounds against another question or a local constant are **not** checked |
| `enable_when` visibility | Authoritative | Never re-evaluated. The server trusts the omission, or `_HIDDEN` for a mapped field |
| `autofill_values`, `initial` | Computed continuously | Never recomputed |
| Item-level `data_collected_about` | Applied per client for household assessments | Not applied; the full definition is returned |
| Pick list answer codes | Renders the options | Checked when the form is published, not on submit |

So the shape of a submission is decided client-side. A caller that is not the HMIS front-end — a script, a test, a hand-built payload — can write values for questions the definition would have hidden, with only ActiveRecord validations in the way.

## Work-in-progress assessments

Only assessment roles can be saved in progress, and only if the form contains no `FILE` or `IMAGE` item.

`SaveAssessment` assigns `values` and `hud_values` onto the `FormProcessor` and saves with `as_wip: true`. It never calls `run!`. The answers exist solely as JSON in the two columns: no `IncomeBenefit`, `HealthAndDv`, `Exit`, or other related record has been created, and none of the `*_id` columns on `hmis_form_processors` are populated. On this path `save_submitted_assessment!` saves the processor and marks the assessment `wip: true`.

Two consequences:

- WIP answers are invisible to reporting, HUD exports, and any query against HUD tables. They are searchable only as JSON.
- Warnings do not gate a WIP save, and required-field validation does not run at all. A half-finished assessment saves cleanly.

When the assessment is finally submitted, the front-end re-sends the full payload and `SubmitAssessment` runs the processor for the first time, creating all the related records at once.

## Footguns

**Empty and hidden are not the same.** Empty becomes the data-not-collected value when the field has an enum type; hidden becomes `nil`. Adding an `enable_when` that hides an already-populated question will null the column on the next submission.

**Enrollment is not one of the processor's associations.** It is reached through `enrollment_factory`, which infers it from the owner, so `form_processor.save!` does not save it. Every caller has to save the enrollment itself, and a new submission path that forgets will silently drop enrollment changes.

**`editor_user_ids` skips silently.** When an item restricts editing to specific users, a submission from anyone else has that field dropped with no error and no record of the attempt. The front-end sends all values regardless, so raising would break legitimate submissions — but the user sees a successful save that did not save their edit.

**Hiding every field of a container can delete a record.** On a `CustomAssessment`, if all of a container's fields arrive as `_HIDDEN` and its processor is `dependent_destroyable?`, the related record is destroyed rather than updated. Only a few processors opt in — CE event, CE assessment, current living situation, and geolocation. This is how a conditionally collected record disappears when its condition goes false, and how one gets deleted unintentionally by an `enable_when` change.

**`collect_processing_validations` does not run every relevant validator.** It picks the validator off each *related* record, in the context of the definition's role, so an enrollment form that also creates a client will not run the client validator.

**Two mutations duplicate household business rules.** `SubmitAssessment` and `SubmitHouseholdAssessments` each carry their own copy of the HoH exit and non-HoH intake checks.

## Related

- [Form definitions](hmis-form-definitions.md) — the definition model, roles, and the status lifecycle
- [Form resolution](hmis-form-resolution.md) — form rules, and which definition is used for a new or existing record
- [HMIS form authoring](hmis-form-authoring.md) — the definition JSON, including `mapping`
- [HMIS form seeding](hmis-form-seeding.md) — loading definitions from disk
- [HMIS assessments](hmis-assessments.md) — what the assessment record types are
- [HMIS auth policies](hmis-auth-policies.md) — the policies `SubmitFormAuthorizer` consults
