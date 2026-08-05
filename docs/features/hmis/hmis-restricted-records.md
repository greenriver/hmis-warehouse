# HMIS Restricted Records

`hmis_restricted_records` marks individual HMIS records as **restricted**. The table was introduced to support **restricted clients**, with the intention to expand the same pattern to other record types later (for example case notes or assessments).

An active (non-deleted) row means the associated record is restricted. Soft-deleting the row clears the restriction.

## Use Cases

- **Restricted clients**: Keep clients out of client search (and mask identity fields on resolve) for staff who lack `can_view_restricted_clients` at a project where the client is or was enrolled. This is **not confidentiality** — staff who reach the client through enrollments, households, or a direct link still see project records under normal permissions.
- **Future record types**: The polymorphic `restrictable` association is designed so additional HMIS models can be marked restricted without a new table per type. Potential future use-cases:
  - **CustomAssessment**: Ability to mark a specific Assessment as restricted.
  - **FormDefinition**: Ability to mark a specific Form as restricted, for example an assessment Form that collects particularly sensitive data.
  - **Project**: Ability to mark a specific Project as restricted (potentially similar to Confidential project designation on the Warehouse, needs more discovery)

## Behavior for Restricted Clients

Restricted clients use a **hybrid** model: hide from search, mask PII on resolve.

* **Search**: Restricted clients are omitted from `searchable_to` (client search, omni search, find-client flows) unless the user has `can_view_clients` **and** `can_view_restricted_clients` at an overlapping enrollment project.
* **Direct resolve / enrollments / households**: `visible_to` and enrollment `viewable_by` are **not** filtered by restriction. Restricted clients remain listable and resolvable under normal project permissions.
* **PII masking**: When a restricted client is resolved and the user cannot unlock them, name/DOB/SSN/age are masked the same way as lacking those PII permissions. Unlock uses the same overlapping-project rule as search.
* **Unenrolled restricted clients**: Omitted from search; resolvable like other unenrolled clients; PII stays masked (there is no enrollment project that can unlock them).
* **Marking a Client as Restricted**: Requires `can_mark_clients_as_restricted` (which requires `can_view_restricted_clients`). Marking does **not** make the client confidential in project workflows.
* **Merging Restricted Clients**: If any merged client is restricted, the retained client is marked restricted.

**Not a full hide.** Enrollments, assessments, case notes, and other project records remain available under normal permissions. Restriction is also not a guarantee that identity cannot be inferred from non-PII fields.

Warehouse report/PII redaction based on this table is out of scope for the initial HMIS feature, but is planned as future work (#9479).

## Architecture

- **`Hmis::RestrictedRecord`**: ActiveRecord model for the table; `restricted_client_ids` returns active client restrictable IDs.
- **`Hmis::Concerns::Restrictable`**: Included on restrictable models (`Hmis::Hud::Client` today). Provides `restricted?`, `mark_as_restricted!`, and `remove_restriction!`.
- **Search hide**: `Hmis::Hud::Client.searchable_to` starts from `visible_to` and excludes restricted clients the user cannot unlock. `visible_to` / `files_viewable_by` are unchanged.
- **Policy**: `Hmis::AuthPolicies::HmisClientPolicy` restores `can_mark_restricted?` and locks name/DOB/SSN/age via `restricted_pii_unlocked?` (overlapping enrollment + `can_view_restricted_clients`; no global fallback for unenrolled restricted clients).
- **GraphQL**: `SetClientRestricted` mutation toggles the flag; client types expose a `restricted` field and resolve PII through the client policy.
