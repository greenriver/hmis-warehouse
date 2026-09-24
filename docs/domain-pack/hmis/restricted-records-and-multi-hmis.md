---
title: HMIS client merges, restricted records, and multi-HMIS hosting
summary: "Three cross-cutting HMIS behaviors. MergeClientsJob and its undo with audit history; RestrictedRecord plus the Restrictable concern that redacts PII and hides clients from search; and multi-HMIS support where the request host binds to a data source, with the hmis_go_live_at gate."
area: hmis
tags: [hmis, client-merge, MergeClientsJob, UndoMergeClientsJob, ClientMergeAudit, ClientMergeHistory, RestrictedRecord, Restrictable, pii_redacted_for_client?, client_ids_hidden_from_search, searchable_to, RestrictedClientLoader, multi-hmis, current_hmis_host, attach_data_source_id, hmis_data_source_id, hmis_go_live_at, hmis_access_error_for]
sources:
  - drivers/hmis/app/jobs/hmis/merge_clients_job.rb
  - drivers/hmis/app/jobs/hmis/undo_merge_clients_job.rb
  - drivers/hmis/app/models/hmis/client_merge_audit.rb
  - drivers/hmis/app/models/hmis/client_merge_history.rb
  - drivers/hmis/app/graphql/mutations/merge_clients.rb
  - drivers/hmis/app/models/hmis/restricted_record.rb
  - drivers/hmis/app/models/hmis/concerns/restrictable.rb
  - drivers/hmis/app/models/hmis/auth_policies/user_context.rb
  - drivers/hmis/app/models/hmis/auth_policies/context_loaders/restricted_client_loader.rb
  - drivers/hmis/app/models/hmis/auth_policies/hmis_client_policy.rb
  - drivers/hmis/app/graphql/mutations/set_client_restricted.rb
  - drivers/hmis/app/models/hmis/hud/client.rb
  - drivers/hmis/app/controllers/hmis/base_controller.rb
  - drivers/hmis/app/controllers/hmis/concerns/request_data_source.rb
  - drivers/hmis/app/controllers/hmis/sessions_controller.rb
  - drivers/hmis/app/controllers/hmis/users_controller.rb
  - drivers/hmis/app/models/hmis/user.rb
  - app/models/grda_warehouse/data_source.rb
related:
  - authorization/hmis-permissions.md
  - warehouse/pii-and-restricted-clients.md
  - warehouse/client-identity.md
---

## Purpose

Three HMIS behaviors that cut across the data model and the authorization layer, all in
`drivers/hmis`:

- **Client merges.** `Hmis::MergeClientsJob` folds several `Hmis::Hud::Client` rows in one data
  source into the oldest one, moves every related record, soft-deletes the rest, and writes an
  audit trail (`Hmis::ClientMergeAudit`, `Hmis::ClientMergeHistory`) that
  `Hmis::UndoMergeClientsJob` can replay in reverse.
- **Restricted records.** `Hmis::RestrictedRecord` marks a record restricted; the
  `Hmis::Concerns::Restrictable` concern adds `restricted?`, `mark_as_restricted!`, and
  `remove_restriction!` to `Hmis::Hud::Client`. A restricted client stays viewable but has PII
  redacted and is dropped from search for users who lack `can_view_restricted_clients` at a
  project where the client is or was enrolled.
- **Multi-HMIS hosting.** One warehouse deployment serves several Open Path HMIS installations,
  each its own `GrdaWarehouse::DataSource` with a domain in `data_sources.hmis`. Each request
  binds `Hmis::User#hmis_data_source_id` from the request host, and
  `data_sources.hmis_go_live_at` blocks non-admins before launch.

Read this doc before touching merge logic, adding a redaction point, adding a new HMIS controller,
or writing any HMIS code that assumes one data source. Permission mechanics (`UserContext`,
policies, `viewable_by`, `hmis_data_source_id` scoping) are in `authorization/hmis-permissions.md`
and are not restated here.

## Entry points

Merges:

- `Mutations::MergeClients` (`drivers/hmis/app/graphql/mutations/merge_clients.rb`) and
  `Mutations::BulkMergeClients` call `Hmis::MergeClientsJob.perform_now(client_ids:, actor_id:)`.
- `Hmis::UndoMergeClientsJob.perform_now(retained_client_id:, deleted_client_id:, dry_run: false)`
  from a Rails console. Not exposed in the UI.
- `mergeAuditHistory` and `mergeCandidates` queries on `Types::HmisSchema::QueryType`, gated by
  `can_merge_clients`; `Hmis::ClientMergeAudit.viewable_by(user)`.

Restricted records:

- `Mutations::SetClientRestricted` (`drivers/hmis/app/graphql/mutations/set_client_restricted.rb`),
  gated by `HmisClientPolicy::Instance#can_mark_restricted?` (`can_mark_clients_as_restricted`).
- `client.restricted?`, `client.mark_as_restricted!(user:)`, `client.remove_restriction!`.
- `Hmis::Hud::Client.searchable_to(user)`: `visible_to` minus
  `user.policy_context.client_ids_hidden_from_search`. Used by `Client.client_search` and the
  `clientOmniSearch` query.
- `Hmis::AuthPolicies::UserContext#pii_redacted_for_client?(client_id)`, read through
  `HmisClientPolicy::Instance#pii_redacted?`.

Multi-HMIS:

- `Hmis::Concerns::RequestDataSource#current_hmis_host` and `#current_data_source`
  (`drivers/hmis/app/controllers/hmis/concerns/request_data_source.rb`).
- `Hmis::BaseController#attach_data_source_id`, declared as a `before_action` in
  `Hmis::GraphqlController`, `Hmis::ImpersonationsController`, and `Hmis::ClientFilesController`.
- `GrdaWarehouse::DataSource.hmis(user = nil)` scope, `#hmis?`, `#hmis_live?`.
- `Hmis::User#hmis_access_error_for(data_source)`, `#can_administer_hmis_in_data_source?`.
- Warehouse side: `User#can_sign_in_to_hmis_data_source?` (`app/models/user.rb`) hides the
  "Open HMIS" menu link for blocked users.

## How it works

### Merges

`Hmis::MergeClientsJob#perform` sorts the clients by `[DateCreated, id]`, keeps the first as
`client_to_retain`, raises unless all share one `data_source_id`, and runs one
`Hmis::Hud::Client.transaction`:

1. `save_audit_trail`: one `Hmis::ClientMergeAudit` (`pre_merge_state` = every client's
   attributes) and one `Hmis::ClientMergeHistory` per deleted client. Histories whose
   `retained_client_id` is now being deleted are repointed to the new retained client.
2. Attribute values come from the warehouse
   `GrdaWarehouse::Tasks::ClientCleanup#choose_attributes_from_sources`, the same picker used for
   destination-client rollup. The retained client is marked restricted if any source was.
3. Names move to the retained client; the one matching the chosen name becomes primary.
4. Custom data elements move by `owner_id`; non-repeating definitions keep the newest.
5. `client_id` keys (`Hmis::File`, `Hmis::Ce::Referral`, `Hmis::ClientAlert`), `PersonalID`
   keys on 18 HUD models scoped by `data_source_id`, MCI IDs, scan cards, and client locations
   move. `GrdaWarehouse::WarehouseClient` rows for deleted clients are destroyed.
6. `dedup` via `equal_for_merge?` on names, contact points, addresses, custom data elements.
   Enrollments are never deduplicated.
7. Soft-delete the rest; mark the retained client's destination dirty for CE when enabled.

Every moved record's prior foreign key is written to `pre_merge_mappings[key][record_id]`;
`ClientMergeAudit::PRE_MERGE_MAPPING_EXPECTED_FIELDS` lists the 13 keys.

`Hmis::UndoMergeClientsJob` requires the `ClientMergeHistory` for the pair, a soft-deleted client,
and mappings present. It clears `DateDeleted`, walks the mappings back, runs
`FixIncorrectPersonalIdReferences` for moved enrollments, destroys the history row, then runs
`SanityCheckServiceHistory`, `IdentifyDuplicates`, and queues service-history processing. It does
not revert retained-client attributes, recreate deduped records, or restore
`ReferralHouseholdMember` or `WarehouseClient` rows.

### Restricted records

`hmis_restricted_records` (`Hmis::RestrictedRecord`, `acts_as_paranoid`, `has_paper_trail`) has a
polymorphic `restrictable`; `RESTRICTABLE_TYPES` is `['Hmis::Hud::Client']` today. An active row
means restricted. `mark!` restores a soft-deleted row if one exists and validates
`data_source_id` matches the record. `unmark!` destroys the row.

`UserContext#pii_redacted_for_client?(client_id)` is the one rule: false unless restricted; true
if the client has no enrollments in the data source (no project through which the permission
could be held); otherwise true unless `client_permissions(client_id)` includes
`can_view_restricted_clients`. `client_ids_hidden_from_search` applies that rule to every
restricted client in the data source (`RestrictedClientLoader#restricted_ids_in_data_source`,
one query) and backs `Client.searchable_to`. `visible_to` is unchanged, so `client(id:)` and
navigation from enrollments still resolve.

Redaction points are the PII predicates on `HmisClientPolicy::Instance` (`can_view_name?`,
`can_view_dob?`, `can_view_full_ssn?`, `can_view_partial_ssn?`, `can_view_contact_info?`,
`can_view_photo?`), each `!pii_redacted? && permission`. `Types::HmisSchema::Client` reads them:
`firstName` returns `Client#masked_name` (`"Client <id>"`), other name parts and `dob`/`ssn` nil,
`names` a single masked entry, photo and contact fields empty, matching `access` booleans false.
`age` is not redacted.

`RestrictedClientLoader` caches per `UserContext`, so per request. `Mutations::SetClientRestricted`
calls `policy_context.clear_client_restriction_cache!` after marking so the response reflects the
change.

### Multi-HMIS

`current_hmis_host` is `request.host` in production and the `X-Hmis-Dev-Host` header in
development (raises if absent). `current_data_source` is
`GrdaWarehouse::DataSource.hmis.find_by(hmis: host)` and raises when unconfigured.
`attach_data_source_id` sets `hmis_data_source_id` on `current_hmis_user` and `true_hmis_user`,
then renders 403 with `hmis_access_error_for(current_data_source)` if it returns an error.
`hmis_data_source_id` is an `attr_accessor`; nothing persists it.

Go-live: `DataSource#hmis_live?` is `hmis_go_live_at.nil? || hmis_go_live_at <= Time.current`.
`Hmis::User#hmis_access_error_for` returns nil when live or when
`can_administer_hmis_in_data_source?` (an access control whose role grants `can_administer_hmis`
and whose Collection reaches an entity in that data source); otherwise `:no_hmis_access`.
`Hmis::SessionsController#create` signs the user back out and returns 403 on that error;
`Hmis::UsersController#show` returns `{ accountError: ... }` via `bootstrap_account_error`. The
check uses `true_hmis_user`, so an admin impersonating a blocked user is not locked out.

## Key files

- `drivers/hmis/app/jobs/hmis/merge_clients_job.rb`: the merge; `pre_merge_mappings` shape in the
  comment on `build_and_update_merge_mappings`; `update_personal_id_foreign_keys` lists the HUD models.
- `drivers/hmis/app/jobs/hmis/undo_merge_clients_job.rb`: header comment lists usage and limitations;
  `CLIENT_ID_FOREIGN_KEY_CANDIDATES`, `PERSONAL_ID_FOREIGN_KEY_CANDIDATES`.
- `drivers/hmis/app/models/hmis/client_merge_audit.rb`: `mappings_for`, `viewable_by`,
  `PRE_MERGE_MAPPING_EXPECTED_FIELDS`.
- `drivers/hmis/app/models/hmis/client_merge_history.rb`: retained/deleted pair; destroyed on undo.
- `drivers/hmis/app/graphql/mutations/merge_clients.rb`: calls the job with `perform_now`.
- `drivers/hmis/app/models/hmis/restricted_record.rb`: `mark!`, `unmark!`, `for_clients`, data-source validation.
- `drivers/hmis/app/models/hmis/concerns/restrictable.rb`: `has_one :restricted_record`, the three instance methods.
- `drivers/hmis/app/models/hmis/auth_policies/user_context.rb`: `pii_redacted_for_client?`,
  `client_ids_hidden_from_search`, `clear_client_restriction_cache!`, `preload_client_dependencies`.
- `drivers/hmis/app/models/hmis/auth_policies/context_loaders/restricted_client_loader.rb`: bulk restriction cache.
- `drivers/hmis/app/models/hmis/auth_policies/hmis_client_policy.rb`: `pii_redacted?` folded into the PII predicates; `can_mark_restricted?`.
- `drivers/hmis/app/graphql/mutations/set_client_restricted.rb`: mark/unmark plus cache clear.
- `drivers/hmis/app/models/hmis/hud/client.rb`: `include Hmis::Concerns::Restrictable`, `searchable_to`, `client_search`, `masked_name`, merge-history associations.
- `drivers/hmis/app/controllers/hmis/concerns/request_data_source.rb`: `current_hmis_host`, `current_data_source`.
- `drivers/hmis/app/controllers/hmis/base_controller.rb`: `attach_data_source_id`, `hmis_access_error`, `bootstrap_account_error`.
- `drivers/hmis/app/controllers/hmis/sessions_controller.rb`, `drivers/hmis/app/controllers/hmis/users_controller.rb`: go-live refusals.
- `drivers/hmis/app/models/hmis/user.rb`: `hmis_data_source_id`, `hmis_access_error_for`, `can_administer_hmis_in_data_source?`, `can_access_hmis_data_source?`.
- `app/models/grda_warehouse/data_source.rb`: `hmis` scope, `hmis?`, `hmis_live?`, hostname validations.

## Gotchas

- Restriction status is a per-request snapshot in `RestrictedClientLoader`. That is intentional.
  The only cache clear is `clear_client_restriction_cache!` in `Mutations::SetClientRestricted`;
  do not add cache busting elsewhere, including long-running exports.
- `client_ids_hidden_from_search` loads every restricted client in the data source and evaluates
  permissions for each. Restriction is meant for a small fraction of clients, not bulk hiding.
- A restricted client with no enrollments is redacted and hidden for everyone, including users
  who hold `can_view_restricted_clients` somewhere. Marking and unmarking still use the normal
  `client_permissions` fallback to global permissions, so the marker can unmark.
- Restriction is not denial: enrollments, assessments, files, alerts, and `age` resolve as usual.
- Merging marks the retained client restricted if any source client was restricted.
- Merges never deduplicate enrollments; two open enrollments in one project after a merge is
  expected and cleaned up by hand.
- `UndoMergeClientsJob` destroys the `ClientMergeHistory` row but keeps the `ClientMergeAudit`.
  It does not revert retained-client attribute changes or recreate records removed by `dedup`.
- `MergeClientsJob` and `UndoMergeClientsJob` mutate `GrdaWarehouse::WarehouseClient` and rely on
  `IdentifyDuplicates` and `ClientCleanup` to reconcile destination clients afterwards.
- `hmis_data_source_id` is transient. Jobs, specs, and console code must assign it before calling
  `policy_for`, `viewable_by`, or `UserContext.new`.
- `current_hmis_host` raises in development without `X-Hmis-Dev-Host`; `request.host` is not used
  there because the dev proxy rewrites it.
- `data_sources.hmis` must be in `HmisEnforcement.configured_hmis_hostnames` and is immutable once
  set (`hmis_hostname_immutable`).
- The go-live gate runs in `attach_data_source_id`, `Hmis::SessionsController#create`, and
  `Hmis::UsersController#show`. A new HMIS controller that skips `attach_data_source_id` is not gated.
- Known gaps as of 2026-09: configuration tables not yet scoped by `data_source_id`, user lists not
  filtered to the current data source, no per-data-source CoC management, no per-instance name and
  theme.

## Do not repeat

- Permission or scope checks that ignore `hmis_data_source_id`. `Hmis::User#can_x?` and
  `can_x_for?` answer across all data sources. Replace with an instance or global policy via
  `user.policy_for(...)`, or a `viewable_by(user)` scope. Example of the replacement:
  `Mutations::SetClientRestricted` (`viewable_by` then `can_mark_restricted?`).
- Loading HMIS records with `find` and no data-source filter, then authorizing. Replace with
  `Model.viewable_by(user).find_by(id:)`. Detail in `authorization/hmis-permissions.md`.
- Adding a restriction bypass in a resolver or type, such as reading `object.first_name` directly
  or checking `client_permissions.include?(:can_view_client_name)` without `pii_redacted?`. Every
  PII field must go through the `HmisClientPolicy::Instance` predicate; see
  `Types::HmisSchema::Client#first_name` for the pattern.
- Hiding restricted clients with an ad hoc `where.not(id: ...)` in a new search path. Use
  `Client.searchable_to(user)`, which derives from `pii_redacted_for_client?` so search and
  redaction cannot drift.
- Calling `Hmis::RestrictedRecord.create!` or `destroy!` directly. Use
  `client.mark_as_restricted!(user:)` / `remove_restriction!` so restore-if-deleted and
  data-source validation apply.
- Moving client-owned records in a merge without writing `pre_merge_mappings`. Add the key to
  `ClientMergeAudit::PRE_MERGE_MAPPING_EXPECTED_FIELDS` and a restore step in
  `UndoMergeClientsJob`, or the undo silently skips those records.
- Repo-wide patterns are in `conventions/do-not-repeat.md`.

## Related

- `authorization/hmis-permissions.md`: `UserContext`, `client_permissions`, `viewable_by`,
  `hmis_data_source_id` scoping, Collection reach.
- `authorization/hmis-graphql-authorization.md`: where `viewable_by` and `authorized?` belong in
  the GraphQL layer.
- `warehouse/pii-and-restricted-clients.md`: warehouse-side redaction and search exclusion for
  HMIS-restricted clients.
- `warehouse/client-identity.md`: `WarehouseClient`, `IdentifyDuplicates`, `ClientCleanup`, and
  `choose_attributes_from_sources`.
- Human-facing source docs: `docs/features/hmis/hmis-client-merges.md`,
  `docs/features/hmis/hmis-restricted-records.md`, `docs/features/hmis/multi-hmis-support.md`.
