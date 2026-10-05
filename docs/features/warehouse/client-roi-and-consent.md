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
- for changed clients, from `UpdateHousingReleaseStatuses`. This goes through the task-wide lock and is skipped while the nightly run holds it.
- nightly, for every destination client

ETO consent (`HmisClient.maintain_client_consent`) only grants consent. It reaches the table at the next nightly run. It sets no `consent_form_id`, and the nightly run only invalidates expired releases that have one. An expired ETO release therefore keeps its expired `full` row, and the client is hidden on every ROI path (not shown with implied consent) until `revoke_expired_consent` clears the columns and a later rebuild runs.

Each rebuild reads its clients with row locks (`SELECT ... FOR UPDATE`, in id order) held until it commits. A consent column write therefore waits for any rebuild of that client, and a rebuild always reads the latest committed consent.

| Client columns | Row status |
|---|---|
| Revoked consent (`Client#revoked_consent?`), even with no signature date | `revoked`, with no `starts_at` or `expires_at` |
| `Implied Consent` under `Consent::Implied`, under every `release_duration` | `partial`, with no `starts_at` or `expires_at` |
| The consent class's partial release string | `partial` |
| The consent class's full release string | `full` |
| Anything else; a missing signature date under `One Year`/`Two Years`; a missing expiration date under `Use Expiration Date` | no row (and the task clears the consent columns; under `Consent::Implied` the client falls back to implied consent) |

`ClientRoiAuthorization.visible_in_cocs(coc_codes)` is the ROI rule for access-control visibility and for `SourceClientPolicy`. Legacy scope code still reads the client columns through `Client.active_confirmed_consent_in_cocs`.

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

## Known gaps

- `Client#consent_form_valid?` and `Client#release_valid?` (without `coc_codes`) accept only the full release string, so under `Consent::Implied` they reject `Implied Consent`. The `consent_form_valid` scope accepts it.
- Legacy scope code reads the client columns, while legacy policy code reads the ROI row.
- `FilterForActiveRoi` does not match CoCs or check `obey_consent`.
- `SourceClientsController` and `Clients::ExternalDataSharingController` load clients without a visibility scope and rely on `can_create_clients` and `can_edit_clients`.
