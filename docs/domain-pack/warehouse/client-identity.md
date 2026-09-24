---
title: "Client identity: source and destination clients, matching, merge and split"
summary: "Every source client links through GrdaWarehouse::WarehouseClient to one destination client. Covers the 2-of-3 exact matching in IdentifyDuplicates, statistical ClientMatch candidates and their review, merge and split with ClientMergeHistory and ClientSplitHistory, ClientCleanup choosing destination attributes, and the daily job order."
area: warehouse
tags: [client-identity, source-client, destination-client, WarehouseClient, IdentifyDuplicates, IdentifyDuplicatesQueryMatcher, ClientMatch, SimilarityMetric, matching-algorithm, merge, split, merge_from, ClientMergeHistory, ClientSplitHistory, ClientCleanup, choose_attributes_from_sources, SourceClientNameSet, RunIdentifyDuplicatesJob, ensure_source_client_linked!, enable_auto_deduplication]
sources:
  - docs/matching_algorithm.md
  - app/models/grda_warehouse/warehouse_client.rb
  - app/models/grda_warehouse/hud/client.rb
  - app/models/grda_warehouse/tasks/identify_duplicates.rb
  - app/models/grda_warehouse/tasks/identify_duplicates_query_matcher.rb
  - app/models/grda_warehouse/identify_duplicates_log.rb
  - app/models/grda_warehouse/client_match.rb
  - app/models/grda_warehouse/client_merge_history.rb
  - app/models/grda_warehouse/client_split_history.rb
  - app/models/grda_warehouse/source_client_name_set.rb
  - app/models/grda_warehouse/tasks/client_cleanup.rb
  - app/models/similarity_metric/tasks/generate_candidates.rb
  - app/controllers/clients_controller.rb
  - app/controllers/client_matches_controller.rb
  - app/controllers/concerns/client_controller.rb
  - app/jobs/importing/run_identify_duplicates_job.rb
  - app/jobs/importing/run_daily_imports_job.rb
  - drivers/hmis/app/models/hmis/hud/client.rb
related:
  - hmis/restricted-records-and-multi-hmis.md
  - hud-reporting/service-history.md
  - authorization/warehouse-policies.md
  - roi/consent-from-external-sources.md
  - conventions/do-not-repeat.md
---

## Purpose

The warehouse holds one `GrdaWarehouse::Hud::Client` row per person per data source (a
*source client*) and one more row in the warehouse's own data source that stands for the person
(a *destination client*). `GrdaWarehouse::WarehouseClient` is the join: one row per source
client, pointing at exactly one destination. Reports, dashboards, cohorts, service history, and
CAS all key on destination client ids; imports and HMIS write source clients.

Two mechanisms decide which destination a source belongs to:

- `GrdaWarehouse::Tasks::IdentifyDuplicates` links unlinked sources and merges destinations
  when two of three identifiers (SSN, normalized name, DOB) match exactly. It runs nightly, per
  HMIS client on create, and on demand.
- `GrdaWarehouse::ClientMatch` rows are statistical candidates produced by the
  `SimilarityMetric` scoring described in `docs/matching_algorithm.md`. Staff accept or reject
  them in the warehouse UI; configurable thresholds can auto-accept or auto-reject.

Both paths end in `GrdaWarehouse::Hud::Client#merge_from`, which repoints `WarehouseClient`
rows, writes `GrdaWarehouse::ClientMergeHistory` so old ids keep resolving, and queues
`GrdaWarehouse::Tasks::ClientCleanup`. The reverse operation is `Hud::Client#split`, which
writes `GrdaWarehouse::ClientSplitHistory` so the automatic matcher never re-merges the pair.

`ClientCleanup#choose_attributes_from_sources` decides what name, SSN, DOB, race, gender, sex,
and veteran fields the destination shows, using installation configuration for tie-breaking.
The HMIS-side merge (`Hmis::MergeClientsJob`) reuses the same method.

Read this doc before writing any query that should return "a person" rather than "a record",
before touching matching or merge code, and before adding a job that creates or deletes
`Hud::Client` rows. The HMIS-side merge of source clients within one data source is a different
operation and is documented in `hmis/restricted-records-and-multi-hmis.md`.

## Entry points

Linking and automatic merging:

- `GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!`: full pass over unlinked source clients,
  under the `identify_duplicates` advisory lock (5 second wait, then enqueue another full run).
- `GrdaWarehouse::Tasks::IdentifyDuplicates.new.match_existing!`: merges destination clients
  that are 2-of-3 exact duplicates. Gated by `GrdaWarehouse::Config.get(:enable_auto_deduplication)`.
- `GrdaWarehouse::Tasks::IdentifyDuplicates.new.ensure_source_client_linked!(source_client_id)`:
  one source client. Enqueued on the `short_running` queue by
  `Hmis::Hud::Client` `after_commit on: :create`.
- `GrdaWarehouse::Tasks::IdentifyDuplicates.enqueue_full_run!`: enqueues `run!` on the
  `long_running` queue unless one is already queued. Used by `Hmis::Hud::Client.warehouse_identify_duplicate_clients`.
- `Importing::RunIdentifyDuplicatesJob`: a `BaseJob` wrapper around `run!` on the
  `long_running` queue. No caller inside this repository was found.
- `Importing::RunDailyImportsJob#_perform`, `'Identify Duplicates'` task: `run!`,
  `match_existing!`, then `GrdaWarehouse::ClientMatch.auto_process!`.
- Rake: `lib/tasks/grda_warehouse.rake` runs `run!`; `lib/tasks/validate_duplicate_matching.rake`
  runs the matcher with `run_post_processing: false`.

Statistical candidates and review:

- `SimilarityMetric::Tasks::GenerateCandidates.new(batch_size:, threshold:, run_length:).run!`
  from `RunDailyImportsJob#create_statistical_matches` (threshold `-1.45`, 10,000 destinations,
  10 minutes) and `lib/tasks/similarity.rake`.
- `ClientMatchesController` (`/client_matches`, `require_can_edit_clients!`): `index` lists
  candidates, accepted, rejected; `update` calls `accept!` or `reject!`; `defer` bumps
  `defer_count`.
- `GrdaWarehouse::ClientMatch.auto_process!`: accepts and rejects candidates inside the
  configured thresholds when `auto_de_duplication_enabled` is true.

Manual merge and split:

- `ClientsController#merge` (`PATCH /clients/:id/merge`) calls `@client.merge_from`.
- `ClientsController#unmerge` (`PATCH /clients/:id/unmerge`) calls `@client.split`.
- `GrdaWarehouse::ClientMergeHistory.new.current_destination(id)`: follows merge history to the
  live destination id; `ClientController#set_client` and `#set_search_client` redirect with it.

Attribute rollup and cleanup:

- `GrdaWarehouse::Tasks::ClientCleanup.new.run!` (daily, twice) and
  `ClientCleanupJob.perform_later(ids)` -> `ClientCleanup.run_for_clients(ids)`.
- `GrdaWarehouse::SourceClientNameSet.new(source_clients:, user:)`: name aliases for display.

Logs: `GrdaWarehouse::IdentifyDuplicatesLog` at `MatchLogsController` (`/match_logs`,
`require_can_view_imports!`) and on the admin imports dashboard.

## How it works

### Source vs destination

`GrdaWarehouse::DataSource.source` is any data source with a `source_type` or with
`authoritative: true`; `DataSource.destination` is the one with neither. `Hud::Client.source`
and `Hud::Client.destination` filter on `data_source_id` using
`DataSource.source_data_source_ids` and `destination_data_source_ids`, both cached for one hour.

`GrdaWarehouse::WarehouseClient` (`app/models/grda_warehouse/warehouse_client.rb`) has
`source_id`, `destination_id`, `id_in_source` (the source `PersonalID`), `data_source_id` (of the
source), `client_match_id`, review columns (`proposed_at`, `reviewed_at`, `reviewd_by`,
`approved_at`, `rejected_at`; the misspelling is the real column name and it is a string), a
`source_hash` copied from the source client after rollup, and `deleted_at`. The model has
`has_paper_trail` and does not use `acts_as_paranoid`; `ClientCleanup` still sets `deleted_at`
because external analytics tooling reads it.

On `Hud::Client`:

- `has_one :warehouse_client_source` and `has_one :destination_client, through:` (for a source
  row).
- `has_many :warehouse_client_destination` and `has_many :source_clients, through:` (for a
  destination row).
- `destination?` is true when the row has any source clients; `destination?(strict: true)` also
  requires the warehouse data source. `source?` is true when `destination_client` is present.

A destination row is a `dup` of the first source that created it, saved into the warehouse data
source with `apply_housing_release_status` applied. From then on its demographic columns are
owned by `ClientCleanup#update_client_demographics_based_on_sources`, not by imports. The
`WarehouseClient.destination_needs_cleanup` scope finds destinations whose source's
`source_hash` differs from the stored one, which is how nightly rollup knows what changed.

Consequences for queries: a `Hud::Client` id in a URL, cohort, or report is a destination id.
Enrollments, services, and other HUD records hang off source clients by `PersonalID` plus
`data_source_id`. Getting from a destination to its HUD data means going through
`source_clients`; getting from a source to the person means `destination_client`. A query on
`Hud::Client` with no `.source`/`.destination` scope returns both kinds of row.

### Matching

`IdentifyDuplicates` uses one rule: two of three exact matches on SSN, normalized full name, and
DOB. `IdentifyDuplicatesQueryMatcher` holds the filters. SSN must be non-blank, not
`000000000`, `111111111`, `123456789`, not start with `999`, not start or end with `x`, and pass
`HudHelper.util.valid_social?`. Name is `lower(trim(unaccent(...)))` with non-alphanumerics
removed, first and last joined by `_`, both present. DOB must be present with year after 1920.
Each criterion has two shapes: `:existing` compares destination pairs through
`warehouse_clients`, `:unprocessed` compares destinations against unlinked source ids.

The public methods `exact_ssn_matches`, `exact_name_matches`, `exact_dob_matches`, and their
`_for_unprocessed` variants take `legacy: true` by default and run hand-written SQL in the
`_legacy` methods; `legacy: false` routes to `IdentifyDuplicatesQueryMatcher`. Both
implementations exist while the new one is validated; the `validate_duplicate_matching` rake
task compares them.

`identify_duplicates` (called by `run!`):

1. `restore_previously_deleted_destinations`: any destination referenced by a live source's
   `WarehouseClient` but soft-deleted gets `DateDeleted` cleared and a full service history
   rebuild.
2. `unprocessed_ids`: source client ids minus `warehouse_clients.source_id`.
3. `matched_destinations_by_source_id`: pairs with count >= 2, sorted so the highest destination
   id wins when several qualify.
4. `process_unprocessed_batch`: skip sources linked meanwhile; for matched ones build a
   `WarehouseClient` and fill blank SSN, DOB, first and last name on the destination; for the
   rest `dup` a new destination. Bulk import with `on_duplicate_key_ignore`. Mark touched
   destinations dirty for CE (`Hmis::Ce::ChangeMarker`) and invalidate service history for
   matched destinations.
5. `ClientMatch.accept_exact_matches!`, then an `IdentifyDuplicatesLog` row.

`match_existing!` is gated by `enable_auto_deduplication`. `find_merge_candidates_for_match_existing`
collects destination pairs with >= 2 criteria, drops any pair in `ClientSplitHistory`, groups
transitive chains to one root (`group_merge_chains`), and splits chains so no destination
exceeds `MAX_SOURCE_CLIENTS` (50) sources; exceeding it raises in production. Each merge calls
`destination.merge_from(source, cleanup: false)`, then one `ClientCleanupJob` per 500-pair batch.

`ensure_source_client_linked!` runs the same queries for one source, restricted to destinations
sharing its SSN or DOB, and queues a service history rebuild for the touched destination only.

Statistical matching is separate. `SimilarityMetric::Tasks::GenerateCandidates` walks
destinations with no `ClientMatch` row, calls `SimilarityMetric.pairwise_candidates` (z-scored
metrics per `docs/matching_algorithm.md`), writes `candidate` rows with `score` and
`score_details`, and a `processed_sources` self-row marking the destination as scanned.

### Review and merge

`GrdaWarehouse::ClientMatch` has `source_client`, `destination_client`, `status` in
`candidate`, `accepted`, `rejected`, `processed_sources`, a negative `score` (better is more
negative), a serialized `score_details` hash, `defer_count`, and `updated_by`. Despite the
column names, both sides of a `candidate` row are source clients:
`SimilarityMetric.pairwise_candidates(destination)` scores each of the destination's source
clients against other source clients (`merge_candidates`), and `ClientMatch.create_candidates!`
stores the scanned destination's source as `destination_client` and the candidate as
`source_client`. Code that needs the person on either side calls `.destination_client` on the
match's client. The `processed_sources` rows are bookkeeping, not matches; they hold the
scanned destination's id in both columns. Scopes `candidate`, `accepted`, `rejected`, and
`processed_or_candidate` exist for that reason.

Review paths:

- `ClientMatchesController#index` orders candidates by `defer_count`, `score`, `id` and preloads
  each side's current destination. `#update` with `status: accepted` calls
  `ClientMatch#accept!(user:)`; `rejected` calls `#reject!`. `#defer` increments `defer_count`.
- `ClientMatch.auto_process!` (daily) initializes `SimilarityMetric` if no match rows exist,
  then accepts `within_auto_accept_threshold` and rejects `within_auto_reject_threshold`. Both
  scopes return none unless `GrdaWarehouse::Config.get(:auto_de_duplication_enabled)` is true
  and the matching threshold config is non-zero (admin de-duplication page).
- `ClientMatch.accept_exact_matches!` (end of every `identify_duplicates` run, gated by
  `enable_auto_deduplication`) accepts candidates where SSN and DOB match, or two of SSN, DOB,
  exact first and last name match, and destroys candidates whose clients are gone.

`ClientMatch#accept!` flags the row, then calls
`destination_client.destination_client.merge_from(source_client, reviewed_by:, reviewed_at:, client_match_id:)`:
the match's `destination_client` (a source) resolved to its current destination, absorbing the
match's `source_client` (also a source, so only that one `WarehouseClient` row moves).

`Hud::Client#merge_from(other, reviewed_by:, reviewed_at:, client_match_id: nil, cleanup: true)`
raises unless the receiver is a destination. In one transaction it:

1. Finds `other`'s previous destination (its `destination_client`, or `other` itself when it
   is a destination).
2. Repoints every `WarehouseClient` of `other.source_clients`, and `other`'s own
   `warehouse_client_source`, to the receiver, stamping `reviewed_at`, `reviewd_by`, and
   `client_match_id`.
3. Copies CAS columns from the previous destination where the receiver's are blank.
4. If the previous destination has no sources left: writes
   `ClientMergeHistory(merged_into: receiver, merged_from: previous)`, carries forward an
   external-data-sharing exclusion, and destroys it.
5. `move_dependent_items` (notes, files, VI-SPDATs, cohort memberships, CE assessments, custom
   data elements, and the `other` list in `hmis_dependent_items`).
6. `force_full_service_history_rebuild` on the receiver, view cache clears.

Outside the transaction it destroys `processed_or_candidate` match rows for moved clients and,
when `cleanup` is true, queues `ClientCleanupJob`. `ClientsController#merge` and
`ClientMatch#accept!` then run `GrdaWarehouse::Tasks::ServiceHistory::Add` synchronously.
`ClientMergeHistory#current_destination(id)` follows `merged_from -> merged_into` links so a
historical destination id redirects to the current one.

### Split

`Hud::Client#split(client_ids, receiver_id, item_categories, current_user)` runs on a destination
client. `client_ids` are the source clients to detach. For each, inside one transaction:

1. Destroy the source's `warehouse_client_source` row.
2. `dup` the source into a new destination in the warehouse data source.
3. Write `GrdaWarehouse::ClientSplitHistory(split_from: original destination id, split_into: new destination id, receive_hmis: receives_items)`.
4. Create a `WarehouseClient` linking source to the new destination, with `proposed_at`,
   `reviewed_at`, `reviewd_by`, `approved_at` set to now and the acting user.
5. If this source is the chosen `receiver_id`, call `move_dependent_hmis_items(original, new, categories: item_categories)`
   so notes, files, VI-SPDATs, cohort assignments, CE assessments, custom data elements, or
   the `other` group move to the new destination. Only one receiver is allowed; everything not
   moved stays with the original destination.
6. Carry forward an external-data-sharing exclusion from the original destination.

After the transaction it queues `ClientCleanupJob` for the original, each new destination, and
each detached source. `ClientsController#unmerge` then invalidates the original's service
history and runs `ServiceHistory::Add`.

`ClientSplitHistory` is the "never re-merge" record. `IdentifyDuplicates#find_merge_candidates_for_match_existing`
loads every `(split_from, split_into)` pair, sorts each pair, and deletes matching keys from
the 2-of-3 candidate set, so `match_existing!` will not undo a manual split even when all three
identifiers agree. The unprocessed path does not consult split history: a brand-new source that
exactly matches two destinations which were split from each other is attached to one of them,
chosen deterministically (highest destination id), and the reviewer can split again if that
choice was wrong.

The history rows have `belongs_to :destination_client` (`split_into`) and
`belongs_to :source_client` (`split_from`); `Hud::Client` exposes them as `splits_to`
(`split_from` side) and `splits_from` (`split_into` side). The naming is inverted relative to
the column names; read the `foreign_key` before using either association.

A split is not an undo of a specific merge. It does not read `ClientMergeHistory`, does not
restore the destroyed previous destination row, and produces new destination ids, so bookmarks
to the detached clients' old destination keep resolving to the original destination.

### Attribute selection

Destination demographics are recomputed from source clients by
`GrdaWarehouse::Tasks::ClientCleanup#update_client_demographics_based_on_sources`. It picks
destinations from `clients_to_munge`: the explicit `destination_ids` passed to the task, or
every destination whose `WarehouseClient.destination_needs_cleanup` (source `source_hash`
differs from the stored hash). For each, it loads source clients whose data source still
exists, defaults missing data-quality fields to 99 and missing dates to ten years ago, and
calls `choose_attributes_from_sources(dest_attr, source_clients)`:

- `choose_best_name`: among sources with a name, walk `NameDataQuality` 1, 2, 8, 9, 99 and take
  the first non-empty tier; within a tier pick earliest or latest `DateCreated` per
  `GrdaWarehouse::Config.get(:warehouse_client_name_order)` (`earliest` default, `latest`).
- `choose_best_pronouns`: newest `DateUpdated` with a value, else nil.
- `choose_best_ssn`: `GrdaWarehouse::SSNSelector`.
- `choose_best_dob`: `dob_selection_method` config selects `GrdaWarehouse::DOBSelector` with
  `use_oldest: true` (`oldest`) or `false` (`newest`), else the legacy tier walk on
  `DOBDataQuality` with oldest `DateCreated` breaking ties. When no source has a DOB the
  destination's DOB is cleared and quality set to 99.
- `choose_best_veteran_status`: `VeteranStatusCalculator` combines `verified_veteran_status`,
  `va_verified_veteran`, and source values; if 1, veteran detail columns copy from the newest
  source with `VeteranStatus == 1`, otherwise they are nulled.
- `choose_best_gender` and `choose_best_race`: per column, newest source first; a 0 or 1 wins
  and stops the walk; `GenderNone`/`RaceNone` are nulled when any column is 1, else taken from
  the newest source. `DifferentIdentityText` and `AdditionalRaceEthnicity` take the newest
  non-blank value.
- `choose_best_sex`: `GrdaWarehouse::SexSelector` with `prioritization_method: :newest_first`.

A DOB change invalidates the destination's service history. Changed rows are bulk-imported on
`client_columns`, marked dirty for CE, and each source's `source_hash` is copied onto its
`WarehouseClient` so the destination drops out of `destination_needs_cleanup`.

`ClientCleanup#run!` also: soft-deletes source clients in importable, non-HMIS data sources
that have no enrollments (`remove_unused_source_clients`); finds destinations with no live
source (`find_unused_destination_clients`), deletes their service history,
`WarehouseClientsProcessed`, `HmisClient`, and CE proxy rows, marks their `WarehouseClient`
rows `deleted_at`, and soft-deletes the destination; fixes duplicate `HouseholdID`s,
individual/family flags, and ages in service history. Several steps skip when the task ran
within 30 minutes (`recently_ran?`).

`Hmis::MergeClientsJob` calls `ClientCleanup.new.choose_attributes_from_sources` for the
retained HMIS client, so a `choose_best_*` change affects HMIS merges too.

Display: `GrdaWarehouse::SourceClientNameSet` collects `pii_provider(user:).full_name` from
source clients, dropping blanks and duplicates, tagged with data source short name and id.
`GrdaWarehouse::SourceClientViewAccessor#searchable_client_names` and `#viewable_client_names`
build it from the source clients the viewer may see, so the alias list is permission-filtered.

### Daily job

`Importing::RunDailyImportsJob#_perform` runs maintenance tasks in this order; only the ones
that touch identity are listed with what they call:

1. `'Update Client ROIs'`: `Hud::Client.revoke_expired_consent`, then
   `GrdaWarehouse::HmisClient.maintain_client_consent` when `release_duration` is
   `'Use Expiration Date'`.
2. `'Update HMIS forms'`: ends with a second `maintain_client_consent`.
3. `'Sync with CAS'`.
4. `'Identify Duplicates'`: `IdentifyDuplicates.new.run!`, `IdentifyDuplicates.new.match_existing!`,
   `GrdaWarehouse::ClientMatch.auto_process!`.
5. `'Clean projects & clients'`: `ProjectCleanup`, then `GrdaWarehouse::Tasks::ClientCleanup.new.run!`.
6. `'Generate service history and related records'`, chronic calculations, and the rest.
7. `'Finalize client history'`: `ClientCleanup.new.run!` again, then sanity checks.
8. `'System maintenance'`: `create_statistical_matches` runs
   `SimilarityMetric::Tasks::GenerateCandidates` with threshold `-1.45`, batch 10,000, run
   length 10 minutes.

Consent reconciliation runs before identity, so a link or merge made in tonight's run affects
which source's consent lands on the destination tomorrow night. Detail in
`roi/consent-from-external-sources.md`.

Between daily runs, HMIS keeps identity current:

- `Hmis::Hud::Client` `after_commit :warehouse_identify_duplicates_for_new_client, on: :create`
  enqueues `IdentifyDuplicates.new.ensure_source_client_linked!(id)` on the `short_running`
  queue, one job per client. `after_commit` rather than `after_create` because Delayed Job
  writes to a different database and the client row must be committed first.
- `after_update :warehouse_match_existing_clients` enqueues `match_existing!` on the
  `long_running` queue when `FirstName`, `LastName`, `DOB`, `SSN`, or `DateDeleted` changed,
  unless one is already queued.
- `Hmis::Hud::Client.warehouse_identify_duplicate_clients` calls `enqueue_full_run!` for bulk
  producers (`Hmis::CreateFakeEnrollmentsJob`, the AC MCI client import).
  `Hmis::UndoMergeClientsJob` calls `IdentifyDuplicates.new.run!` inline instead.

Concurrency: `run!` and `ensure_source_client_linked!` both take the `identify_duplicates`
advisory lock with a 5 second wait. If the lock is held, they log and call `enqueue_full_run!`
instead of skipping, so an import that overlaps a per-client run is still processed.
`process_unprocessed_batch` re-checks `warehouse_clients` before writing and imports with
`on_duplicate_key_ignore`, so a per-client run that wins the race does not make the full run
raise. `ClientCleanupJob` allows two concurrent instances and re-queues itself one minute out
beyond that.

HMIS CSV imports do not call the matcher directly; new source clients from an import are
picked up as `unprocessed` by the nightly `run!`.

## Key files

- `app/models/grda_warehouse/warehouse_client.rb`: associations, `destination_needs_cleanup`,
  `reset_source_hashes!`.
- `app/models/grda_warehouse/hud/client.rb:108` `warehouse_client_source`, `destination_client`,
  `source_clients`; `:272` `destination`/`source` scopes; `:1645` `destination?`, `source?`;
  `:2274` `split`; `:2349` `merge_from`; `:2477` `move_dependent_items` and
  `hmis_dependent_items`.
- `app/models/grda_warehouse/tasks/identify_duplicates.rb:37` `run!`; `:52`
  `ensure_source_client_linked!`; `:72` `identify_duplicates`; `:132` `match_existing!`; `:246`
  `process_unprocessed_batch`; `:710` `find_merge_candidates_for_match_existing` (split filter,
  chain grouping, `MAX_SOURCE_CLIENTS`); `:874` `restore_previously_deleted_destinations`.
- `app/models/grda_warehouse/tasks/identify_duplicates_query_matcher.rb`: `SSN_FILTERS`,
  `NAME_PRESENCE_FILTERS`, `DOB_FILTERS`, `NORMALIZED_NAME_SQL`, `existing_sql`, `unprocessed_sql`.
- `app/models/grda_warehouse/identify_duplicates_log.rb`: `to_match`, `matched`, `new_created`
  per run.
- `app/models/grda_warehouse/client_match.rb:64` `accept_exact_matches!`; `:88` `auto_process!`;
  `:118` `create_candidates!`; `:214` `accept!`; `:234` `reject!`.
- `app/models/grda_warehouse/client_merge_history.rb`: `current_destination`.
- `app/models/grda_warehouse/client_split_history.rb`: `split_from`, `split_into`, `receive_hmis`.
- `app/models/grda_warehouse/source_client_name_set.rb`: `SourceClientName` struct, `+`.
- `app/models/grda_warehouse/tasks/client_cleanup.rb:71` `run!`; `:237`
  `remove_unused_source_clients`; `:263` `find_unused_destination_clients`; `:370`
  `choose_attributes_from_sources`; `:673` `update_client_demographics_based_on_sources`; `:837`
  `clients_to_munge`.
- `app/models/similarity_metric/tasks/generate_candidates.rb`: candidate generation loop and the
  `processed_sources` marker row.
- `app/controllers/clients_controller.rb:154` `merge`; `:175` `unmerge`.
- `app/controllers/client_matches_controller.rb`: `index`, `defer`, `update`.
- `app/controllers/concerns/client_controller.rb:169` and `:192`: redirect through
  `ClientMergeHistory#current_destination`.
- `app/jobs/importing/run_identify_duplicates_job.rb`: wrapper job.
- `app/jobs/importing/run_daily_imports_job.rb:55` `'Identify Duplicates'` task; `:71` and
  `:147` `ClientCleanup` runs; `:263` `create_statistical_matches`.
- `drivers/hmis/app/models/hmis/hud/client.rb:94` create and update callbacks; `:397`
  `warehouse_match_existing_clients`; `:410` `warehouse_identify_duplicates_for_new_client`.
- `docs/matching_algorithm.md`: the `SimilarityMetric` scoring model behind `ClientMatch`.

## Gotchas

- `enable_auto_deduplication` off means no exact matching at all. `find_merge_candidates_for_unprocessed`
  returns nothing, so every unlinked source client gets its own new destination, and
  `match_existing!` and `accept_exact_matches!` return early. It is a different key from
  `auto_de_duplication_enabled`, which only governs threshold-based accept/reject of
  statistical `ClientMatch` rows.
- The exact-match methods default to `legacy: true` and run the hand-written SQL. The
  `IdentifyDuplicatesQueryMatcher` path is only exercised with `legacy: false`. A filter change
  must be made in both until the legacy methods are removed.
- `Hmis::MergeClientsJob` reuses `ClientCleanup#choose_attributes_from_sources`. Changing a
  `choose_best_*` rule changes HMIS merge results too.
- Merges change consent. `HmisClient.maintain_client_consent` resolves the destination through
  `warehouse_clients` at run time, and the daily job runs consent before `IdentifyDuplicates`,
  so consent follows a moved source the next night; dates already written on the old
  destination are not cleared. See `roi/consent-from-external-sources.md`.
- `ClientSplitHistory` only blocks `match_existing!`. The unprocessed path can attach a new
  source to either of two split destinations.
- `MAX_SOURCE_CLIENTS` (50): outside production `split_chains_on_max_source` starts a new
  chain when a merge would exceed it; in production `will_exceed_source_counts?` raises first,
  so the Sentry message after it is never reached and the nightly `match_existing!` stops until
  someone intervenes.
- `warehouse_clients.reviewd_by` is misspelled and is a string column holding a user id.
- `WarehouseClient` does not use `acts_as_paranoid` (the include is commented out), yet
  `ClientCleanup#clean_warehouse_clients` clears and re-sets `deleted_at` on every run for
  external analytics. Do not filter on `deleted_at` inside this app.
- `DataSource.source_data_source_ids` and `destination_data_source_ids` are cached for one
  hour; a data source created or reclassified mid-run may not be recognized until then.
- `destination?` without `strict: true` means "has source clients"; a destination whose
  `WarehouseClient` is not yet saved is not one, and `merge_from` on it raises.
- `Hud::Client#splits_to` uses `foreign_key: :split_from` and `splits_from` uses `split_into`.
- `ClientMatch` `processed_sources` rows have `source_client_id == destination_client_id`.
  Counting `ClientMatch` rows without a status scope overstates candidates. On `candidate`
  rows both ids are source clients, not a source and a destination as the column names imply.
- `Import::ClientMatching` (ad hoc batch uploads), `ObviousClientMatcher`, and
  `GrdaWarehouse::ClientMatcherLookups` (`IdentifyExternalClientsJob`) are lookup helpers for
  other jobs; they never write `WarehouseClient` rows.
- `Importing::RunIdentifyDuplicatesJob` has no callers in this repository; the daily pipeline
  calls the task class directly.
- `Hmis::MergeClientsJob` and `Hmis::UndoMergeClientsJob` mutate `WarehouseClient` rows and
  rely on the next `IdentifyDuplicates` and `ClientCleanup` runs to repair destinations.

## Do not repeat

- Querying `GrdaWarehouse::Hud::Client` for a person-level view without going through
  `WarehouseClient`. `Hud::Client.where(...)` returns source and destination rows mixed;
  `Hud::Client.find(id)` on a source id shows one data source's slice. Replace with the
  `.destination` scope plus `source_clients`, or `client.destination_client` when starting
  from a source. Existing example of the replacement: `ClientMatchesController#index` joins
  `source_client: :destination_client` and `destination_client: :destination_client` before
  reading enrollments.
- Hand-rolled merges outside the history-writing path: `WarehouseClient.update_all(destination_id:)`,
  destroying a destination `Hud::Client` directly, or moving `client_id` foreign keys by hand.
  Replace with `Hud::Client#merge_from`, which stamps review columns, writes
  `ClientMergeHistory`, moves dependent items, invalidates service history, clears `ClientMatch`
  rows, and queues `ClientCleanupJob`. Existing example: `ClientMatch#accept!`.
- Detaching a source by deleting its `WarehouseClient` and letting the nightly run re-link it.
  Without a `ClientSplitHistory` row `match_existing!` merges the pair again. Replace with
  `Hud::Client#split`. Existing example: `ClientsController#unmerge`.
- Adding another exact-match query with its own SSN or name filters. Replace with a new
  `IdentifyDuplicatesQueryMatcher.for_*` builder so the `:existing` and `:unprocessed` shapes
  and the shared filters stay in one place.
- Picking a destination name, DOB, or SSN in a view or report with ad hoc logic over
  `source_clients`. Replace with the destination's stored columns (owned by `ClientCleanup`)
  or `SourceClientNameSet` for aliases. Existing example:
  `SourceClientViewAccessor#viewable_client_names`.
- Rescuing `Exception` around a merge as `match_existing!` does. New code should rescue
  nothing and let failures reach Sentry; the existing rescue predates the repo rule.
- Repo-wide patterns are in `conventions/do-not-repeat.md`.

## Related

- `hmis/restricted-records-and-multi-hmis.md`: `Hmis::MergeClientsJob` merges source clients
  within one HMIS data source, reuses `choose_attributes_from_sources`, and leaves
  `WarehouseClient` repair to `IdentifyDuplicates` and `ClientCleanup`.
- `roi/consent-from-external-sources.md`: how a merge changes which source's consent is
  reconciled onto the destination, and why the effect lands one daily run later.
- `hud-reporting/service-history.md`: `invalidate_service_history`,
  `force_full_service_history_rebuild`, and `ServiceHistory::Add`, which every merge, split,
  and DOB change triggers.
- `authorization/warehouse-policies.md`: which users may edit clients (`require_can_edit_clients!`
  on merge, split, and match review) and view import logs.
- `docs/features/warehouse/identify-duplicates.md`: human-facing description of the three
  `IdentifyDuplicates` operations.
- `docs/matching_algorithm.md`: the statistical `SimilarityMetric` design, initialization, and
  proposed machine-learning follow-ups.
- `docs/adr/0004-identity-management.md` and `docs/adr/0008-identity-management.md`: despite the
  titles, these cover user authentication (an external IdP behind Dex and OAuth2-Proxy), not
  client identity. ADR 0008 supersedes ADR 0004: the same decision with Keycloak replacing
  Zitadel as the default IdP, because the Zitadel choice was never deployed. ADR 0008 is still
  marked Draft. Nothing in the client identity code depends on either.
