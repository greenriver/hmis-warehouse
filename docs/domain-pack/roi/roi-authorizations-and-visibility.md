---
title: ROI authorizations, client visibility, and CAS sync
summary: "How consent becomes access. Derived GrdaWarehouse::ClientRoiAuthorization rows and how they are rebuilt, the ClientRoiAuthorization.visible_in_cocs rule shared by every access-control ROI check (SourceClientPolicy via ClientRoiLoader, EnrollmentArbiter, Client#show_demographics_to?), the legacy column-based ROI scopes, the obey_consent data-source flag, CoC matching, ConsentLimit for agencies, the active-ROI report filter, and how release status is pushed to CAS."
area: roi
tags: [roi, consent, ClientRoiAuthorization, visible_in_cocs, in_coc_codes, visible_roi_statuses, rebuild_clients, roi_authorized?, ClientRoiLoader, EnrollmentArbiter, enrollments_from_rois, show_demographics_to?, obey_consent, can_view_client_enrollments_with_roi, can_search_clients_with_roi, coc_codes, ConsentLimit, FilterForActiveRoi, PushClientsToCas, housing_release_status]
sources:
  - app/models/grda_warehouse/client_roi_authorization.rb
  - app/models/grda_warehouse/tasks/generate_client_roi_authorizations_task.rb
  - app/models/grda_warehouse/tasks/update_housing_release_statuses.rb
  - app/models/consent/default.rb
  - app/models/consent/implied.rb
  - lib/tasks/grda_warehouse.rake
  - config/schedule.rb
  - app/models/grda_warehouse/auth_policies/source_client_policy.rb
  - app/models/grda_warehouse/auth_policies/context_loaders/client_roi_loader.rb
  - app/models/grda_warehouse/auth_policies/user_base_context.rb
  - drivers/client_access_control/app/models/client_access_control/enrollment_arbiter.rb
  - drivers/client_access_control/app/models/client_access_control/extensions/grda_warehouse/hud/client_extension.rb
  - app/models/filters/criteria/filter_for_active_roi.rb
  - app/models/grda_warehouse/tasks/push_clients_to_cas.rb
  - app/models/concerns/cas_client_data.rb
  - app/models/consent_limit.rb
  - app/models/agencies_consent_limit.rb
  - app/models/agency.rb
  - app/models/concerns/user_concern.rb
  - app/controllers/admin/consent_limits_controller.rb
  - app/models/cohort_columns/consent_confirmed.rb
  - app/views/clients/_consent_form_status_tags.haml
related:
  - roi/consent-records.md
  - authorization/warehouse-policies.md
  - authorization/warehouse-access-controls.md
  - warehouse/cas-integration.md
---

## Purpose

A Release of Information (ROI) lets a user who is not assigned to a client's project see that
client. This doc covers the step after consent is recorded: how the consent columns on the
destination `GrdaWarehouse::Hud::Client` become visibility decisions, and how release status
leaves the warehouse for CAS.

The client columns (`housing_release_status`, `consent_form_signed_on`, `consent_expires_on`,
`consented_coc_codes`, `consent_form_id`) are the record of consent.
`GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask` derives one
`GrdaWarehouse::ClientRoiAuthorization` row per destination client from them. The model's
comment says the row may become canonical once multiple ROIs per client are supported; until
then, write consent to the client and let the task rebuild the row. How consent gets onto the
client is in `roi/consent-records.md`.

Every access-control (ACL) check that can expose a client through an ROI reads the row through
one scope, `ClientRoiAuthorization.visible_in_cocs`:

- the policy path, `SourceClientPolicy#roi_authorized?`, through `ClientRoiLoader`;
- the scope path, `ClientAccessControl::EnrollmentArbiter#enrollments_from_rois`;
- the dashboard gate, `Client#show_demographics_to?` (private `visible_because_of_release?`).

Legacy role-based scope code still reads the client columns through
`Client.active_confirmed_consent_in_cocs`.

Use this doc when a user cannot see a client they expect to see through an ROI, when changing
CoC matching or which statuses grant visibility, when touching the `_with_roi` permissions, or
when changing what CAS receives about consent.

## Entry points

- `SourceClientPolicy#roi_authorized?` (`app/models/grda_warehouse/auth_policies/source_client_policy.rb`):
  the record-level check. `can_view?` returns it when the user's resource permissions include
  `:can_view_client_enrollments_with_roi` but not `:can_view_clients`;
  `can_view_supplemental_data?` requires it in addition to `:can_view_supplemental_client_data`.
  Reach it through `user.policy_for(source_client)`; see `authorization/warehouse-policies.md`.
- `GrdaWarehouse::ClientRoiAuthorization.visible_in_cocs(coc_codes, date = Date.current)`: the
  ROI visibility rule. Built from `active(date)`, a status filter on
  `Config.active_consent_class.visible_roi_statuses`, and `in_coc_codes(coc_codes)`. Instance
  helpers: `active?(date:)`, `partial_release?`, `full_release?`.
- `GrdaWarehouse::AuthPolicies::ContextLoaders::ClientRoiLoader#get(client_id)` and
  `#preload(client_ids)`, reached as `user.policy_context.client_roi_loader`.
- `ClientAccessControl::EnrollmentArbiter`: private `enrollments_from_rois(user, permission:)` on
  the ACL branch and `consent_sub_query(coc_codes, user)` on the legacy branch. Callers use the
  public `clients_source_visible_to`, `clients_source_searchable_to`, `enrollments_visible_to`,
  and the `Client` scopes `source_visible_to`, `searchable_to`, `destination_visible_to`.
- `GrdaWarehouse::Hud::Client#show_demographics_to?(user)` and
  `#active_confirmed_consent_in_cocs?(coc_codes)`, defined in
  `drivers/client_access_control/.../client_extension.rb`.
- `GenerateClientRoiAuthorizationsTask.rebuild_clients(client_ids)`: rebuilds the given clients
  immediately. Called from `ClientFile#set_client_consent`, `Clients::FilesController#destroy`
  (when the active consent file is deleted), and the `GrdaWarehouse::Vispdat::Base`
  `after_commit` that fires when `housing_release_confirmed` changes.
- `rake grda_warehouse:generate_client_roi_authorizations` (`lib/tasks/grda_warehouse.rake`),
  scheduled daily in `config/schedule.rb`, rebuilds every client;
  `GrdaWarehouse::Tasks::UpdateHousingReleaseStatuses` calls the task for clients whose status
  changed.
- `Filters::Criteria::FilterForActiveRoi`: report filter keyed by `FilterBase#active_roi`.
- `GrdaWarehouse::Tasks::PushClientsToCas`: field map that sends release status to CAS.
- Admin: `Admin::ConsentLimitsController` ("CoCs for Consent" tab), `require_can_edit_users!`.

## How it works

### Derived rows

`GenerateClientRoiAuthorizationsTask#_perform(client_ids: nil, batch_size: 500)` runs under a
`GrdaWarehouseBase.with_advisory_lock` (timeout 0, so a concurrent run skips) and passes each
batch of destination client ids to `rebuild_batch_with_retry`, which retries a batch once on
`ActiveRecord::Deadlocked` (a transaction updating the same clients in a different order, such as a
client merge, can deadlock against the batch's row locks). `rebuild_clients` calls `rebuild_batch`
directly, outside the advisory lock and without the retry.

`rebuild_batch` runs in a `GrdaWarehouseBase.transaction` and reads its clients with
`SELECT ... FOR UPDATE` in id order, so a consent column write waits for an in-progress rebuild
of that client and a rebuild reads the latest committed consent. For each client `roi_status`
returns `revoked` if `client.revoked_consent?` (checked first, because revocation clears
`consent_form_signed_on`); `partial` for implied consent under `Consent::Implied`, whatever the
duration; `nil` when `release_dates_present?` fails (`One Year`/`Two Years` without
`consent_form_signed_on`, `Use Expiration Date` without `consent_expires_on`); `partial` if
`partial_release?`; `full` if `release_valid?`; else `nil`. A non-nil status is upserted (conflict
target `destination_client_id`) with `coc_codes` = sorted unique `consented_coc_codes` or `nil`.
Revoked and implied-consent rows have no `starts_at` or `expires_at`; other rows get
`starts_at = consent_form_signed_on` and `expires_at` from `roi_expiry_date` (signed date plus
`Client.consent_validity_period`, `consent_expires_on`, or `nil` for `Indefinite`). A nil status
deletes the row and calls `Client.invalidate_consent!`; those clients are then processed again
and any resulting row is upserted. Under `Consent::Implied` the reset to `Implied Consent`
produces a `partial` row in the same rebuild.

After the batches, `_perform` (not `rebuild_clients`) invalidates clients with an expired
`partial`/`full` row and a non-nil `consent_form_id`, then rebuilds them (under `Consent::Implied`
they fall back to implied consent), and deletes rows whose client no longer
exists. `Client has_many :roi_authorizations, dependent: :delete_all`.

### Visibility rule and policy path

`visible_in_cocs` keeps rows that are `active(date)` (status `partial` or `full`, `starts_at`
on or before the date, `expires_at` on or after it), whose status is in the consent class's
`visible_roi_statuses`, and that pass `in_coc_codes`. `Consent::Default.visible_roi_statuses` is
`full` only, because a partial release is CAS-only. `Consent::Implied` returns `partial` and
`full`, because its partial release string is implied consent. `in_coc_codes` matches rows whose
`coc_codes` is NULL, empty, or overlaps the given codes plus `'All CoCs'`; the codes are bound as
a parameter. Dates are checked at query time, so an expiry does not wait for a rebuild.

`roi_authorized?` returns false unless the source client's data source has `obey_consent` and
the client has a destination, then asks `ClientRoiLoader#get(destination.id)`. The loader caches
`{ destination_client_id => bool }` for the request, defaulting to false, and sets true for ids
returned by `visible_in_cocs(user.coc_codes, today).where(destination_client_id: ids)`. On the
legacy branch, `add_legacy_data_source_permissions` also consults `roi_authorized?` for window
data sources when `Config.get(:window_access_requires_release)` is on.

### Scope path and dashboard gate

ACL branch: `enrollments_from_rois(user, permission:)` selects destination ids from
`visible_in_cocs(user.coc_codes)`, maps them to source client ids through `WarehouseClient`, keeps
source clients whose data source is in `DataSource.obeys_consent`, and keeps enrollments at
`Project.viewable_by(user, permission:)`. Search passes `:can_search_clients_with_roi`; the
client and enrollment visibility scopes pass `:can_view_client_enrollments_with_roi`.

`show_demographics_to?` on the ACL branch (`visible_because_of_release?`) requires
`user.can_view_client_enrollments_with_roi?`, a `visible_in_cocs(user.coc_codes)` row with status
`full` among the destination's `roi_authorizations`, and at least one source client in an
`obey_consent` data source. Implied consent (a `partial` row under `Consent::Implied`) grants the
lists, enrollments, and policy paths but not the dashboard.

Legacy branch: `consent_sub_query` selects from `Client.active_confirmed_consent_in_cocs`
(`consent_form_valid` plus a `consented_coc_codes` match) limited to
`potentially_viewable_data_source_ids(user)` (source data sources that obey consent plus data
sources `viewable_by(user)`), and is skipped when `user.can_search_own_clients?`.
Legacy `visible_because_of_release?` checks `consent_form_valid?` and `valid_in_coc`.

### ConsentLimit, CAS, and display

`ConsentLimit` rows (`name` is a CoC code, format `ZZ-000`) are the option list for the
CoC-codes select on the consent-file forms: `User#coc_codes_for_consent` returns
`ConsentLimit.available_coc_codes` for every user. `AgenciesConsentLimit` links limits to
`Agency` for display only. Neither model changes a user's effective `coc_codes`.

`PushClientsToCas` sends `housing_release_status: :release_status_for_cas` and
`housing_assistance_network_released_on: :consent_form_signed_on`. `release_status_for_cas`
(`app/models/concerns/cas_client_data.rb`) returns `'None on file'` when blank, `'Expired'` when
`release_duration` is `One Year` or `Use Expiration Date` and the form is not valid and
confirmed, else the translated status.

`CohortColumns::ConsentConfirmed` (read-only, not usable in cohort rules) shows
`consent_confirmed?` and `release_current_status`. `_consent_form_status_tags.haml` lists the
client's `roi_authorizations` dates.

## Key files

- `app/models/grda_warehouse/client_roi_authorization.rb`: status constants, `active`,
  `in_coc_codes`, `visible_in_cocs`, `with_invalid_client`, `active?`, `date_in_valid_range?`.
- `app/models/grda_warehouse/tasks/generate_client_roi_authorizations_task.rb`:
  `rebuild_clients`, `_perform`, `rebuild_batch`, `process_client`, `roi_status`,
  `roi_expiry_date`, `roi_coc_codes`, `with_lock`.
- `app/models/consent/default.rb`, `app/models/consent/implied.rb`: `visible_roi_statuses`.
- `app/models/grda_warehouse/tasks/update_housing_release_statuses.rb`: calls the task for
  clients whose `housing_release_status` changed.
- `lib/tasks/grda_warehouse.rake`: `grda_warehouse:generate_client_roi_authorizations` runs the
  task inline; `config/schedule.rb` runs that rake task daily.
- `app/models/grda_warehouse/auth_policies/source_client_policy.rb`: `can_view?`,
  `can_view_supplemental_data?`, `roi_authorized?`, `add_legacy_data_source_permissions`.
- `app/models/grda_warehouse/auth_policies/context_loaders/client_roi_loader.rb`: `get`,
  `preload`.
- `app/models/grda_warehouse/auth_policies/user_base_context.rb`: memoized `client_roi_loader`.
- `drivers/client_access_control/app/models/client_access_control/enrollment_arbiter.rb`:
  `enrollments_from_rois`, `obeys_consent_data_source_ids`, `consent_sub_query`,
  `potentially_viewable_data_source_ids`.
- `drivers/client_access_control/app/models/client_access_control/extensions/grda_warehouse/hud/client_extension.rb`:
  `active_confirmed_consent_in_cocs?`, `valid_in_coc`, `visible_because_of_release?`,
  `show_demographics_to?`, `enrollments_for_verified_homeless_history` (`:release` method).
- `app/models/filters/criteria/filter_for_active_roi.rb`: joins clients, merges
  `Client.consent_form_valid`.
- `app/models/grda_warehouse/tasks/push_clients_to_cas.rb`: attribute map;
  `app/models/concerns/cas_client_data.rb`: `release_status_for_cas`.
- `app/models/consent_limit.rb`, `app/models/agencies_consent_limit.rb`, `app/models/agency.rb`,
  `app/models/concerns/user_concern.rb` (`coc_codes`, `coc_codes_for_consent`),
  `app/controllers/admin/consent_limits_controller.rb`.
- `app/models/cohort_columns/consent_confirmed.rb`,
  `app/views/clients/_consent_form_status_tags.haml`.

## Gotchas

- ACL and legacy code read different things. Every ACL ROI check reads
  `ClientRoiAuthorization.visible_in_cocs`; legacy scope code reads the client columns
  (`Client.active_confirmed_consent_in_cocs`, `ClientExtension#valid_in_coc`); legacy policy code
  (`add_legacy_data_source_permissions`) reads the row through `roi_authorized?`. A change to CoC
  matching or validity lands in `visible_in_cocs` for ACL users and in the column scopes for
  legacy users.
- Every ACL ROI path requires `obey_consent` on the source client's data source. Access that does
  not come from an ROI (project access through a collection, authoritative data sources, direct
  client assignment) does not depend on it.
- Rows lag consent column writes that do not call `rebuild_clients`. `revoke_expired_consent` is
  safe because `expires_at` is checked at query time; ETO consent from
  `HmisClient.maintain_client_consent` only grants and reaches the row at the nightly run. A spec
  that writes consent columns with `update_columns` must call `rebuild_clients` before checking
  visibility.
- `Client#invalidate_consent!` does not rebuild. Under `Consent::Implied`, `revoked_consent?`
  reads the newest consent file, so a rebuild before the file's `consent_revoked_at` is saved
  would reset the client to `Implied Consent`. The file's `after_commit` rebuilds once the
  revocation is saved.
- `rebuild_batch` processes clients a second time after `invalidate_consent!`, because under
  `Consent::Implied` invalidation writes `Implied Consent`, which needs a `partial` row. Dropping
  that pass hides the client from ROI-only users until the next rebuild.
- `ClientRoiLoader` is memoized on the policy context for the request or job. Call
  `preload(client_ids)` before per-row policy checks in a list to avoid one query per client.
- `EnrollmentArbiter#obeys_consent_data_source_ids` is memoized on the arbiter instance, and
  `Client.arbiter(user)` reuses one arbiter per user object (`client_access_arbiter`). Specs that
  flip `obey_consent` need a fresh user object.
- `user.coc_codes` is `Rails.cache`d for one minute (deleted in test) and comes from the user's
  collections (ACL) or access groups (legacy), not from `ConsentLimit`.
- `window_access_requires_release` and window data sources are a legacy mechanic; under ACLs a
  system collection of window data sources replaces them, and `visible_because_of_window?` is
  skipped when `using_acls?`.
- `FilterForActiveRoi` only checks `consent_form_valid`; it ignores CoC codes, `obey_consent`,
  and the requesting user.
- `roi_expiry_date` raises when the duration is time-based and `consent_form_signed_on` is
  blank. `process_client` never reaches it for such a client: `roi_status` returns nil for an
  undated release, and revoked and implied-consent rows skip `roi_expiry_date`.
- A release missing the date its duration needs gets no row, and `rebuild_batch` clears the
  client's consent columns with `invalidate_consent!`. Under `Consent::Implied` the client then
  falls back to implied consent.

## Do not repeat

- Treating `GrdaWarehouse::ClientRoiAuthorization` as the record of consent by writing rows
  directly. Write consent through `GrdaWarehouse::ClientFile` and the client columns
  (`roi/consent-records.md`), then call `GenerateClientRoiAuthorizationsTask.rebuild_clients`.
  Current example: `ClientFile#set_client_consent` in `app/models/grda_warehouse/client_file.rb`.
- Deciding ROI visibility in a new ACL check from the client columns, from
  `ClientRoiAuthorization.active`, or from `consent_form_valid?`. Use `visible_in_cocs` plus the
  `obey_consent` check, as `app/models/grda_warehouse/auth_policies/context_loaders/client_roi_loader.rb`
  and `SourceClientPolicy#roi_authorized?` do.
- New uses of the window data source mechanic (`DataSource.visible_in_window`,
  `window_data_source_ids`, `Config.get(:window_access_requires_release)`). Under ACLs, grant
  `can_view_client_enrollments_with_roi` or `can_search_clients_with_roi` on a collection
  instead; see `authorization/warehouse-access-controls.md`.
- Reading `user.can_view_client_enrollments_with_roi?` alone to decide a client is visible. Use
  `user.policy_for(source_client).can_view?` or the `Client.source_visible_to(user)` scope.
- The commented-out `calculate_consent_status` in
  `app/models/grda_warehouse/tasks/update_housing_release_statuses.rb` is dead code; do not
  resurrect it.

## Related

- `roi/consent-records.md`: how consent columns are written and `housing_release_status`
  computed.
- `roi/consent-from-external-sources.md`: consent arriving via ETO and `HmisClient`.
- `authorization/warehouse-policies.md`: `policy_for`, `UserBaseContext`, what
  `ClientRoiLoader` plugs into.
- `authorization/warehouse-access-controls.md`: `Project.viewable_by(user, permission:)` and the
  `EnrollmentArbiter` branches the ROI scopes feed.
- `warehouse/cas-integration.md`: the rest of the `PushClientsToCas` field map.
- `docs/features/warehouse/client-roi-and-consent.md`: human-facing ROI and consent overview.
- `docs/features/warehouse/data-sources.md`: the `obey_consent` data source flag.
