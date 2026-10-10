---
title: Consent records and release status
summary: "Where client consent (Release of Information) is stored, how a consent-tagged ClientFile writes onto the destination client, how validity and housing_release_status are computed, and the two consent strategies (Consent::Default, Consent::Implied) selected by GrdaWarehouse::Config."
area: roi
tags: [roi, consent, release-of-information, ClientFile, consent_form_signed_on, consent_expires_on, housing_release_status, consented_coc_codes, Consent::Default, Consent::Implied, release_duration, roi_model, AvailableFileTag]
sources:
  - app/models/grda_warehouse/client_file.rb
  - app/models/grda_warehouse/hud/client.rb
  - app/models/consent/default.rb
  - app/models/consent/implied.rb
  - app/models/grda_warehouse/config.rb
  - app/models/grda_warehouse/available_file_tag.rb
  - app/models/grda_warehouse/tasks/update_housing_release_statuses.rb
  - app/jobs/grda_warehouse/tasks/update_housing_release_statuses_job.rb
  - app/models/grda_warehouse/tasks/generate_client_roi_authorizations_task.rb
  - app/jobs/importing/run_daily_imports_job.rb
  - app/controllers/admin/configs_controller.rb
  - app/controllers/clients/releases_controller.rb
  - app/controllers/clients/files_controller.rb
  - app/controllers/warehouse_reports/expiring_consent_controller.rb
  - app/views/admin/configs/_roi.haml
  - app/models/grda_warehouse/vispdat/base.rb
related:
  - roi/roi-authorizations-and-visibility.md
  - roi/consent-from-external-sources.md
  - warehouse/files-and-documents.md
---

## Purpose

A Release of Information (ROI) is a consent form authorizing the sharing of a client's PII
between organizations; the warehouse enforces it as an access-control input. This doc covers
how that consent is recorded and how "does this client have a valid release right now" is
answered.

Canonical consent data lives on `GrdaWarehouse::Hud::Client` destination-client columns
(`housing_release_status`, `consent_form_signed_on`, `consent_expires_on`,
`consented_coc_codes`, `consent_form_id`). Those columns are written from consent-tagged
`GrdaWarehouse::ClientFile` uploads. `GrdaWarehouse::ClientRoiAuthorization` rows are derived
from the client columns, not the other way round. Access-control visibility reads those rows, so
code that changes consent also calls `GenerateClientRoiAuthorizationsTask.rebuild_clients`; see
`roi/roi-authorizations-and-visibility.md`.

Two strategy classes, `Consent::Default` and `Consent::Implied`, define the status strings and
the human-readable current status. `GrdaWarehouse::Config.active_consent_class` picks one from
the `roi_model` config.

The HMIS application under `drivers/hmis` has no ROI or consent feature of its own; consent is
a warehouse-only concept.

## Entry points

- Upload and edit: `Clients::ReleasesController` (`app/controllers/clients/releases_controller.rb`)
  for users with `can_use_separated_consent`, tag group `Release of Information`;
  `Clients::FilesController` (`app/controllers/clients/files_controller.rb`) for the general
  files tab. Both `create` actions only honor `consent_form_confirmed` when the user
  `can_confirm_housing_release?` or the `auto_confirm_consent` config is on. Both `update`
  actions call `client.invalidate_consent!(hr_status: revoked_consent_string)` when
  `consent_revoked_at` is set on the client's active consent form, inside a
  `GrdaWarehouseBase.transaction` with the file save that rolls back when the file fails
  validation. `FilesController#destroy`
  calls `client.invalidate_consent!` and then
  `GenerateClientRoiAuthorizationsTask.rebuild_clients` when the soft-deleted file is the active
  consent form.
- `GrdaWarehouse::ClientFile#set_client_consent`, an `after_commit` on create and update. The
  only path from a file to the client consent columns; for consent forms it ends by rebuilding
  the client's ROI row. `ClientFile#confirm_consent!` only sets `consent_form_confirmed`; the
  callbacks do the rest.
- `GrdaWarehouse::Hud::Client#release_valid?(coc_codes: nil)`: true when
  `housing_release_status` starts with the active full-release string; with `coc_codes`, runs
  the `active_confirmed_consent_in_cocs` scope instead.
- `GrdaWarehouse::Hud::Client#consent_form_valid?`: `release_valid?` plus the date check for
  the configured `release_duration`. Scope form: `Client.consent_form_valid`.
- `GrdaWarehouse::Hud::Client#release_current_status`, `#revoked_consent?`,
  `#partial_release?`, `#full_or_partial_release?`, `#consent_confirmed?`,
  `#newest_consent_form`, `#active_consent_form` (`has_one` via `consent_form_id`).
- `GrdaWarehouse::Hud::Client.revoke_expired_consent`, run nightly from
  `Importing::RunDailyImportsJob#_perform` under the `Update Client ROIs` maintenance task.
- `GrdaWarehouse::Tasks::UpdateHousingReleaseStatuses#run!`, enqueued as
  `UpdateHousingReleaseStatusesJob` by `Admin::ConfigsController#update` when `roi_model`
  changes. There is no scheduled run.
- `WarehouseReports::ExpiringConsentController#index`: expired, expiring within 30 days, and
  unconfirmed consent lists. Compares `consent_expires_on` to today under `Use Expiration Date`,
  `consent_form_signed_on` to `consent_validity_period.ago` under the year durations, and lists
  only unconfirmed consent under `Indefinite`; raises on an unknown duration. A NULL date (a
  signed form awaiting confirmation) never counts as expired.

## How it works

### Tagging

A file is a consent form when one of its tags is a `GrdaWarehouse::AvailableFileTag` with
`consent_form: true`. `full_release: true` on the tag makes it a full release; a consent tag
without it is a partial release. `coc_available: true` lets the uploader pick CoC codes.
`ClientFile.consent_forms` and `.non_consent` resolve tags through `ActsAsTaggableOn::Tagging`
ids cached for two minutes under `CONSENT_FORM_TAG_CACHE_KEY`, because `tagged_with` misbehaves
in tests.

`ClientFile#consent_type` returns `Hud::Client.full_release_string` for full or CoC-level
tags and `Hud::Client.partial_release_string` for partial tags. Those class methods delegate to
the active strategy class.

### Writing to the client

On save, `before_save :adjust_consent_date` copies `effective_date` into
`consent_form_signed_on` when the tags include a consent form. After commit,
`set_client_consent` clears the tag cache, returns unless the file is a consent form, and
computes `consented_coc_codes`: `['All CoCs']` if chosen or if the tag is CoC-capable and no
codes were picked, the chosen codes otherwise, `[]` for tags without CoC support. It then
writes with `update_columns` (no callbacks): when the client has no valid consent, or when the
file is confirmed and not revoked, it sets `housing_release_status` to `consent_type`,
`consent_form_signed_on`, `consent_form_id`, `consented_coc_codes`, and `consent_expires_on`
from the file's `expiration_date`. When the client already has valid consent and this file is
unconfirmed or revoked and no other confirmed consent file exists,
`client.invalidate_consent!` clears all five columns (`housing_release_status` to the passed
`hr_status`, or the no-release string under implied consent) and clears view caches. For
every consent form it then calls `GenerateClientRoiAuthorizationsTask.rebuild_clients([client_id])`,
so the derived `ClientRoiAuthorization` row matches the columns once the commit finishes.

Confirmation is `consent_form_confirmed` on the file; `ClientFile.confirmed` also requires
`consent_revoked_at` to be nil. Revocation is `consent_revoked_at` plus
`consent_revoked_by_user_id`, set by `sync_revokation_info(current_user)`.

### Validity and expiry

Validity depends on `Config.get(:release_duration)`, one of `Indefinite`, `One Year`,
`Two Years`, `Use Expiration Date` (`Config.available_release_durations`).
`Hud::Client.consent_validity_period` maps `One Year` to `1.years`, `Two Years` to `2.years`,
`Indefinite` to `100.years`, and raises `Unknown Release Duration` for anything else, including
`Use Expiration Date`. `consent_form_valid?` checks `consent_form_signed_on >= period.ago.to_date`
for the year durations, `consent_expires_on >= Date.current` for `Use Expiration Date`, and only
`release_valid?` for `Indefinite`. Under `Use Expiration Date`, `ClientFile` refuses to save a
confirmed, unrevoked consent form without an `expiration_date`, because the ROI rebuild clears
consent for a release with no expiration date. The date comparison matters: comparing the date column with
`period.ago` (a time) treats the expiration date as expired. `revoke_expired_consent` nulls
`housing_release_status` and empties `consented_coc_codes` with `update_all` for clients strictly
outside the window `consent_form_valid?` accepts, so a release is valid on its expiration date;
it does not clear `consent_form_id` or `consent_form_signed_on`.

### Strategy classes

`Config.active_consent_class` returns `Consent::Implied` when `roi_model` is `implicit`
(`Config.implied_consent?`), else `Consent::Default`. Status strings:

- `Consent::Default`: full `Full HAN Release`, partial `Limited CAS Release`, none
  `None on file`, revoked `''` (empty string). `release_string_query` is a `LIKE
  '%Full HAN Release'`. `release_current_status` renders `Valid Until <date>` or `Expired`
  for dated durations, else the translated status, with ` in <CoC list>` appended.
  `visible_roi_statuses` is `full` only: a partial release is CAS-only and does not grant
  warehouse visibility.
- `Consent::Implied`: full `Expanded Consent`, partial equals none, `Implied Consent`,
  revoked `Consent Revoked`. `release_string_query` is `IN (full, partial)`.
  `consent_view_permission` returns `:can_view_clients` when revoked, else
  `:can_view_client_enrollments_with_roi`, and the enrollment scopes filter projects by it.
  `visible_roi_statuses` is `partial` and `full`, so implied consent grants visibility.

Both classes compute `current_consent_type` from `client.active_consent_form.consent_type`,
overridden to the revoked string when `client.newest_consent_form.revoked?`.
`UpdateHousingReleaseStatuses#run!` recomputes that for every destination client in batches of
1000, `update_all`s changed statuses grouped by new value, and calls
`GenerateClientRoiAuthorizationsTask#perform(client_ids:)` for each group.

## Key files

- `app/models/grda_warehouse/client_file.rb`: consent scopes, callbacks, `set_client_consent`,
  `consent_type`, `calculated_expiration_date`, `revoked?`, `confirm_consent!`,
  `sync_revokation_info`, `visible_by?` (uses `consent_visible_to_all` and
  `verified_homeless_history_method`).
- `app/models/grda_warehouse/hud/client.rb`: the release section (`full_release_string`,
  `consent_validity_period`, `consent_expiration_date`, `revoke_expired_consent`,
  `release_valid?`, `consent_form_valid?`,
  `consent_confirmed?`, `newest_consent_form`, `invalidate_consent!`,
  `apply_housing_release_status`), scopes `consent_form_valid`,
  `active_confirmed_consent_in_cocs`, `with_confirmed_consent`, `with_unconfirmed_consent`,
  `has_one :active_consent_form`.
- `app/models/consent/default.rb`, `app/models/consent/implied.rb`: strategy classes, including
  `visible_roi_statuses`.
- `app/models/grda_warehouse/config.rb`: `available_release_durations`,
  `available_roi_models`, `implied_consent?`, `active_consent_class`.
- `app/models/grda_warehouse/available_file_tag.rb`: `consent_forms`, `full_release`,
  `partial_consent` scopes and the `contains_consent_form?` family of predicates.
- `app/models/grda_warehouse/tasks/update_housing_release_statuses.rb`,
  `app/jobs/grda_warehouse/tasks/update_housing_release_statuses_job.rb`: bulk recompute.
- `app/models/grda_warehouse/tasks/generate_client_roi_authorizations_task.rb`:
  `rebuild_clients`, called after consent changes, and `roi_expiry_date`, the second copy of the
  duration mapping.
- `app/models/grda_warehouse/vispdat/base.rb`: `set_client_housing_release_status` writes
  `housing_release_status` from `housing_release_confirmed`: the full release string on confirm.
  On un-confirm it writes the `consent_type` of the client's active consent form when that form
  is in `ClientFile.consent_forms.confirmed` and its `calculated_expiration_date` is not past,
  else blank (the daily expiry job keeps `consent_form_id`, so the active form may be expired). An `after_commit` rebuilds the ROI row
  when the flag changes; a blank status there deletes the row and clears the consent columns.
- `app/jobs/importing/run_daily_imports_job.rb`: nightly `revoke_expired_consent`.
- `app/controllers/admin/configs_controller.rb`: enqueues the recompute on `roi_model` change.
- `app/controllers/clients/releases_controller.rb`, `app/controllers/clients/files_controller.rb`:
  upload, confirm, revoke, delete.
- `app/controllers/warehouse_reports/expiring_consent_controller.rb`: expiring-consent report.
- `app/views/admin/configs/_roi.haml`: the admin form for the ROI config knobs.

## Gotchas

- The duration-to-expiry mapping has several copies: `Hud::Client.consent_validity_period`
  (used by `ClientFile#calculated_expiration_date`, `consent_form_valid?`,
  `revoke_expired_consent`), `Hud::Client#consent_expiration_date` (the expiring-consent report),
  and `GenerateClientRoiAuthorizationsTask#roi_expiry_date`. Change them together.
- `Hud::Client.consent_validity_period` raises for `Use Expiration Date`; call it only under the
  year durations, as `ExpiringConsentController#index` does.
- Changing `release_duration` to a dated duration clears consent at the next nightly rebuild for
  every client missing the date that duration needs (`GenerateClientRoiAuthorizationsTask`
  `invalidate_consent!` on a nil `roi_status`). Changing it back does not restore it: nothing
  re-derives client columns from confirmed files except `set_client_consent`, which runs when a
  file is saved. The hint on `release_duration` in `_roi.haml` tells admins this.
- `Hud::Client.release_duration` (class) re-reads config on every call; the instance method
  memoizes per object. Specs that flip the config mid-test must use fresh client instances.
- `set_client_consent` writes with `update_columns` and `revoke_expired_consent` and
  `invalidate_consent!` with `update_all`; none fire callbacks or paper_trail on the client.
- `set_client_consent` only runs when `callbacks_skipped` is falsy. Bulk file writers that set
  `callbacks_skipped = true` leave client columns and the ROI row stale until something else
  recomputes them.
- Soft delete is `update!(deleted_at:)`, so `set_client_consent` fires but returns early because
  the paranoid default scope hides the file from `consent_forms`. The controller's explicit
  `invalidate_consent!` followed by `rebuild_clients` is what clears the client and its ROI row;
  a new deletion path must do both.
- `invalidate_consent!` does not rebuild the ROI row. The revoke paths in both controllers call
  it before saving the file, and the file's `after_commit` rebuilds once `consent_revoked_at` is
  saved; under `Consent::Implied` a rebuild before that save would read the client as
  `Implied Consent`, not revoked.
- `Consent::Default#revoked_consent_string` is the empty string. A revoked client under the
  default model has `housing_release_status = ''`, which `where(housing_release_status: nil)`
  misses; `ExpiringConsentController` matches `[nil, '']` for that reason.
- `revoke_expired_consent` leaves `consent_form_id` and `consent_form_signed_on` in place, so
  `active_consent_form` still resolves after expiry. `consent_form_valid?` is the check to use,
  not presence of the association.
- Under `Consent::Implied`, `partial_release_string == no_release_string`, so
  `partial_release?` is true for a client whose status is `Implied Consent`, the value
  `invalidate_consent!` writes under that model.
- `UpdateHousingReleaseStatuses` is not scheduled; it runs only when an admin changes
  `roi_model`. Day-to-day expiry is `revoke_expired_consent` in the nightly import job.
- Config knobs touching consent: `release_duration`, `roi_model`, `allow_partial_release`,
  `auto_confirm_consent`, `consent_visible_to_all`, `verified_homeless_history_method`
  (`:release` gates verified-homeless-history files by consent in the user's CoCs),
  `window_access_requires_release` (legacy window mechanic), `chronic_tab_roi`.

## Do not repeat

- Resurrecting the commented-out `calculate_consent_status` in
  `app/models/grda_warehouse/tasks/update_housing_release_statuses.rb`. Dead code; the live
  path is `active_consent_class.new(client:).current_consent_type`. Do not resurrect.
- Reintroducing the commented CoC-suffix logic in `ClientFile#consent_type`
  (`app/models/grda_warehouse/client_file.rb`). `housing_release_status` must equal the bare
  strategy string because `full_housing_release_on_file`, `release_valid?`, and
  `release_string_query` compare against it. CoC detail belongs in `consented_coc_codes` and
  `consent_type_with_extras`. Dead code; do not resurrect.
- Adding another copy of the `release_duration` to period mapping. Call
  `Hud::Client.consent_validity_period`, `Hud::Client#consent_expiration_date`, or
  `ClientFile#calculated_expiration_date`.
- Writing `housing_release_status` or the other consent columns from anywhere other than
  `ClientFile#set_client_consent`, `Hud::Client.invalidate_consent!`,
  `Hud::Client.revoke_expired_consent`, `UpdateHousingReleaseStatuses`,
  `GrdaWarehouse::Vispdat::Base#set_client_housing_release_status`, or the ETO path
  `GrdaWarehouse::HmisClient.maintain_client_consent`.
- Hard-coding `'Full HAN Release'` or another status string. Use
  `Hud::Client.full_release_string` and friends, which follow the active strategy.

## Related

- `roi/roi-authorizations-and-visibility.md`: how the client columns become derived
  `ClientRoiAuthorization` rows and gate visibility and CAS sync.
- `roi/consent-from-external-sources.md`: consent arriving from ETO via `HmisClient`.
- `warehouse/files-and-documents.md`: the `ClientFile` model outside of consent.
- Human-facing sources: `docs/architecture/12-glossary.md` (ROI definition),
  `docs/features/warehouse/warehouse-files-model.md`,
  `docs/features/warehouse/data-sources.md` (`obey_consent`).
