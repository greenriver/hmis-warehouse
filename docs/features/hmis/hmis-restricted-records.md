# HMIS Restricted Records

`hmis_restricted_records` marks individual HMIS records as **restricted**, so visibility can be limited to staff with the appropriate permission. The table was introduced to support **restricted clients**, with the intention to expand the same pattern to other record types later (for example case notes or assessments).

An active (non-deleted) row means the associated record is restricted. Soft-deleting the row clears the restriction. Restricting a record that was restricted before creates a new row rather than reviving the old one, so that each restriction is captured in PaperTrail history — Paranoia's `restore` writes through `update_columns` and skips PaperTrail. The unique index is partial on `deleted_at IS NULL`, so a restrictable has at most one active row and any number of soft-deleted ones.

## Use Cases

- **Restricted clients**: Keep clients out of client search, and redact their PII, for staff who lack `can_view_restricted_clients` at a project where the client is or was enrolled. See below.
- **Future record types**: The polymorphic `restrictable` association is designed so additional HMIS models can be marked restricted without a new table per type. Potential future use-cases:
  - **CustomAssessment**: Ability to mark a specific Assessment as restricted.
  - **FormDefinition**: Ability to mark a specific Form as restricted, for example an assessment Form that collects particularly sensitive data.
  - **Project**: Ability to mark a specific Project as restricted (potentially similar to Confidential project designation on the Warehouse, needs more discovery)

## Behavior for Restricted Clients

Restricted clients don't appear in client search unless you have permission to find them. If you have other ways of finding the client, such as a direct link or by navigating from a project where they're enrolled, you still see them, but their PII (name, DOB, SSN, photo, and contact info) is redacted.

Restriction is deliberately *not* a denial of access. A restricted client remains a normal, viewable client: their enrollments, households, assessments, services, and files resolve as they would otherwise, and every permission other than the ones listed below behaves the same whether or not the client is restricted.

Restriction is expected to apply to a small fraction of clients in a data source — it's for the occasional client whose record needs extra protection, not a bulk visibility mechanism.

A typical setup for case managers:

- Grant `can_view_clients` **globally** (data-source-wide), so they can open any client record they encounter.
- Grant `can_view_restricted_clients` and `can_view_enrollment_details` only at **their own project**.

With that combination:

- **Search** only returns a restricted client if they are (or were) enrolled at the case manager's project. Restricted clients enrolled only elsewhere are omitted from search results entirely — including lookup by ID or PersonalID.
- **At their own project**, they can see the restricted client's PII and enrollment details (for example by opening the client from an enrollment or from search).
- **Outside their project**, they can still open the client via a direct link or other navigation (global `can_view_clients`), but PII stays redacted and they do not get enrollment details from this permission set.

### Who can view a restricted client

`can_view_restricted_clients` is a project-level permission that requires `can_view_clients`. A user may view a restricted client if they hold both permissions at **any project where the client is or was enrolled**. `UserContext#pii_redacted_for_client?` is the single definition of this rule; both search exclusion and PII redaction are derived from it, so the two can't drift.

**Restricted clients with no enrollments are treated as restricted for everyone**: they are hidden from search, and their PII is redacted, regardless of who is asking. There is no project through which the permission could be granted for such a client, so the rule redacts them without consulting permissions at all.

This is deliberately stricter than the rest of the permission system. `UserContext#client_permissions` normally falls back to the user's global (data-source-wide) permissions for unenrolled clients, which would let anyone holding `can_view_restricted_clients` at any one project find and read every unenrolled restricted client in the data source. Marking and unmarking still uses the normal fallback, so a user who restricts an unenrolled client can still unmark them, but will see their name masked while the restriction is in place.

### Excluded from search

`Hmis::Hud::Client.searchable_to` drops restricted clients the user can't find. This covers both `clientSearch` and `clientOmniSearch`, including lookup by ID and by PersonalID, since those go through the same scope. `visible_to` is unchanged, so the `client(id:)` query and any navigation from an enrollment or project still resolves the record.

### Redacted PII

The PII predicates on `HmisClientPolicy::Instance` (e.g. `can_view_name?`) each fold redaction into the underlying permission. When a restricted client is resolved by a user without the permission `can_view_restricted_clients`:

- Name is masked. `firstName` returns `Client <id>`, the other name parts return null, and `names` returns a single masked entry.
- `dob` and `ssn` return null.
- Photo is not resolved, and contact info (addresses, phone numbers, email) returns empty.
- The matching `access` booleans (`canViewClientName`, `canViewDob`, `canViewPartialSsn`, `canViewFullSsn`, `canViewClientPhoto`) return false, so the frontend renders these the same way it does for a user who simply lacks the permission.

Not redacted: `age`, alerts, and any associated records to the client that the user otherwise has permission to view (e.g. enrollments, assessments, files).

### Downstream effects in the Warehouse

Restricting an HMIS client also redacts their name, SSN, DOB, photo, and HIV status on the warehouse side — the client dashboard, HUD report drilldowns and detail exports, and cohort grids — for every warehouse user, regardless of role, with no override permission, and excludes them from every warehouse-side client search path by name or SSN (DOB and exact-ID/PersonalID lookup still work). See [Warehouse Auth Policies → PII Redaction](../warehouse/warehouse-auth-policies.md#pii-redaction) for how redaction is implemented and its documented coverage limitations, and [Warehouse Auth Policies → Search](../warehouse/warehouse-auth-policies.md#search) for the search exclusion (several warehouse reports and exports are not mediated by either mechanism and will continue to show the client's real PII). The Superset `analytics.client_piis` view redacts name and SSN fields through a separate SQL-level mechanism, described there.

The warehouse applies the same redaction and search exclusion to clients whose identity has aged out under [Client Data Retention](../warehouse/client-data-retention.md); HMIS itself does not yet honour those marks (see that document's limitations).

## Audit Trail

Restricting and unrestricting a client appear on that client's Audit History page as a **Record Restriction** row reading `Restricted: No → Yes` (or the reverse), attributed to the user who performed it. "Record Restriction" is also a Record Type filter option on that page. The same rows show up on the Audit History page for the acting user.

The change shown there is synthesized rather than read off the row. Every column on `hmis_restricted_records` is a foreign key or a timestamp, and Paranoia leaves `deleted_at` nil on both sides of the destroy, so the raw PaperTrail changeset carries no restriction signal at all. `Types::BaseAuditEvent` reports these versions as an `update` to the restrictable's own `restricted` field instead: a `create` version becomes `false → true`, a `destroy` becomes `true → false`. Reporting the restrictable's GraphQL type rather than the restriction's is what lets the front-end resolve the synthesized change against the real `Client.restricted` boolean and render it as Yes/No.

`RestrictedRecord.mark!` creates a new row per restriction rather than reviving a soft-deleted one. That is a requirement of the audit trail, not a preference: Paranoia's `restore` writes through `update_columns`, which bypasses PaperTrail, so the revive itself produced no version. The unique index is scoped to `deleted_at IS NULL`, so the accumulated rows are safe.

Data written before this was in place is patchier. `mark!` used to follow the revive with `update!(created_by: user)`, so what reached the audit trail depended on who acted:

- **Re-restricted by a different user.** `created_by_id` changed, so the `update!` wrote an `update` version. These are on the audit trail and render as `No → Yes`, which is correct.
- **Re-restricted by the same user.** `update!` had nothing to save and wrote no version. These restrictions are unrecoverable.
- **`mark!` called on an already-active row by a different user.** This restricted nothing but still wrote an `update` version, indistinguishable from the first case. It renders as a restrict on a client who was already restricted.

So a legacy `update` version means "a different user called `mark!`". It does not reliably mean "the client became restricted", and nothing on the version narrows it further.

## Architecture

- **`Hmis::RestrictedRecord`**: ActiveRecord model for the table.
- **`Hmis::Concerns::Restrictable`**: Included on restrictable models (`Hmis::Hud::Client` today). Provides `restricted?`, `mark_as_restricted!`, and `remove_restriction!`.
- **`Hmis::AuthPolicies::UserContext`**: Owns the visibility rule. `pii_redacted_for_client?` answers it for one client, and `Hmis::Hud::Client.searchable_to` applies the same rule as a SQL predicate on top of `visible_to` to back the search exclusion, so search cost does not depend on how many clients are restricted.
- **`Hmis::AuthPolicies::ContextLoaders::RestrictedClientLoader`**: Batches restriction status, so authorizing a page of clients takes one query. Wired into `UserContext#preload_client_dependencies`, which GraphQL already calls when loading clients.
