---
sources:
  - app/models/grda_warehouse/client_file.rb
  - app/models/grda_warehouse/hmis_client.rb
  - app/models/grda_warehouse/tasks/generate_client_roi_authorizations_task.rb
  - app/models/grda_warehouse/tasks/update_housing_release_statuses.rb
  - app/models/consent/default.rb
  - app/models/consent/implied.rb
  - app/models/concerns/cas_client_data.rb
---

# Client ROI and Consent

A release of information (ROI) can make a client visible to users who would not otherwise see them. This doc covers where ROI data lives and which settings change its meaning. It also covers how an ROI affects client search, client dashboards, and reporting, for users with access controls and for users with legacy role-based permissions.

## Where ROI data lives

Consent-form `ClientFile`s write these columns on the **destination** client:

- `housing_release_status`
- `consented_coc_codes`
- `consent_form_signed_on`
- `consent_expires_on`
- `consent_form_id`

`GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask` derives one `GrdaWarehouse::ClientRoiAuthorization` row per destination client from those columns. The row holds a status, CoC codes, `starts_at` and `expires_at`. The task runs:

- per client, via `rebuild_clients`, from:
  - `ClientFile#set_client_consent`, after a consent file is saved
  - `Clients::FilesController#destroy`, after the active consent file is deleted
  - the VI-SPDAT `housing_release_confirmed` checkbox (`Vispdat::Base`)

`Client#invalidate_consent!` does not rebuild. The files and releases controllers call it before they save the file's `consent_revoked_at`. Under `Consent::Implied`, `revoked_consent?` reads the newest consent file, so a rebuild at that point would not see the revocation and would reset the client to `Implied Consent`.
- for the clients whose ETO consent changed, from `HmisClient.maintain_client_consent`, through `_perform(client_ids:)`
- for changed clients, from `UpdateHousingReleaseStatuses`. This goes through the task-wide lock and is skipped while the nightly run holds it.
- nightly, for every destination client

ETO consent (`HmisClient.maintain_client_consent`) only grants consent. It rebuilds the clients whose consent it changed, through `_perform(client_ids:)`. It sets no `consent_form_id`, and the nightly run only invalidates expired releases that have one. An expired ETO release therefore keeps its expired `full` row, and the client is hidden on every ROI path (not shown with implied consent) until `revoke_expired_consent` clears the columns and a later rebuild runs.

Each rebuild reads its clients with row locks (`SELECT ... FOR UPDATE`, in id order) held until it commits. A consent column write therefore waits for any rebuild of that client, and a rebuild always reads the latest committed consent.

| Client columns | Row status |
|---|---|
| Revoked consent (`Client#revoked_consent?`), even with no signature date | `revoked`, with no `starts_at` or `expires_at` |
| `Implied Consent` under `Consent::Implied`, under every `release_duration` | `partial`, with no `starts_at` or `expires_at` |
| The consent class's partial release string | `partial` |
| The consent class's full release string | `full` |
| Anything else; a missing signature date under `One Year`/`Two Years`; a missing expiration date under `Use Expiration Date` | no row (and the task clears the consent columns; under `Consent::Implied` the client falls back to implied consent) |

`ClientRoiAuthorization.visible_in_cocs(coc_codes)` is the ROI rule for access-control visibility and for `SourceClientPolicy`. Legacy scope code still reads the client columns through `Client.active_confirmed_consent_in_cocs`.

## How a consent file becomes client consent

- **Tags decide the type.** A file is a consent form when one of its `AvailableFileTag`s has `consent_form: true`. `full_release: true` makes it a full release; a consent tag without it is a partial release. `coc_available: true` lets the uploader pick CoC codes.
- **CoC codes.** `consented_coc_codes` is `['All CoCs']` if chosen, or if the tag supports CoCs and none were picked. It is the chosen codes otherwise, and `[]` for tags without CoC support.
- **Writes skip callbacks.** `ClientFile#set_client_consent` writes the client columns with `update_columns`, and `invalidate_consent!` and `revoke_expired_consent` use `update_all`. None fire callbacks or paper trail on the client. Bulk file writers that set `callbacks_skipped` leave the client columns and the ROI row stale until something else recomputes them.
- **Status strings are bare.** `housing_release_status` must equal the consent class's bare release string (`Full HAN Release`, `Expanded Consent`, ...). `release_valid?` and the release string queries compare against it. CoC detail belongs in `consented_coc_codes`. Use `Client.full_release_string` and friends instead of hard-coding a string.
- **Expiration date required.** Under `Use Expiration Date`, a confirmed, unrevoked consent form cannot be saved without an `expiration_date`, because the rebuild clears consent for a release with no expiration date.
- **Deleting a file.** Soft delete fires `set_client_consent`, which returns early because the deleted file no longer appears in the consent scopes. The controller's explicit `invalidate_consent!` plus `rebuild_clients` is what clears the client and its ROI row. A new deletion path must do both.
- **Expiry leaves identifiers.** `revoke_expired_consent` clears `housing_release_status` and `consented_coc_codes` only. `consent_form_id` and `consent_form_signed_on` stay, so `active_consent_form` still resolves after expiry. Use `consent_form_valid?`, not the association, to test for a valid release.
- **Revoked under `Consent::Default`.** The revoked string is the empty string, which `where(housing_release_status: nil)` misses. `ExpiringConsentController` matches both `nil` and `''`.
- **Housing release statuses job.** `UpdateHousingReleaseStatuses` is not scheduled. It runs when an admin changes `roi_model`. Day-to-day expiry is `revoke_expired_consent` in the nightly import.
- **VI-SPDAT.** Un-confirming `housing_release_confirmed` restores the `consent_type` of the active consent file only if that file is confirmed and not past its expiration. Otherwise it blanks the status, and the rebuild then removes the row.
- **Duration mapping has several copies.** `Client.consent_validity_period`, `Client#consent_expiration_date` (the expiring-consent report), and `roi_expiry_date` in the rebuild task. Change them together. `consent_validity_period` raises for `Use Expiration Date`.
- **HMIS has no consent feature.** The HMIS application under `drivers/hmis` does not use ROIs; consent is warehouse-only.

## Consent from ETO

Some installations record the release in ETO instead of uploading a form. The ETO importer copies `consent_confirmed_on`, `consent_expires_on` and `consent_form_status` onto the source-level `HmisClient`, only where the installation's `EtoApiConfig` field mapping names them. The mapping is configuration, so code alone cannot say which installations have ETO consent. HMIS CSV imports carry no consent.

`HmisClient.maintain_client_consent` copies active source consent onto the destination client:

- **Gate:** it runs only when `release_duration` is `Use Expiration Date`. Under the other durations ETO consent stays on `HmisClient` and is never copied, while file-based consent keeps working. The year durations compute expiry from the signature date alone, so copying ETO expiry dates would give two definitions of expired.
- **Newest wins:** a blank destination date is filled from the source. A date is overwritten only when the source date is strictly later, so a source with an earlier expiry never shortens the destination's consent.
- **Result:** when a date changes, `housing_release_status` becomes the full release string and the client is saved with callbacks. Otherwise nothing is written.
- **No CoC scoping:** `consented_coc_codes` and `consent_form_id` are never touched, so ETO consent is never CoC-limited.
- **Re-release:** a destination revoked for expiry keeps its stale dates, so any still-active source row re-releases it on the next pass.
- **Order:** the nightly import calls the reconcile twice, and the second call is a no-op. Duplicate identification runs after both, so after a merge the new destination gets the source's dates the next day. Dates already written to the old destination remain.
- **Audit:** the reconcile saves through ActiveRecord, while the expiry revoke uses `update_all`. Audit history differs between the two directions.

## Settings that change ROI behavior

Most are on `GrdaWarehouse::Config`, edited in `app/views/admin/configs/_roi.haml` and nearby config partials.

| Setting | Effect |
|---|---|
| `roi_model` | `explicit` uses `Consent::Default`; `implicit` uses `Consent::Implied` (`Config.active_consent_class`) |
| `release_duration` | `One Year`, `Two Years`, `Use Expiration Date`, or `Indefinite`; sets the row's `expires_at` |
| `allow_partial_release` | Offers the partial release option on consent forms |
| `window_access_requires_release` | Legacy only: window data sources need an ROI |
| `auto_confirm_consent` | Uploaded consent forms count without a separate confirmation |
| `consent_visible_to_all` | Consent files are visible to all users who can see the client |
| `show_partial_ssn_in_window_search_results` | Partial SSN in search results |
| `multi_coc_installation` | Reports default to the user's CoCs |
| `verified_homeless_history_method` | `:release` limits verified homeless history to clients with a release in the user's CoCs |
| `client_dashboard` | Dashboard layout; see [Client Dashboards](client-dashboards.md) |
| `DataSource#obey_consent` | A source client is exposed through an ROI only when its data source obeys consent |

## What grants visibility

Each consent class lists the row statuses that grant visibility in `visible_roi_statuses`.

| Consent class | `housing_release_status` | Row status | Visible through ROI |
|---|---|---|---|
| `Consent::Default` | `Full HAN Release` | `full` | yes |
| `Consent::Default` | `Limited CAS Release` | `partial` | no (CAS only) |
| `Consent::Default` | blank | no row | no |
| `Consent::Implied` | `Expanded Consent` | `full` | yes |
| `Consent::Implied` | `Implied Consent` | `partial` | yes, except the dashboard gate |
| `Consent::Implied` | `Consent Revoked` | `revoked` | no |

Under `Consent::Implied`, the partial release string is the implied consent itself (`partial_release_string == no_release_string`). `Client.invalidate_consent!` resets a client to `Implied Consent` rather than blank.

`ClientRoiAuthorization.visible_in_cocs` also requires:

- **Dates:** `starts_at` on or before today and `expires_at` on or after today. Both are checked at query time, so an expiry does not wait for a rebuild. A release is valid on its expiration date and expired the day after; the nightly task, `revoke_expired_consent`, and `consent_form_valid?` use the same boundary.
- **CoC:** the row's `coc_codes` is blank, includes `All CoCs`, or intersects `user.coc_codes`.

Under `Consent::Implied`, `consent_view_permission` also changes which enrollments show on the dashboard. A client with revoked consent needs `can_view_clients`; any other client needs `can_view_client_enrollments_with_roi`.

## Access-control users

Two role permissions use ROIs, each granted through a collection like any other permission:

- `can_search_clients_with_roi`: the client appears in search.
- `can_view_client_enrollments_with_roi`: the client and their enrollments are viewable.

In both cases the source client's data source must have `obey_consent`, and the destination client must have a `visible_in_cocs` row.

These checks all apply that rule:

| Check | Where |
|---|---|
| Search results | `ClientAccessControl::EnrollmentArbiter#searchable_client_scope` → `enrollments_from_rois` |
| Client and enrollment lists | `EnrollmentArbiter#visible_client_scope`, `#enrollments_visible_to` |
| Detail pages and supplemental data | `SourceClientPolicy#can_view?`, `#can_view_supplemental_data?` via `ClientRoiLoader` |
| Dashboard gate | `Client#show_demographics_to?` (`visible_because_of_release?`) via `ClientRoiLoader#full_release?`; needs a `full` row and `can_view_client_enrollments_with_roi` on any project, not on one where the client is enrolled. `ClientsController#assessment` authorizes on this gate alone |

Access that does not come from an ROI does not depend on `obey_consent`: project access through a collection, authoritative data sources assigned to the user, and direct client assignment.

## ROI-only access by release duration

What an access-control user sees when their only route to a client is `can_search_clients_with_roi` or `can_view_client_enrollments_with_roi`. Assumes the source data source obeys consent and the release covers the user's CoCs. The ROI parity spec (`roi_visibility_parity_spec.rb`, "release duration matrix") checks every cell.

- **all:** search, client and enrollment lists, detail pages, and the dashboard.
- **except dashboard:** everything in **all** except the dashboard (`show_demographics_to?`). Dashboard sub-tabs that load the client through the search scope stay reachable by URL for users who also hold the tab's own permission (for example `can_manage_window_client_files` for files). Search-level pages such as `clients#simple` and `notes#alerts` need only search access.
- **none:** hidden everywhere.
- **(→ implied):** the task cleared the release, and the client fell back to implied consent.

A missing date only matters when the duration computes expiry from it: the signature date under `One Year` and `Two Years`, the expiration date under `Use Expiration Date`. `Indefinite` never expires.

Changing the release duration to a dated one therefore clears consent, at the next nightly run, for every client whose release lacks the date the new duration needs. Changing the setting back does not restore it: the task reads only the client's consent columns. The consent files are kept, and re-confirming a client's consent file restores the release. The release duration field on the admin config page states this.

### `Consent::Implied`

| Duration | Implied consent only | Full, signed, with expiration | Full, no signature date | Full, no expiration date | Full, expired |
|---|---|---|---|---|---|
| Indefinite | except dashboard | all | all | all | all |
| Use Expiration Date | except dashboard | all | all | except dashboard (→ implied) | except dashboard (→ implied) |
| One Year | except dashboard | all | except dashboard (→ implied) | all | except dashboard (→ implied) |
| Two Years | except dashboard | all | except dashboard (→ implied) | all | except dashboard (→ implied) |

### `Consent::Default`

| Duration | No release | Full, signed, with expiration | Full, no signature date | Full, no expiration date | Full, expired |
|---|---|---|---|---|---|
| Indefinite | none | all | all | all | all |
| Use Expiration Date | none | all | all | none | none |
| One Year | none | all | none | all | none |
| Two Years | none | all | none | all | none |

The parity spec also checks three cases outside these tables. A release on its expiration date is **all** under `One Year` and `Use Expiration Date`, the durations where the fixture falls on that date. A release signed 18 months ago is **all** under `Two Years` and expired under `One Year`. An expired release with no `consent_form_id` (ETO) is **none** under every time-based duration, under both classes.

A partial (CAS-only) release under `Consent::Default` grants nothing in the warehouse. Revoked consent grants nothing under either class.

## Legacy role-based users

Legacy code paths are marked `START_ACL` and read the client columns, not `ClientRoiAuthorization`.

- `EnrollmentArbiter#consent_sub_query` applies an ROI to clients in data sources that obey consent or that the user can view.
- `can_search_own_clients` turns off ROI-based search results.
- Window data sources (`visible_in_window`) are visible to users with `can_view_clients`, unless `window_access_requires_release` is on. In that case they need an ROI.
- `can_search_all_clients` bypasses the arbiter in `Client.searchable_to`.
- `SourceClientPolicy#add_legacy_data_source_permissions` applies the window rules to PII. When `window_access_requires_release` is on, it checks `roi_authorized?`, which reads the ROI row.

## Client search variants

All search results come from `Client.searchable_to(user)`.

- **Entry gate:** `require_can_access_some_client_search!` uses `can_access_some_client_search?`:
  - access controls: `can_search_own_clients` or `can_search_clients_with_roi`
  - legacy: window, strict, or own-client search
- **Strict search:** `can_use_strict_search` sends the user to `perform_strict_search` in `ClientAccessControl::ClientsController`.
- **Text search:** otherwise text search, which needs `can_search_own_clients`, or legacy window search.
- **Partial SSN:** shown when `show_partial_ssn_in_window_search_results` is on or the user has `can_view_full_ssn`.

## Client dashboards

See [Client Dashboards](client-dashboards.md) for layout (`default`, `boston`, `va`) and detail level (full or limited).

- **Show page:** `/clients/:id` first passes `require_can_see_this_client_demographics!`, which calls `show_demographics_to?`. It then loads the client through `Client.destination_visible_to`.
- **Sub-tabs:** the controllers under `app/controllers/clients/` (files, notes, enrollment history, youth, and others) load the client through `ClientDependentControllers#destination_searchable_client_scope`, plus each tab's own permission.
- **Rollups:** enrollment rollups intersect `Enrollment.visible_to`. Under `Consent::Implied`, `scope_for_residential_enrollments` and `scope_for_other_enrollments` also filter by `consent_view_permission`.
- **Releases tab:** needs `can_use_separated_consent`. The files shown come from `ClientFile.visible_by?`.
- **Supplemental data tab:** uses `SourceClientPolicy#can_view_supplemental_data?`.
- **Implied consent layout:** installations that use `Consent::Implied` use the `va` layout (`drivers/client_access_control/app/views/client_access_control/clients/va`).

## Reporting

- **HUD reports ignore consent.** `HudFilterBase#apply` uses `tags: [:hud]`, which leaves out the ROI filter.
- **Active ROI filter.** `Filters::Criteria::FilterForActiveRoi` is opt-in through the `active_roi` filter attribute. It reads the client column scope `consent_form_valid`.
- **PII in reports.**
  - `User#reporting_policy_for_client` uses the client policy, so ROIs apply.
  - `User#reporting_policy_for_project` (`ProjectPiiPolicy`) does not consider ROIs.
  - Cohort PII policies do not check ROIs.
- **CAS** uses both full and partial releases (`CasClientData`).

## Rebuild and lookup behavior

- **Locking.** The nightly and bulk rebuilds run under an advisory lock with no wait, so a concurrent run skips. A batch is retried once on a deadlock, for example against a client merge. `rebuild_clients` takes neither the lock nor the retry.
- **Implied-consent second pass.** Under `Consent::Implied`, a client whose consent is cleared is processed again, because the reset to `Implied Consent` needs a `partial` row. Without that pass the client is hidden from ROI-only users until the next rebuild.
- **Spec tip.** A spec that writes consent columns with `update_columns` must call `rebuild_clients` before checking visibility.
- **Preloading.** `ClientRoiLoader` is memoized per request or job, keyed by destination client id. List views that check visibility per row need `user.policy_context.preload_client_dependencies(client_ids)` first. `show_demographics_to?` reads the same loader.
- **Memoized arbiter.** `EnrollmentArbiter` memoizes the obey-consent data source ids, and one arbiter is reused per user object. Specs that flip `obey_consent` need a fresh user object.
- **User CoCs.** `user.coc_codes` is cached for a minute and comes from the user's collections (access controls) or access groups (legacy). It does not come from `ConsentLimit`.
- **`ConsentLimit`.** Rows (a CoC code such as `ZZ-000`) are only the option list for the CoC select on consent forms. `AgenciesConsentLimit` links them to agencies for display. Neither changes a user's effective CoCs.
- **Windows under access controls.** Window data sources and `window_access_requires_release` are legacy. Under access controls, a system collection of window data sources replaces them. For new work, grant `can_view_client_enrollments_with_roi` or `can_search_clients_with_roi` on a collection.
- **Deciding visibility.** New access-control checks should use `visible_in_cocs` plus the `obey_consent` check (as `ClientRoiLoader` does), or `user.policy_for(source_client).can_view?`. Do not read the client columns, `ClientRoiAuthorization.active`, `consent_form_valid?` or `can_view_client_enrollments_with_roi?` alone.
- **Row is derived.** Do not write `ClientRoiAuthorization` rows directly. Write consent through `ClientFile` and the client columns, then call `rebuild_clients`.
- **CAS.** `PushClientsToCas` sends `housing_release_status` through `release_status_for_cas` and `consent_form_signed_on` as the release date. The status is `None on file` when blank, and `Expired` under `One Year` or `Use Expiration Date` when the form is not valid and confirmed.

## Known gaps

- `Client#consent_form_valid?` and `Client#release_valid?` (without `coc_codes`) accept only the full release string, so under `Consent::Implied` they reject `Implied Consent`. The `consent_form_valid` scope accepts it.
- Legacy scope code reads the client columns, while legacy policy code reads the ROI row.
- `FilterForActiveRoi` does not match CoCs or check `obey_consent`.
- `SourceClientsController` and `Clients::ExternalDataSharingController` load clients without a visibility scope and rely on `can_create_clients` and `can_edit_clients`.
