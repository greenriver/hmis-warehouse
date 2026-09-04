# Form data

JSON form definitions for "system-managed" forms, i.e. forms that are `managed_in_version_control`. Base definitions live in `default/`; sibling directories are per-client environment overrides selected by `ENV['CLIENT']`.

Documentation for this directory lives in the feature docs, not here:

- [Form seeding](../../../../docs/features/hmis/hmis-form-seeding.md) — how these files are loaded, and how fragments and patches resolve
- [Form definitions](../../../../docs/features/hmis/hmis-form-definitions.md) — which forms belong in version control, and why seeded forms are always published and overwritten
- [Form authoring](../../../../docs/features/hmis/hmis-form-authoring.md) — how to write the JSON
- [Form resolution](../../../../docs/features/hmis/hmis-form-resolution.md) — configuration footguns, including duplicate occurrence point forms and forms whose items are all ruled out
