# HMIS form seeding

Pipeline that loads form definitions from version-controlled JSON into the database, and creates the system form instances (rules) required for the HMIS application to be HUD-compliant.

On **deploy / `db:seed`**, this pipeline runs from `SeedMaker#load_hmis_data`.


This pipeline can also be manually invoked with task `rails driver:hmis:seed_definitions`.

## Key models

### `Hmis::Form::Definition`

A versioned form schema. The `definition` column holds a recursive JSON structure (based on FHIR Questionnaire) that describes inputs, labels, validation, and mappings to HMIS fields. Each definition has a stable `identifier`, a version, a role (`SERVICE`, `CLIENT`, `ENROLLMENT`, etc.), and a status (`published`, `draft`, `retired`). Definitions that originate from JSON files on disk have `managed_in_version_control: true` and are limited to a single published version per identifier.

- Model: `drivers/hmis/app/models/hmis/form/definition.rb`
- Table: `hmis_form_definitions`

### `Hmis::Form::Instance`

An applicability rule (“Form Rule” in the UI) that binds a form definition to a scope: project, organization, funder, project type, service category, or combinations. Instances control which projects and enrollments use a given form. Matching logic lives in `Hmis::Form::InstanceProjectMatch` and `Hmis::Form::InstanceEnrollmentMatch`.

- **Exclusive** roles (e.g. Project, Client, Enrollment): the single best-matching instance wins.
- **Inclusive** roles (e.g. Services, custom assessments): all matching instances apply.

**System** instances (`system: true`, `active: true`) are created by `HudComplianceFormInstanceMaintainer` and cannot be removed through the admin UI. **Non-system** instances are user-created configuration.

- Model: `drivers/hmis/app/models/hmis/form/instance.rb`
- Table: `hmis_form_instances`

## Seeding pipeline

The task **`rails driver:hmis:seed_definitions`** ([`drivers/hmis/lib/tasks/setup.rake`](../../drivers/hmis/lib/tasks/setup.rake)) iterates each HMIS data source, loads form definitions, then ensures compliant form instances. This ensures that the HMIS application is HUD-compliant and has all the forms it expects.

1. `HmisUtil::JsonForms`: Loads JSON form files, resolves fragments, applies environment-specific patches, validates each definition, and upserts `Form::Definition` records for forms that are `managed_in_version_control`. After definitions are loaded, it invokes `HudComplianceFormInstanceMaintainer` to ensure all system form rules exist.

2. `HmisUtil::HudComplianceFormInstanceMaintainer`: Creates or updates system `Form::Instance` records for HUD-required forms and assessments, using applicability declared in `HudUtility2026` (e.g. `current_living_situation_funder_applicability_requirements`, `service_form_funder_applicability_requirements`). Changes are logged and may be sent via the configured notifier.

3. `HudUtility2026`: Source of truth for which funder / project-type combinations require which forms for HUD compliance.

## Version control vs Form Builder

Forms can either be managed in version control (JSON files under `drivers/hmis/lib/form_data/`) or managed in the Form Builder in-app.

**Prefer version control** for anything that collects **HUD fields** and must **stay HUD-compliant over time**—for example: Client form, HUD Service collection form, Current Living Situation, intake and exit assessments, Project form, and other definitions that ship under `default/` and are seeded as `managed_in_version_control`. In addition to HUD-related forms, any form that is essential to application function (aka it would crash without it) should be seeded from version control.

**Do not manage in version control** forms that are **customer-specific and non-HUD**. Create and maintain those with the **Form Builder** admin tool instead. For example: custom assessments, service forms for **custom (non-HUD) services**, case note forms, **non-HUD** occurrence point forms, client details forms, and similar tenant-only content.

**Patches and environment overrides** are for when you need a **customer-specific change to a HUD-compliant** form. For example: an extra field on the Client form, CLS, or HUD Service form; or extra sections/fields on HUD assessments. Those patches live under the client’s directory (see below) and are applied according to `ENV['CLIENT']` and the `form_data/` layout.

## Environment-specific overrides

Form JSON lives under `drivers/hmis/lib/form_data/`. Base definitions are in `default/`; environment-specific overrides use sibling directories named for the client environment (`ENV['CLIENT']`). See `JsonForms` for full rules of how patches and fragments are resolved.

Example layout for a client environment **`communityxyz`**:

```text
drivers/hmis/lib/form_data/
├── default/
│   ├── assessments/
│   ├── fragments/
│   │   └── patches/
│   ├── occurrence_point_forms/
│   ├── records/
│   ├── services/
│   ├── ce_referral_steps/
│   └── ...
├── communityxyz/
│   ├── fragments/               # JSON fragments that can be referenced from forms
│   │   └── patches/             # JSON patches merged into matching forms
│   ├── records/                 # JSON files to override an entire form (eg Client form)
│   └── ...                      # Can override any other dir
└── test/
```

## Related

- TODO **#6691**: tie each Form Definition to a data source to support isolated configuration for multi-HMIS
- TODO **#8955**: support overrides/patches per data source to support isolated configuration for multi-HMIS
