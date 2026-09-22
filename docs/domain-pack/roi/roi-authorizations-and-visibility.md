---
title: ROI authorizations, client visibility, and CAS sync
summary: "How consent becomes access. Derived GrdaWarehouse::ClientRoiAuthorization rows, the ACL-era SourceClientPolicy#roi_authorized? check via ClientRoiLoader, the legacy EnrollmentArbiter ROI scopes, the obey_consent data-source flag, CoC matching, ConsentLimit for agencies, the active-ROI report filter, and how release status is pushed to CAS."
area: roi
tags: [roi, consent, ClientRoiAuthorization, roi_authorized?, ClientRoiLoader, EnrollmentArbiter, obey_consent, can_view_client_enrollments_with_roi, can_search_clients_with_roi, coc_codes, ConsentLimit, FilterForActiveRoi, PushClientsToCas, housing_release_status]
sources:
  - app/models/grda_warehouse/client_roi_authorization.rb
  - app/models/grda_warehouse/tasks/generate_client_roi_authorizations_task.rb
  - app/models/grda_warehouse/tasks/update_housing_release_statuses.rb
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
destination `GrdaWarehouse::Hud::Client` are turned into visibility decisions, and how release
status leaves the warehouse for CAS.

Two code paths make ROI visibility decisions and both read the same client columns:

- The policy path, `GrdaWarehouse::AuthPolicies::SourceClientPolicy#roi_authorized?`, reads
  derived `GrdaWarehouse::ClientRoiAuthorization` rows through a per-request loader.
- The scope path, `ClientAccessControl::EnrollmentArbiter`, builds SQL directly against
  `housing_release_status`, `consent_form_signed_on`, `consent_expires_on`, and
  `consented_coc_codes` via `GrdaWarehouse::Hud::Client.active_confirmed_consent_in_cocs`.

The client columns are canonical today. `GrdaWarehouse::ClientRoiAuthorization` is a derived
projection of them, rebuilt by `GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask`.
Its comment says it may become canonical when multiple ROIs per client are supported; until
then, write consent to the client and let the task regenerate the row. How consent gets onto
the client is in `roi/consent-records.md`.

Use this doc when a user cannot see a client they expect to see through an ROI, when changing
CoC matching, when touching the `_with_roi` permissions, or when changing what CAS receives
about consent.

## Entry points

- `SourceClientPolicy#roi_authorized?` (`app/models/grda_warehouse/auth_policies/source_client_policy.rb`):
  the record-level check. `can_view?` returns it when the user's resource permissions include
  `:can_view_client_enrollments_with_roi` but not `:can_view_clients`;
  `can_view_supplemental_data?` requires it in addition to `:can_view_supplemental_client_data`.
  Reach it through `user.policy_for(source_client)`; see `authorization/warehouse-policies.md`.
- `GrdaWarehouse::ClientRoiAuthorization.active(date = Date.current)`: rows with status
  `partial` or `full` whose `starts_at`/`expires_at` window includes the date. Instance
  equivalents: `active?(date:)`, `matches_coc_codes?(any_coc_codes)`, `partial_release?`,
  `full_release?`.
- `GrdaWarehouse::AuthPolicies::ContextLoaders::ClientRoiLoader#get(client_id)` and
  `#preload(client_ids)`, reached as `user.policy_context.client_roi_loader`.
- `ClientAccessControl::EnrollmentArbiter` ROI scopes: `viewable_enrollments_from_rois(user)`
  and `searchable_enrollments_from_rois(user)` on the ACL branch, `consent_sub_query(coc_codes,
  user)` on the legacy branch. All private; callers use the public `clients_source_visible_to`,
  `clients_source_searchable_to`, `enrollments_visible_to`, and the `Client` scopes
  `source_visible_to`, `searchable_to`, `destination_visible_to` that wrap them.
- `GrdaWarehouse::Hud::Client#active_confirmed_consent_in_cocs?(coc_codes)` and
  `#show_demographics_to?(user)` (which calls private `visible_because_of_release?`), defined in
  `drivers/client_access_control/.../client_extension.rb`.
- `Filters::Criteria::FilterForActiveRoi`: report filter keyed by `FilterBase#active_roi`.
- `GrdaWarehouse::Tasks::PushClientsToCas`: field map that sends release status to CAS.
- `grda_warehouse:generate_client_roi_authorizations` rake task (`lib/tasks/grda_warehouse.rake`),
  calling `GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.perform` directly, scheduled
  daily via `config/schedule.rb` (no longer a background job — the queue-backed
  `GenerateClientRoiAuthorizationsJob` was removed). `GrdaWarehouse::Tasks::UpdateHousingReleaseStatuses`
  calls the task inline for clients whose status changed.
- Admin: `Admin::ConsentLimitsController` ("CoCs for Consent" tab), `require_can_edit_users!`.

## How it works

**Derived rows.** `GenerateClientRoiAuthorizationsTask#_perform(client_ids: nil, batch_size:
500)` runs under a `GrdaWarehouseBase.with_advisory_lock` (timeout 0, so a concurrent run skips).
For each destination client it computes `roi_status`: `revoked` if `client.revoked_consent?`,
`partial` if `partial_release?`, `full` if `release_valid?`, else `nil`; also `nil` when
`release_duration` is `One Year`/`Two Years` and `consent_form_signed_on` is blank. A non-nil
status is upserted (conflict target `destination_client_id`, so one row per client) with
`starts_at = consent_form_signed_on`, `expires_at` from `roi_expiry_date` (signed date plus
`Client.consent_validity_period`, `consent_expires_on`, or `nil` for `Indefinite`), and
`coc_codes` = sorted unique `consented_coc_codes` or `nil`. A nil status deletes the row and
calls `Client.invalidate_consent!`. After the batches, clients with an expired `partial`/`full`
row and a non-nil `consent_form_id` are invalidated, and rows whose client no longer exists are
deleted. `Client has_many :roi_authorizations, dependent: :delete_all`.

**Policy path.** `roi_authorized?` returns false unless the source client's data source has
`obey_consent` and the client has a destination. It then asks `ClientRoiLoader#get(destination
.id)`. The loader caches `{ client_id => bool }` for the request, defaulting to false, and
answers true when any `ClientRoiAuthorization.active(Date.current)` row for the client satisfies
`matches_coc_codes?(user.coc_codes)`: true if the row's `coc_codes` is blank or includes
`'All CoCs'`, else a non-empty intersection. On the legacy branch,
`add_legacy_data_source_permissions` also consults `roi_authorized?` for window data sources
when `Config.get(:window_access_requires_release)` is on.

**Scope path.** `viewable_enrollments_from_rois` selects destination clients from
`Client.active_confirmed_consent_in_cocs(user.coc_codes)` (`consent_form_valid` plus
`consented_coc_codes ?| [user codes, 'All CoCs']` or `= '[]'`), maps them to source ids via
`WarehouseClient`, and keeps enrollments at `Project.viewable_by(user, permission:
:can_view_client_enrollments_with_roi)`. `searchable_enrollments_from_rois` is the same with
`:can_search_clients_with_roi`. Legacy `consent_sub_query` uses the same client scope limited to
`DataSource.source.obeys_consent` plus data sources `viewable_by(user)`, and is skipped when
`user.can_search_own_clients?`.

**ConsentLimit.** `ConsentLimit` rows (`name` is a CoC code, format `ZZ-000`) are the option
list for the CoC-codes select on the consent-file forms: `User#coc_codes_for_consent` returns
`ConsentLimit.available_coc_codes` for every user. `AgenciesConsentLimit` links limits to
`Agency` for display only. Neither model changes a user's effective `coc_codes`.

**CAS.** `PushClientsToCas` sends `housing_release_status: :release_status_for_cas` and
`housing_assistance_network_released_on: :consent_form_signed_on`. `release_status_for_cas`
(`app/models/concerns/cas_client_data.rb`) returns `'None on file'` when blank, `'Expired'` when
`release_duration` is `One Year` or `Use Expiration Date` and the form is not valid and
confirmed, else the translated status.

**Display.** `CohortColumns::ConsentConfirmed` (read-only, not usable in cohort rules) shows
`consent_confirmed?` and `release_current_status`. `_consent_form_status_tags.haml` lists the
client's `roi_authorizations` dates.

## Key files

- `app/models/grda_warehouse/client_roi_authorization.rb`: status constants, `active`,
  `with_invalid_client`, `active?`, `date_in_valid_range?`, `matches_coc_codes?`.
- `app/models/grda_warehouse/tasks/generate_client_roi_authorizations_task.rb`: `_perform`,
  `process_client`, `roi_status`, `roi_expiry_date`, `roi_coc_codes`, `with_lock`.
- `app/models/grda_warehouse/tasks/update_housing_release_statuses.rb`: calls the task for
  clients whose `housing_release_status` changed.
- `lib/tasks/grda_warehouse.rake`: `generate_client_roi_authorizations` task, calls the Task class
  directly.
- `config/schedule.rb`: daily cron entry for `grda_warehouse:generate_client_roi_authorizations`.
- `app/models/grda_warehouse/auth_policies/source_client_policy.rb`: `can_view?`,
  `can_view_supplemental_data?`, `roi_authorized?`, `add_legacy_data_source_permissions`.
- `app/models/grda_warehouse/auth_policies/context_loaders/client_roi_loader.rb`: `get`,
  `preload`.
- `app/models/grda_warehouse/auth_policies/user_base_context.rb`: memoized `client_roi_loader`.
- `drivers/client_access_control/app/models/client_access_control/enrollment_arbiter.rb`:
  `viewable_enrollments_from_rois`, `searchable_enrollments_from_rois`, `consent_sub_query`,
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

- Two implementations decide ROI visibility and must agree: `ClientRoiAuthorization`
  (`matches_coc_codes?`, `active`) for the policy path and `Client.active_confirmed_consent_in_cocs`
  plus `ClientExtension#valid_in_coc` for the scope path. A change to CoC matching or validity
  has to land in all three, and the task's `roi_status`/`roi_expiry_date` must still produce
  rows that match the scope.
- The paths already differ in two ways. `roi_authorized?` requires the source data source to
  have `obey_consent`; the ACL-branch arbiter scopes do not check it (only legacy
  `consent_sub_query` does). `ClientRoiAuthorization.active` accepts `partial` rows, while
  `Client.consent_form_valid` under `Consent::Default` matches only the full-release string
  (`Consent::Implied` matches full and partial). Do not "fix" one side without deciding the
  intended behavior for both.
- `ClientRoiAuthorization` rows lag the client columns until the task runs: inline from
  `UpdateHousingReleaseStatuses` for status changes it detects, otherwise the nightly cron task.
  A spec that writes consent columns and then checks `roi_authorized?` must run the task.
- `ClientRoiLoader` is memoized on the policy context for the request or job. Call
  `preload(client_ids)` before per-row policy checks in a list to avoid one query per client.
- `user.coc_codes` is `Rails.cache`d for one minute (deleted in test) and comes from the user's
  collections (ACL) or access groups (legacy), not from `ConsentLimit`.
- `window_access_requires_release` and window data sources are a legacy mechanic; under ACLs a
  system collection of window data sources replaces them, and `visible_because_of_window?` is
  skipped when `using_acls?`.
- `FilterForActiveRoi` only checks `consent_form_valid`; it ignores CoC codes and the
  requesting user.
- `roi_expiry_date` raises when the duration is time-based and `consent_form_signed_on` is
  blank, but `roi_status` returns nil first for that case, so the raise is unreachable from
  `process_client`.

## Do not repeat

- Treating `GrdaWarehouse::ClientRoiAuthorization` as the record of consent: writing rows
  directly, or reading them from code that runs before the task has regenerated them. Write
  consent through `GrdaWarehouse::ClientFile` and the client columns
  (`roi/consent-records.md`), then run `GenerateClientRoiAuthorizationsTask`. Current example
  of the correct order: `app/models/grda_warehouse/tasks/update_housing_release_statuses.rb:43`.
- Adding ROI logic to one path only. A new rule for CoC matching, validity dates, or partial
  releases goes into `ClientRoiAuthorization` and the task (policy path) and into
  `Client.active_confirmed_consent_in_cocs` and `ClientExtension#valid_in_coc` (scope path).
  Existing mirror pair: `app/models/grda_warehouse/client_roi_authorization.rb:51` and
  `drivers/client_access_control/app/models/client_access_control/extensions/grda_warehouse/hud/client_extension.rb:145`.
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
- `docs/features/warehouse/data-sources.md`: the `obey_consent` data source flag.
