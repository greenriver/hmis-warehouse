---
title: Consent from external sources (ETO and source-level HmisClient)
summary: "How consent captured in an external HMIS (ETO API) lands on GrdaWarehouse::HmisClient per source record and is reconciled onto the destination client by maintain_client_consent, including the newest-wins rule and expiry revocation."
area: roi
tags: [roi, consent, ETO, EtoApi, HmisClient, maintain_client_consent, consent_confirmed_on, consent_expires_on, revoke_expired_consent, IdentifyDuplicates, RunDailyImportsJob, EtoApiConfig]
sources:
  - app/models/grda_warehouse/hmis_client.rb
  - app/models/eto_api/tasks/update_eto_data.rb
  - app/models/grda_warehouse/eto_api_config.rb
  - app/models/grda_warehouse/tasks/identify_duplicates.rb
  - app/models/grda_warehouse/hud/client.rb
  - app/jobs/importing/run_daily_imports_job.rb
  - app/jobs/importing/eto_demographics_job.rb
  - app/jobs/importing/eto_update_everything_job.rb
  - lib/tasks/eto.rake
related:
  - roi/consent-records.md
  - roi/roi-authorizations-and-visibility.md
  - warehouse/data-sources-and-imports.md
---

## Purpose

Some installations record a client's Release of Information in an external HMIS (ETO) instead
of uploading a signed form to the warehouse. The ETO API importer copies per-source consent
dates onto `GrdaWarehouse::HmisClient` (`app/models/grda_warehouse/hmis_client.rb`), one row per
source client. A separate reconcile step, `GrdaWarehouse::HmisClient.maintain_client_consent`,
pushes the newest dates onto the destination `GrdaWarehouse::Hud::Client`, which is where the
canonical consent columns live (see `roi/consent-records.md`).

This is the only importer path that writes consent. HMIS CSV imports (`drivers/hmis_csv_importer`)
carry no consent fields. The reconcile runs only when `GrdaWarehouse::Config.get(:release_duration)`
is `'Use Expiration Date'`; under the other durations ETO consent dates sit on `HmisClient` and
are never copied.

## Entry points

- `EtoApi::Tasks::UpdateEtoData#fetch_demographics` (`app/models/eto_api/tasks/update_eto_data.rb`)
  builds or updates one `GrdaWarehouse::HmisClient` from an ETO demographic response.
  `Importing::EtoDemographicsJob` calls `update_demographics!` in 500-client slices, enqueued by
  `Importing::EtoUpdateEverythingJob`, which the `eto:import:demographics_and_touch_points` rake
  task (`lib/tasks/eto.rake`) schedules per active `GrdaWarehouse::EtoApiConfig`.
  `GrdaWarehouse::Hud::Client#fetch_updated_source_hmis_clients(save:)` runs the same fetch on
  demand for one destination client.
- `GrdaWarehouse::HmisClient.maintain_client_consent` reconciles every `consent_active`
  `HmisClient` onto its destination client. Scheduled by `Importing::RunDailyImportsJob`
  (`app/jobs/importing/run_daily_imports_job.rb`), which calls it twice per run: inside the
  `'Update Client ROIs'` maintenance task (guarded by `release_duration == 'Use Expiration Date'`)
  and again unguarded at the end of `update_from_hmis_forms`. The method carries its own guard,
  so the second call is a no-op under other durations.
- `eto:import:maintain_client_consent` (`lib/tasks/eto.rake`) runs the same class method by hand.
- `GrdaWarehouse::Hud::Client.revoke_expired_consent` clears release status on destination
  clients whose consent has lapsed. `RunDailyImportsJob` calls it before the reconcile, and the
  class method calls it again first thing.
- `GrdaWarehouse::Hud::Client#consent_form_status` and `#signed_consent_form_fully?` read the
  ETO `consent_form_status` string from the newest source `HmisClient`. Display only, used by
  two `_rollups_limited.haml` partials in `drivers/client_access_control`.

## How it works

Field mapping is configuration, not code. `fetch_demographics` loads the active
`GrdaWarehouse::EtoApiConfig` (`app/models/grda_warehouse/eto_api_config.rb`) for the data
source and walks three JSON hashes on it: `demographic_fields` (an `HmisClient` attribute name
to an ETO demographic label, resolved through `literal_value` or `defined_value`),
`demographic_fields_with_attributes` (entity lookups such as staff names), and
`additional_fields` (attribute name to a `CustomDemoData` CDID; the `else` branch assigns any
key that is a column on `hmis_clients`). `consent_confirmed_on`, `consent_expires_on`, and
`consent_form_status` are ordinary `hmis_clients` columns and are populated only when an
installation's config names them. The same values are also copied into the `processed_fields`
jsonb snapshot. Nothing in this file hardcodes consent.

`HmisClient.consent_active` selects rows where `consent_confirmed_on <= Date.current` and
`consent_expires_on >= Date.current`; null dates never qualify. `consent_inactive` is the
complement.

`HmisClient.maintain_client_consent` returns unless `release_duration` is
`'Use Expiration Date'`. It then calls `Hud::Client.revoke_expired_consent`, which under that
duration runs `update_all` on destination clients with `consent_expires_on < Date.current`,
setting `housing_release_status` to `nil` and `consented_coc_codes` to `[]`; the date columns are
left in place and no callbacks fire. Then it iterates `consent_active.preload(:destination_client)`
and calls the instance method on each.

`HmisClient#maintain_client_consent` resolves `destination_client` (a `has_one ... through:
:client`, so the link is read from `warehouse_clients` at run time) and applies newest-wins:

- A destination date that is blank is filled from the source.
- `consent_form_signed_on` is overwritten only when the source `consent_confirmed_on` is
  strictly later. `consent_expires_on` is overwritten only when the source
  `consent_expires_on` is strictly later.
- If either write happens, `housing_release_status` is set to
  `Hud::Client.full_release_string` (the active consent class's full release string) and the
  client is saved through ActiveRecord, so callbacks run.
- Otherwise nothing is written. Dates only ever move forward; a source with an earlier expiry
  cannot shorten the destination's consent.

The reconcile never touches `consented_coc_codes` or `consent_form_id`. A destination revoked
for expiry keeps its stale dates, so any still-active source row (expiry on or after today)
re-releases it on the next pass.

## Key files

- `app/models/grda_warehouse/hmis_client.rb:26` `consent_active`, `:33` `consent_inactive`,
  `:56` `self.maintain_client_consent`, `:64` instance `maintain_client_consent`.
- `app/models/eto_api/tasks/update_eto_data.rb:243` `fetch_demographics`; `:296` the
  `processed_fields` snapshot that includes the three consent values.
- `app/models/grda_warehouse/eto_api_config.rb`: per-data-source model whose
  `demographic_fields`, `demographic_fields_with_attributes`, and `additional_fields` JSON
  columns decide which ETO values reach which `hmis_clients` columns.
- `app/models/grda_warehouse/hud/client.rb:1040` `self.revoke_expired_consent`; `:1500`
  `fetch_updated_source_hmis_clients`; `:1676` `consent_form_status` and
  `signed_consent_form_fully?`.
- `app/jobs/importing/run_daily_imports_job.rb:35` `'Update Client ROIs'` task (revoke, then
  guarded reconcile); `:298` second, unguarded reconcile call in `update_from_hmis_forms`; the
  `'Identify Duplicates'` task runs after both.
- `app/jobs/importing/eto_demographics_job.rb:14` calls `update_demographics!` for a slice of
  client ids.
- `app/jobs/importing/eto_update_everything_job.rb`: fans out `EtoDemographicsJob` per 500
  clients for one data source.
- `lib/tasks/eto.rake:11` `eto:import:maintain_client_consent`; `:33`
  `eto:import:demographics_and_touch_points`.
- `app/models/grda_warehouse/tasks/identify_duplicates.rb`: re-links source clients to
  destinations. It does not call `maintain_client_consent`; the daily job order is what
  reconciles after a merge.

## Gotchas

- ETO is one data source type. Consent only arrives through `GrdaWarehouse::EtoApiConfig`
  rows; a data source without one, including every HMIS CSV data source, contributes no
  `HmisClient` consent. HMIS CSV imports do not carry consent.
- Whether `consent_confirmed_on` and `consent_expires_on` are filled at all depends on the
  installation's `EtoApiConfig` JSON naming those keys. Reading the code alone cannot tell you
  which installations have ETO consent; check the config rows.
- The reconcile is gated on `release_duration == 'Use Expiration Date'`. Switching an
  installation to `'One Year'` or `'Two Years'` silently stops ETO consent from reaching
  destination clients, while `ClientFile`-based consent keeps working.
- `Importing::RunDailyImportsJob` calls `maintain_client_consent` twice per run (once in
  `'Update Client ROIs'`, once in `update_from_hmis_forms`). Each call is a full scan of
  `consent_active` rows. The result is idempotent, so the second pass changes nothing.
- A merge can change which source consent wins. `destination_client` is resolved through
  `warehouse_clients` at run time, so after `IdentifyDuplicates` moves a source client, the next
  daily run writes that source's dates onto the new destination. Nothing removes the dates
  already written onto the old destination; they stay until `revoke_expired_consent` clears the
  release status after `consent_expires_on` passes, and even then the date columns remain.
- `IdentifyDuplicates` runs after the consent tasks in the daily job, so consent from a merge
  done today reaches the new destination tomorrow.
- `revoke_expired_consent` uses `update_all` and skips callbacks and paper trail;
  `maintain_client_consent` uses `save` and does not. Audit history for the two directions
  differs.
- The reconcile sets `housing_release_status` to the full release string but leaves
  `consented_coc_codes` alone. CoC-scoped visibility (`roi/roi-authorizations-and-visibility.md`)
  treats an empty array as "all CoCs", so ETO-sourced consent is never CoC-limited.
- `Hud::Client#consent_form_status` orders source clients by `Client.DateUpdated`, not by
  `HmisClient.eto_last_updated` or `consent_confirmed_on`. It is a display string and is not
  used by the reconcile.

## Do not repeat

- Writing `consent_form_signed_on`, `consent_expires_on`, or `housing_release_status` onto
  `GrdaWarehouse::Hud::Client` directly from an importer or API client. Replace with: store
  the source values on `GrdaWarehouse::HmisClient` columns (existing example:
  `EtoApi::Tasks::UpdateEtoData#fetch_demographics` via `EtoApiConfig` field mapping) and let
  `GrdaWarehouse::HmisClient.maintain_client_consent` reconcile. A direct write bypasses the
  newest-wins comparison and would be overwritten or left inconsistent on the next daily run.
- Hardcoding ETO CDIDs or demographic labels for consent in Ruby. The mapping belongs in the
  `GrdaWarehouse::EtoApiConfig` JSON columns, which `fetch_demographics` already reads.
- Adding a third call to `maintain_client_consent` in `Importing::RunDailyImportsJob`. Two
  already exist; a new consumer that needs fresh consent should call the class method itself or
  reuse the rake task `eto:import:maintain_client_consent`.
- Bypassing the `release_duration == 'Use Expiration Date'` guard inside
  `HmisClient.maintain_client_consent`. Under `'One Year'`/`'Two Years'`, validity is computed
  from `consent_form_signed_on` alone, and `revoke_expired_consent` takes a different branch;
  copying ETO expiry dates in that mode would produce two disagreeing definitions of "expired".

## Related

- `roi/consent-records.md`: the destination `Hud::Client` consent columns, `ClientFile`-based
  consent, `release_duration`, and the consent strategy classes whose `full_release_string`
  the reconcile writes.
- `roi/roi-authorizations-and-visibility.md`: how the resulting `housing_release_status` and
  `consented_coc_codes` gate visibility and CAS sync.
- `warehouse/data-sources-and-imports.md`: data source types, including ETO API data sources
  and the daily import job.
- `docs/features/warehouse/data-sources.md`: human-facing description of data sources and the
  `obey_consent` flag.
