# HMIS form seeding

Pipeline that loads form definitions from version-controlled JSON into the database, and creates the system form instances (rules) required for the HMIS application to be HUD-compliant.

On **deploy / `db:seed`**, this pipeline runs from `SeedMaker#load_hmis_data`.


This pipeline can also be manually invoked with task `rails driver:hmis:seed_definitions`.

## Key models

### `Hmis::Form::Definition`

The versioned form schema itself (`drivers/hmis/app/models/hmis/form/definition.rb`, table `hmis_form_definitions`). Definitions loaded by this pipeline have `managed_in_version_control: true` and are limited to a single published version per identifier. See [Form definitions](hmis-form-definitions.md) for columns, roles, and the status lifecycle — noting that seeded forms bypass that lifecycle, since they are always published and overwritten in place on every run.

### `Hmis::Form::Instance`

An applicability rule ("Form Rule" in the UI) binding a definition to a scope such as a project, organization, funder, or project type (`drivers/hmis/app/models/hmis/form/instance.rb`, table `hmis_form_instances`). This pipeline creates the **system** instances (`system: true`) that HUD compliance requires; everything else is user-created configuration. See [Form resolution](hmis-form-resolution.md) for the scope columns, rule ranking, and how the app picks a form.

## Seeding pipeline

The task **`rails driver:hmis:seed_definitions`** ([`drivers/hmis/lib/tasks/setup.rake`](../../../drivers/hmis/lib/tasks/setup.rake)) iterates each HMIS data source, loads form definitions, then ensures compliant form instances. This ensures that the HMIS application is HUD-compliant and has all the forms it expects.

1. `HmisUtil::JsonForms`: Loads JSON form files, resolves fragments, applies environment-specific patches, validates each definition, and upserts `Form::Definition` records for forms that are `managed_in_version_control`. After definitions are loaded, it invokes `HudComplianceFormInstanceMaintainer` to ensure all system form rules exist.

2. `HmisUtil::HudComplianceFormInstanceMaintainer`: Creates or updates system `Form::Instance` records for HUD-required forms and assessments, using applicability declared in `HudUtility2026` (e.g. `current_living_situation_funder_applicability_requirements`, `service_form_funder_applicability_requirements`). Changes are logged and may be sent via the configured notifier.

3. `HudUtility2026`: Source of truth for which funder / project-type combinations require which forms for HUD compliance.

## Which forms belong here

Not every form should be seeded from JSON. That decision, and its consequences, are covered in [Form definitions — Version control or Form Builder?](hmis-form-definitions.md#version-control-or-form-builder). In short: HUD-compliant and application-critical forms belong in version control; customer-specific non-HUD forms belong in the Form Builder.

**Patches and environment overrides** are for when you need a customer-specific change to a HUD-compliant form — an extra field on the Client form, CLS, or HUD Service form, or extra sections on a HUD assessment. Those patches live under the client's directory and are applied according to `ENV['CLIENT']` and the `form_data/` layout.

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

- TODO **#8955**: support overrides/patches per data source to support isolated configuration for multi-HMIS
