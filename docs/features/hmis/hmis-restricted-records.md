# HMIS Restricted Records

`hmis_restricted_records` marks individual HMIS records as **restricted**, so visibility can be limited to staff with the appropriate permission. The table was introduced to support **restricted clients**, with the intention to expand the same pattern to other record types later (for example case notes or assessments).

An active (non-deleted) row means the associated record is restricted. Soft-deleting the row clears the restriction.

## Use Cases

- **Restricted clients**: Keep clients out of client search, and redact their PII, for staff who lack `can_view_restricted_clients` at a project where the client is or was enrolled. See below.
- **Future record types**: The polymorphic `restrictable` association is designed so additional HMIS models can be marked restricted without a new table per type. Potential future use-cases:
  - **CustomAssessment**: Ability to mark a specific Assessment as restricted.
  - **FormDefinition**: Ability to mark a specific Form as restricted, for example an assessment Form that collects particularly sensitive data.
  - **Project**: Ability to mark a specific Project as restricted (potentially similar to Confidential project designation on the Warehouse, needs more discovery)

## Behavior for Restricted Clients

Restricted clients don't appear in client search unless you have permission to find them. If you have other ways of finding the client, such as a direct link or by navigating from a project where they're enrolled, you still see them, but their PII (name, DOB, SSN, photo, and contact info) is redacted.

Restriction is deliberately *not* a denial of access. A restricted client remains a normal, viewable client: their enrollments, households, assessments, services, and files resolve as they would otherwise, and every permission other than the ones listed below behaves the same whether or not the client is restricted.

Restriction is expected to apply to a small fraction of clients in a data source — it's for the occasional client whose record needs extra protection, not a bulk visibility mechanism. The implementation relies on that: excluding restricted clients from search loads every restricted client ID in the data source.

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

## Architecture

- **`Hmis::RestrictedRecord`**: ActiveRecord model for the table.
- **`Hmis::Concerns::Restrictable`**: Included on restrictable models (`Hmis::Hud::Client` today). Provides `restricted?`, `mark_as_restricted!`, and `remove_restriction!`.
- **`Hmis::AuthPolicies::UserContext`**: Owns the visibility rule. `pii_redacted_for_client?` answers it for one client, and `search_hidden_client_ids` applies it to every restricted client in the data source to back the search exclusion.
- **`Hmis::AuthPolicies::ContextLoaders::RestrictedClientLoader`**: Bulk-loads restriction status, so authorizing a page of clients takes one query. Wired into `UserContext#preload_client_dependencies`, which GraphQL already calls when loading clients.
