# HMIS form authoring

How to build the JSON structure of a form definition — the `definition` blob itself.

The authoritative source for what is *allowed* is the JSON schema at `drivers/hmis_external_apis/public/schemas/form_definition.json`. What is *rejected*, and with what message, is `Hmis::Form::DefinitionValidator`. When this doc disagrees with either, they win. Both run on publish and on seed, so most malformed JSON fails loudly and early; this doc does not enumerate what they already catch.

Out of scope here:

- Statuses, the draft/publish/retire lifecycle, and roles — [Form definitions](hmis-form-definitions.md)
- How `rule` / `custom_rule` / `data_collected_about` behave at runtime — [Form resolution](hmis-form-resolution.md)
- How JSON files on disk are loaded, and how fragments and patches resolve — [Form seeding](hmis-form-seeding.md)
- How a submission becomes records — [Form processing](hmis-form-processing.md)

## The definition object

The top level has exactly two allowed keys: `item`, required, with at least one entry, and `name`, optional and read by nothing. The user-facing title lives on the database record's `title` column, not in the JSON.

```json
{ "item": [ ... ] }
```

Everything else lives in the recursive `item` tree. Each node has a `link_id`, a `type`, and type-specific properties. A node with `"type": "GROUP"` may carry a child `item` array; that is the only nesting mechanism.

Groups are structure and layout only. They hold children, collect no value, may not have a `mapping`, and are skipped by `Hmis::Form::Definition#link_id_item_hash`. Groups are also the unit of visibility: if filtering removes every child, the group goes too.

Files on disk may use a `fragment` key in place of an item. That is a seeding-time construct resolved before validation — see [Form seeding](hmis-form-seeding.md).

## Item types

`type` is required on every node. The full list is `Types::Forms::Enums::ItemType`.

- Structure and text: `GROUP`, `DISPLAY`. Neither collects a value.
- Free text: `STRING` (one line), `TEXT` (multi-line).
- Numbers: `INTEGER`, `CURRENCY` (up to two decimals). These are the only types with server-side format and bounds checking.
- `BOOLEAN`, `DATE`, `TIME_OF_DAY`.
- Lists: `CHOICE`, `OPEN_CHOICE` (allows a value not on the list). Both require a pick list. Multi-select is `repeats: true`, not a separate type.
- Uploads: `FILE`, `IMAGE`. A form containing either cannot be saved in progress.
- Composite: `OBJECT`, rendered by `component` as `NAME`, `ADDRESS`, `PHONE`, or `EMAIL`. `GEOLOCATION` for captured coordinates.

Set `assessment_date: true` on the one `DATE` item that is the assessment date (for assessment-role forms only).

## `link_id`

Required on every node, groups included. It must be unique for each item within the Form Definition.

`link_id` is the stable handle for everything that refers to an item: stored answers are keyed by it; `enable_when.question`, `bounds.question`, and `autofill_values.value_question` reference it; environment patches target it; HUD assessments must contain specific ones for their role; and an auto-created Custom Data Element derives its key from it.

## `mapping`

`mapping` says where an answer is stored. Exactly one of `field_name` or `custom_field_key` is required when `mapping` is present.

**A HUD or record field.** `field_name` is the camelCase GraphQL field on the target type. `record_type` selects which related record receives it; omit it to write to the form's own owner record.

```json
"mapping": { "record_type": "HEALTH_AND_DV", "field_name": "pregnancyStatus" }
```

Valid `record_type` values are defined in `Hmis::Form::RecordType`. Each targets the same-named model, with two exceptions: `DISABILITY_GROUP` fans out to several `Disabilities` records, and `GEOLOCATION` writes to the `Enrollment`.

**A Custom Data Element.** The answer is stored as a `CustomDataElement` against a `CustomDataElementDefinition` (CDED) with that key. Add `record_type` alongside it to move the CDED's owner off the form's default owner.

```json
"mapping": { "custom_field_key": "tb_flagged_date" }
```

The owner is `RecordType.find(record_type).owner_type` when `record_type` is set, otherwise the form role's `owner_class`. A CDED is then looked up by owner type, key, and data source. **Keys are unique per owner type, not globally** — the same key on `Client` and on `CustomAssessment` is two unrelated CDEDs.

When authoring a form in the Form Builder UI, there is no need to specify the mapping. `PublishFormDefinition` will create a CDED for the field, deriving the key from link ID if none was given.

**No mapping.** Omit `mapping` for display and layout items.

## Conditional logic and filtering

Four mechanisms decide whether a user sees an item. They are not interchangeable.

| Property | Evaluated | Against | Effect |
| --- | --- | --- | --- |
| `hidden` | Front-end, unconditionally | Nothing — a static flag, not a condition | Item is never rendered, but still submits a value |
| `enable_when` | Front-end, live as the user types | Other answers on this form, or a local constant | Item is disabled; `disabled_display` decides whether it hides |
| `rule` / `custom_rule` | Server, when the definition is served | The project, its type, and its funders | Item is removed from the returned definition |
| `data_collected_about` | Front-end, when the form is rendered | The client and their relationship to head of household | Item is removed from the rendered definition |

A disabled item is still in the definition and returns as soon as its dependency changes. A filtered item is gone for that project or client, and no answer for it can be submitted.

### `hidden`

`hidden: true` takes an item out of the UI permanently. Use it for a calculated field whose value comes from `initial` or `autofill_values` and that the user should never see or edit — `LOS Under Threshold` is the canonical example. The value is still computed and still submitted, which is the point; only the rendering is suppressed. Submission-time exclusion keys off `enable_when` and `disabled_display`, not off `hidden`.

### `enable_when` and `enable_behavior`

`enable_when` is an array of conditions; `enable_behavior` is `ALL` or `ANY`. Each condition takes exactly one source — `question` (a link ID) or `local_constant` — and exactly one comparison value out of `answer_code`, `answer_codes`, `answer_group_code`, `answer_number`, `answer_boolean`, `answer_date`, or `compare_question`. `operator` is one of `EQUAL`, `NOT_EQUAL`, `EXISTS`, `ENABLED`, `IN`, `INCLUDES`, `EXCLUDES`, `GREATER_THAN`, `GREATER_THAN_EQUAL`, `LESS_THAN`, `LESS_THAN_EQUAL`.

```json
{
  "type": "GROUP",
  "link_id": "R10_1_conditionals",
  "enable_behavior": "ALL",
  "enable_when": [{ "question": "R10_1", "operator": "EQUAL", "answer_code": "YES" }],
  "item": [ ... ]
}
```

Putting the condition on a wrapping group, as above, is the idiomatic way to show or hide several items together.

`local_constant` names a value supplied by the rendering context, written with a leading `$`. The most used are `$today`, `$entryDate`, `$exitDate`; seeded forms also use `$projectStartDate`, `$projectEndDate`, `$projectType`, `$householdId`, and several user and project fields. Which are available depends on where the form is rendered.

`disabled_display` decides what a *disabled* item looks like and whether its answer survives. It has no effect while the item is enabled.

| `disabled_display` | Rendering when disabled | Answer submitted? |
| --- | --- | --- |
| `HIDDEN` (the default) | Not rendered | No |
| `PROTECTED` | Rendered, read-only, value blanked | No |
| `PROTECTED_WITH_VALUE` | Rendered, read-only, value shown | Yes |

`PROTECTED_WITH_VALUE` is the only one that keeps the value. Under the other two the field is unregistered from form state when it becomes disabled, so a previously-entered answer is dropped from the submission rather than persisted — use `PROTECTED_WITH_VALUE` when a conditionally locked field still needs to record what it holds.

### `rule` and `custom_rule`

Both hold a rule object evaluated by `Hmis::Form::DefinitionItemFilter` when the definition is served. `rule` is HUD-derived; `custom_rule` is yours. When both are present the item is kept if *either* passes. With no rule, the item is always kept.

Leaf rules are `{ variable, operator, value }`:

| `variable` | Operators | `value` |
| --- | --- | --- |
| `projectType` | `EQUAL`, `NOT_EQUAL` | HUD project type integer |
| `projectId` | `EQUAL`, `NOT_EQUAL` | string |
| `projectFunders` | `INCLUDE`, `NOT_INCLUDE` | HUD funder integer |
| `projectFunderComponents` | `INCLUDE`, `NOT_INCLUDE` | string such as `"HUD: CoC"` |
| `projectOtherFunders` | `INCLUDE`, `NOT_INCLUDE` | string, compared case-insensitively |

Compose with `{ "operator": "ANY", "parts": [ ... ] }` or `ALL`.

### `data_collected_about`

Allowed on groups and input items. Values are `ALL_CLIENTS` (the default when unset), `HOH`, `HOH_AND_ADULTS`, `ALL_VETERANS`, and `VETERAN_HOH`. A client of unknown age counts as an adult.

## Initial values and autofill

`initial` sets a value once on load. Each entry needs `initial_behavior` — `IF_EMPTY` or `OVERWRITE` — and exactly one value source out of `value_code`, `value_number`, `value_boolean`, or `value_local_constant`.

`autofill_values` keeps recomputing a value. Each entry takes exactly one source out of `value_code`, `value_number`, `value_boolean`, `value_question`, `sum_questions`, or `formula`, plus an optional `autofill_when` array with the same shape and rules as `enable_when`. With no `autofill_when` the autofill always runs. `autofill_behavior` defaults to `ANY`; `autofill_readonly: true` also runs it in read-only views.

A `DISPLAY` item may carry either, to show a computed value.

## Pick lists

`CHOICE` and `OPEN_CHOICE` require exactly one of `pick_list_options` or `pick_list_reference`.

Static options need only `code`, which is what gets stored. `label`, `secondary_label`, `helper_text`, `initial_selected`, `numeric_value` for scoring, and `group_code` / `group_label` for grouping are optional.

```json
"pick_list_options": [{ "code": "YES", "label": "Yes" }, { "code": "NO", "label": "No" }]
```

A `pick_list_reference` is either a `Types::Forms::Enums::PickListType` value, resolved server-side and often needing project or client context (see `pick_list_type.rb` and `pick_list_option.rb`), or any GraphQL enum name such as `NoYesReasonsForMissingData`, resolved in the front-end. The two share one namespace and the validator accepts the union.

## Validation-affecting properties

| Property | Effect |
| --- | --- |
| `required` | Missing or empty value is an error at submit |
| `warn_if_empty` | Missing value, or `DATA_NOT_COLLECTED`, is a warning at submit |
| `bounds` | Min/max, see below |
| `repeats` | Value is an array, aka multi-select. Must match the CDED's `repeats` when mapped to a custom field |
| `read_only` | No human editing |

`required` and `warn_if_empty` are only checked for link IDs actually present in the submission, so an item removed by a rule or by `data_collected_about` never blocks submission.

`bounds` are allowed on `INTEGER`, `CURRENCY`, `DATE`, `STRING`, and `TEXT`; on string types the bound is a character count. Each needs `id` and `type` (`MIN` or `MAX`) plus exactly one of `value_number`, `value_date`, `value_local_constant`, or `question`. `offset` shifts the comparison, in days for dates. `severity` defaults to `error`.

```json
"bounds": [
  { "id": "min-service-date", "type": "MIN", "value_local_constant": "$entryDate" },
  { "id": "max-fa-start", "type": "MAX", "question": "faEndDate" }
]
```

## Gotchas

The schema and validator catch malformed JSON on their own, so this list covers only what they *don't*.

- **Only the first `initial` entry applies.** Extra entries are silently ignored, so multiple initial values for a multi-select do not work.
- **Most bounds are not enforced server-side.** `NumericInputValidator` checks only `INTEGER` and `CURRENCY`, only non-warning severity, and only bounds expressed as a literal `value_number`. A bound against another question, a local constant, or a date is front-end only.
- **Neither is conditional logic.** `enable_when` and item-level `data_collected_about` are evaluated in the browser and never re-checked on submit, so a non-UI caller can write values for questions the form would have hidden. See [Form processing](hmis-form-processing.md#who-enforces-what).
- **`set_hud_requirements` overwrites what you wrote.** On HUD assessment forms it rewrites `rule` — so don't hand-author it there — and relaxes `data_collected_about` to the less strict of the HUD requirement and yours. It never tightens.
- **An input item with no `mapping` silently discards its answer.** Valid JSON, no warning, no persisted value.
- **`DATA_NOT_COLLECTED` and `_HIDDEN` bypass numeric validation** rather than failing format checks.
- **Don't let every item be filtered out.** A form whose questions are all ruled out for a project fails the GraphQL query at runtime, not at authoring time. See [Form resolution](hmis-form-resolution.md#item-level-filtering).

Use `_comment` to leave notes. It is accepted on most objects, and it is the only free-form key the schema allows anywhere.

## Related

- [Form definitions](hmis-form-definitions.md) — the definition model, roles, and statuses
- [Form resolution](hmis-form-resolution.md) — which form applies to a project, and item-level filtering
- [Form seeding](hmis-form-seeding.md) — loading definitions from JSON, fragments, and patches
- [Form processing](hmis-form-processing.md) — turning a submission into records
- [HMIS assessments](hmis-assessments.md) — what the assessment roles collect
