# HMIS Restricted Records

`hmis_restricted_records` marks individual HMIS records as **restricted**, so visibility can be limited to staff with the appropriate permission. The table was introduced to support **restricted clients**, with the intention to expand the same pattern to other record types later (for example case notes or assessments).

An active (non-deleted) row means the associated record is restricted. Soft-deleting the row clears the restriction.

## Use Cases

- **Restricted clients**: Hide clients from staff who lack `can_view_restricted_clients` at a project where the client is or was enrolled. Users with that permission (plus `can_view_clients`) can see the client; users without it cannot.
- **Future record types**: The polymorphic `restrictable` association is designed so additional HMIS models can be marked restricted without a new table per type. Potential future use-cases:
  - **CustomAssessment**: Ability to mark a specific Assessment as restricted.
  - **FormDefinition**: Ability to mark a specific Form as restricted, for example an assessment Form that collects particularly sensitive data.
  - **Project**: Ability to mark a specific Project as restricted (potentially similar to Confidential project designation on the Warehouse, needs more discovery)

## Behavior for Restricted Clients

Not yet implemented

## Architecture

- **`Hmis::RestrictedRecord`**: ActiveRecord model for the table
- **`Hmis::Concerns::Restrictable`**: Included on restrictable models (`Hmis::Hud::Client` today). Provides `restricted?`, `mark_as_restricted!`, and `remove_restriction!`.
