# Client Data Retention

Aging out of client data for warehouse identities that have had no activity for a configurable
number of years. Phase 1 marks and hides; nothing is overwritten or deleted. The position and its
trade-offs are in [ADR 0009](../../adr/0009-client-data-retention-and-removal.md).

## Settings

- **Global window**: `GrdaWarehouse::Config` `client_retention_years`. `nil` (the default) turns the
  whole feature off. The admin form offers 7 through 20 years; HUD requires at least seven. Any
  positive whole number is valid so a shorter window can be set from the console, and the form
  includes that value so re-saving the page keeps it.
- **Per data source override**: `GrdaWarehouse::DataSource` `client_retention_years`, same rule,
  `nil` means "use the global window". The field is only shown when the global window is set.

## What counts as activity

`GrdaWarehouse::InactiveClient.rollup_activity` computes, per destination client, one activity
date from the source clients linked through a live (`deleted_at IS NULL`) `warehouse_clients`
row. Which fields count depends on whether the identity has an open enrollment:

- **No open enrollment** (every `Enrollment` has a live `Exit`, or there are no enrollments):
  the latest of `Exit.ExitDate` and `Client` DateUpdated. Nothing else recorded after an exit
  counts.
- **An open enrollment anywhere in the identity**: the latest of `Client` DateUpdated,
  `Enrollment` EntryDate and DateUpdated, `Exit` ExitDate on the other enrollments,
  `Services` DateProvided, `CurrentLivingSituation` InformationDate and `IncomeBenefits`
  InformationDate. These are the fields every project type keeps writing during a stay.
Rows with `DateDeleted` set are ignored (a soft-deleted `Exit` leaves its enrollment open, and a
soft-deleted source `Client` contributes nothing and is not marked). Dates after today are ignored.
An identity with no enrollments and no `Client` DateUpdated on any source has no activity date at
all: it is skipped entirely, never marked, never unmarked, and not included in the run's
evaluated count. The expiring-soon report shows which rule applied as the
"Basis" column.

## Window rule

The window for an identity is the **longest** among its source data sources, each using its
override or falling back to the global window. A client in a 7-year and a 10-year data source ages
out at 10; a client only in a 7-year data source ages out at 7 even when the global is 10. An
identity is inactive when its newest activity is strictly older than today minus that window.

## Nightly job

`ClientRetentionJob` is enqueued from `Importing::RunDailyImportsJob` after service history is
generated, at maintenance priority on the long-running queue, under an advisory lock and a
maintenance-task record. It does nothing when the global window is `nil`. Each run:

1. Creates a `GrdaWarehouse::ClientRetentionRun` with the global window and a snapshot of the data
   source overrides.
2. Evaluates destinations in batches, inserting one `inactive_clients` row per source client of
   an aged-out identity (unique on `client_id`, so existing rows are left alone) and deleting rows
   for sources of evaluated identities that are not aged out, including a marked source that has
   since moved into an active identity.
3. Logs `marked` and `unmarked` entries in `client_retention_log_entries` with plain identifiers
   (warehouse ids, data source ids, PersonalIDs) and never names, SSN or DOB.
4. Records evaluated, marked and unmarked counts on the run.

## Sizing before enabling

`GrdaWarehouse::ClientRetentionDryRun` runs the same batches and rollup as the nightly job and
writes nothing. From a console:

    GrdaWarehouse::ClientRetentionDryRun.new(global_years: 7).run
    GrdaWarehouse::ClientRetentionDryRun.new(global_years: 7).explain

`run` returns destination and batch counts, total and slowest-batch seconds, evaluated and
would-mark counts by basis, and a sample of destination ids that would be marked. `explain`
returns `EXPLAIN (ANALYZE, BUFFERS)` for one job-sized batch. Pass `limit:` for a quick sample.

## What "hidden" means

A source client in `inactive_clients`, and every destination it is linked to through a live
`warehouse_clients` row, is treated exactly like an HMIS-restricted client on the warehouse side
(`GrdaWarehouse::HiddenClients`); see [Warehouse Auth Policies](warehouse-auth-policies.md#client-restriction). PII is redacted
everywhere `PiiProvider` is consulted, name and SSN search skip the client, the Superset
`analytics.client_piis` view and the HMIS CSV export transform redact name and SSN. DOB and exact
id lookups still work. There is no override permission; visibility returns when the identity has
new activity and the next run clears the marks. Disabling the global window stops the job but
leaves existing marks in place; clear them from `inactive_clients` in the console.

## Limitations

- A marked identity touched by an import stays hidden until the next nightly run.
- The OP HMIS frontend does not yet honour these marks. To extend it:
  `Hmis::AuthPolicies::UserContext#pii_redacted_for_client?` should return true for an id in
  `inactive_clients` with no permission override (a per-id or preloaded lookup added to
  `Hmis::AuthPolicies::ContextLoaders::RestrictedClientLoader`), and `Hmis::Hud::Client.searchable_to`
  should anti-join `inactive_clients`.
- A source whose `warehouse_clients` link is removed keeps its mark until it is linked again and
  re-evaluated.
- Nothing is scrubbed or deleted, and a later full historical import re-creates aged-out clients
  until the next run marks them again.
