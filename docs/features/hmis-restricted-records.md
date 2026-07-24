# HMIS Restricted Records

`hmis_restricted_records` marks individual HMIS records as **restricted**, so visibility can be limited to staff with the appropriate permission. The table was introduced to support **restricted clients**, with the intention to expand the same pattern to other record types later (for example case notes or assessments).

An active (non-deleted) row means the associated record is restricted. Soft-deleting the row clears the restriction.

## Use Cases

- **Restricted clients**: Hide clients from staff who lack `can_view_restricted_clients` at a project where the client is or was enrolled. Users with that permission (plus `can_view_clients`) can see the client; users without it should not discover the client in search, lists, merge candidates, or related views.
- **Future record types**: The polymorphic `restrictable` association is designed so additional HMIS models can be marked restricted without a new table per type. Potential future use-cases:
  - **CustomAssessment**: Ability to mark a specific Assessment as restricted.
  - **FormDefinition**: Ability to mark a specific Form as restricted, for example an assessment Form that collects particularly sensitive data.
  - **Project**: Ability to mark a specific Project as restricted (potentially similar to Confidential project designation on the Warehouse, needs more discovery)

## Behavior for Restricted Clients

* **Client Visibility**: Restricted clients require `can_view_clients` **and** `can_view_restricted_clients` at an overlapping enrollment project
* **Unenrolled Restricted Clients**: Restricted clients with no enrollments are hidden from everyone (there is no project context to grant access)
* **Marking a Client as Restricted**: Requires `can_mark_clients_as_restricted` (which requires `can_view_restricted_clients`)
* **Merging Restricted Clients**: If any merged client is restricted, the retained client is marked restricted

Restriction is a **full hide** in HMIS (not PII masking). Warehouse report/PII redaction based on this table is out of scope for the initial HMIS feature, but is planned as future work.

## Architecture

- **`Hmis::RestrictedRecord`**: ActiveRecord model for the table
- **`Hmis::Concerns::Restrictable`**: Included on restrictable models (`Hmis::Hud::Client` today). Provides `restricted?`, `mark_as_restricted!`, and `remove_restriction!`.
- **Visibility**: `Hmis::Hud::Client.apply_restricted_visibility` filters scopes such as `visible_to` and `files_viewable_by` using active restricted-client IDs.
- **Policy**: `Hmis::AuthPolicies::HmisClientPolicy` gates view/mark via `can_view_restricted_clients` and `can_mark_clients_as_restricted`.
- **GraphQL**: `SetClientRestricted` mutation toggles the flag; client types expose a `restricted` field.
