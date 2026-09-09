# HMIS form definitions

Nearly all data entry in the HMIS front-end is driven by a **form definition**. This document covers the `Hmis::Form::Definition` model itself — its columns, its roles, and its status lifecycle. It is the entry point to the other form docs.

| Concept | Model / table | What it answers | Documented in |
| --- | --- | --- | --- |
| Form definition | `Hmis::Form::Definition` / `hmis_form_definitions` | What questions does this form ask, and is this version live? | This doc |
| The definition JSON | the `definition` column | How do I write or change the questions? | [Form authoring](hmis-form-authoring.md) |
| Form rule | `Hmis::Form::Instance` / `hmis_form_instances` | Which projects use this form, and which form does the app pick? | [Form resolution](hmis-form-resolution.md) |
| Form processor | `Hmis::Form::FormProcessor` / `hmis_form_processors` | What happened when this form was submitted, and where did the data go? | [Form processing](hmis-form-processing.md) |
| Custom Data Element | `Hmis::Hud::CustomDataElement` | Where do answers live that have no HUD field? | Below, briefly |
| JSON files on disk | `drivers/hmis/lib/form_data/` | How do version-controlled forms get into the database? | [Form seeding](hmis-form-seeding.md) |

## The definition model

`Hmis::Form::Definition` (table `hmis_form_definitions`) is a versioned form schema. Its `definition` column holds a recursive JSON structure, loosely based on FHIR Questionnaire, describing inputs, labels, validation, and the `mapping` of each question to a HMIS field or Custom Data Element.

Key columns:

| Column | Meaning |
| --- | --- |
| `identifier` | Stable string shared across all versions of the same form. Form rules reference this, not `id` |
| `role` | What the form collects (see [Roles](#roles)) |
| `status` | `draft`, `published`, or `retired` (see [Lifecycle](#lifecycle)) |
| `version` | Integer, incremented when a new draft is created for an identifier |
| `data_source_id` | Scopes the definition to an HMIS data source |
| `managed_in_version_control` | True if the definition came from a JSON file on disk rather than the Form Builder |
| `admin_editable_only` | Restricts editing to super-admins (`Hmis::AuthPolicies::FormDefinitionPolicy`) |
| `external_form_object_key` | For `EXTERNAL_FORM` only: the key public submissions are filed under. Cannot be reused across identifiers |

`identifier` + `version` is unique within a data source. A definition is never edited in place once published; a new version is created instead. The exception is seeded forms, [described below](#seeded-forms-are-always-published-and-overwritten).

Answers that have no HUD field are stored as **Custom Data Elements**, keyed by a `custom_field_key` in the item's `mapping`. Publishing a form creates the matching `CustomDataElementDefinition` rows automatically. There is no dedicated CDE doc yet; the generation rules are covered in [Form authoring](hmis-form-authoring.md).

## Roles

A definition's `role` determines what record the form owns, which mutation submits it, and where it appears in the UI. Roles are declared in `Hmis::Form::Definition`, grouped as follows:

| Group | Roles | Notes |
| --- | --- | --- |
| Assessment | `INTAKE`, `UPDATE`, `ANNUAL`, `EXIT`, `POST_EXIT`, `CUSTOM_ASSESSMENT` | Own a `CustomAssessment`; submitted via `SubmitAssessment`. Only these support save-in-progress. See [HMIS assessments](hmis-assessments.md) |
| System record | `PROJECT`, `ORGANIZATION`, `PROJECT_COC`, `FUNDER`, `INVENTORY`, `CLIENT`, `NEW_CLIENT_ENROLLMENT`, `ENROLLMENT`, `HMIS_PARTICIPATION`, `CE_PARTICIPATION` | Required for basic HMIS function. Resolution raises if one is missing |
| Data collection feature | `CURRENT_LIVING_SITUATION`, `SERVICE`, `CE_EVENT`, `CE_ASSESSMENT`, `CASE_NOTE`, `EXTERNAL_FORM`, `REFERRAL`, `REFERRAL_REQUEST` | Optional per-project features, toggled on by an active form rule. The two referral roles are deprecated |
| Static | `FORM_RULE`, `PROJECT_CONFIG`, `CLIENT_ALERT`, `FORM_DEFINITION` | Admin config forms. Not configurable, need no rule, submitted by bespoke mutations |
| Other | `OCCURRENCE_POINT`, `CLIENT_DETAIL`, `FILE`, `CE_REFERRAL_STEP` | |

Everything except the assessment and static groups is a "record form," submitted via `SubmitForm`. `FORM_ROLE_CONFIG` maps each of those roles to its `owner_class` — the record type the form creates or edits.

`EXTERNAL_FORM` is the one public-facing role. Those forms are filled out by the public rather than by staff, arrive through an S3 pipeline instead of a GraphQL mutation, and are reviewed in the HMIS before their data is accepted.

Multiple published definitions can share a role. Which one applies to a given project is not determined by the role alone — see [Form resolution](hmis-form-resolution.md).

## Lifecycle

| Status | Offered for new data entry | Can submit | Can delete |
| --- | --- | --- | --- |
| `draft` | No | No | Yes |
| `published` | Yes | Yes | No |
| `retired` | No\* | Yes | No |

\* Resolution only ever returns published definitions, so a retired form is never *offered*. It is not, however, refused: the front-end will open a new assessment against a retired definition if navigated to one directly by id (`NewIndividualAssessmentPage.tsx` accepts `Published` or `Retired`).

Only one version per identifier can be `published` at a time. Publishing a draft (`PublishFormDefinition`) retires the previously published version in the same transaction. Editing a published form means creating the next draft version (`CreateNextDraftFormDefinition`), then publishing that. The Form Builder refuses to open anything but a draft.

Deletion is restricted to drafts (`DeleteFormDefinition`), because published and retired definitions are referenced by `hmis_form_processors` rows on existing records. Retiring is the only way to take a form out of circulation.

`valid_status_for_submit?` allows both `published` and `retired`, so a retired definition can still be submitted. This is deliberate: it keeps existing records editable after their form is retired. Which definition the UI actually uses to edit an old record — the original or a newer one — depends on the record type, and is covered in [Form resolution](hmis-form-resolution.md#choosing-a-definition-for-an-existing-record).

### Seeded forms are always published, and overwritten

Definitions loaded from JSON (`managed_in_version_control: true`) do not participate in the draft/publish cycle. `HmisUtil::JsonForms#load_definition` upserts a single row per identifier at `version: 0`, overwrites its `definition` JSON from the file, and forces `status` to `published` on every run. There is no version history and no retired predecessor.

Two things follow:

- Local edits to a seeded form through the Form Builder are lost on the next deploy or `rails driver:hmis:seed_definitions`. The Form Builder shows an alert on these forms and offers "Duplicate" instead.
- Adding a JSON file for an identifier that is deliberately retired will publish it. Avoid version control for any form whose value depends on staying retired.

## Version control or Form Builder?

Forms can either be managed in version control (JSON files under `drivers/hmis/lib/form_data/`) or managed in the Form Builder in-app. This is a per-form decision with real consequences, since seeded forms are overwritten on deploy.

**Prefer version control** for anything that collects **HUD fields** and must **stay HUD-compliant over time** — the Client form, HUD Service collection form, Current Living Situation, intake and exit assessments, the Project form, and the other definitions that ship under `default/`. Any form that is essential to application function, such that the app would crash without it, also belongs in version control.

**Do not manage in version control** forms that are **customer-specific and non-HUD**: custom assessments, service forms for custom (non-HUD) services, case note forms, non-HUD occurrence point forms, client details forms, and similar tenant-only content. Build those in the Form Builder. Service forms and custom assessments in particular should never be added to `form_data/`.

**Patches and environment overrides** are for a customer-specific change to a HUD-compliant form — an extra field on the Client form, or extra sections on a HUD assessment. Those live under the client's directory and are applied per `ENV['CLIENT']`; see [Form seeding](hmis-form-seeding.md).

## Related

- [Form resolution](hmis-form-resolution.md) — form rules, which definition applies where, and item-level filtering
- [Form authoring](hmis-form-authoring.md) — writing the definition JSON
- [Form processing](hmis-form-processing.md) — what happens on submit, and where the data lands
- [Form seeding](hmis-form-seeding.md) — loading definitions from JSON and maintaining HUD compliance rules
- [HMIS assessments](hmis-assessments.md) — what the assessment roles collect, and the record types behind them
- [Multi-HMIS support](multi-hmis-support.md) — why definitions carry `data_source_id`, and which config tables are not yet fully scoped
- [CE workflow builders](ce-workflow-builders.md) — `WorkflowDefinition::Template` uses a parallel draft/publish/retire lifecycle
