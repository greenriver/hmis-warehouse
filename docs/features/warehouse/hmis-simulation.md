# HMIS Simulation Engine

Generates realistic, obviously-fake HMIS data for development, demo, and staging environments. The engine populates `Hmis::Hud::*` (`GrdaWarehouse::Hud::*`) tables directly — the same tables that back the HMIS front-end and warehouse reports — so generated clients appear in the UI and flow through to all standard HUD reports (APR, LSA, SPM, etc.).

---

## Why

- **Fresh** — updated daily so the demo always looks like a live system
- **Realistic** — enough variety in program types, client demographics, and enrollment patterns that the data looks real.  Additionally, the data generally follows HMIS data entry guidelines with some intentional data quality issues.
- **Obviously fake** — unambiguously synthetic so no simulated record can be mistaken for real client data

---

## Architecture

### Tracks

A simulation config has a `tracks` array. Each track has a `type` (`primary`, `concurrent`, or `lifecycle`) and a `name`. At least one `primary` track is required.

| Track type | Example | Lifecycle |
|---|---|---|
| **primary** | General population homeless → housed journey through the continuum | Sequential state machine; one active enrollment at a time; exits and re-enters based on configured transitions |
| **concurrent** | Street Outreach contacts, Case Management | Independent timer-based enrollments that overlap with the primary; may reopen after a gap |
| **lifecycle** | Coordinated Entry | Opens when client enters a trigger population; closes on housing move-in, disengagement timeout, or pre-entry exit |

Each simulated client belongs to exactly one primary track (stored in `hmis_simulation_clients.track_name`). Secondary tracks (concurrent/lifecycle) apply to all primary tracks by default, but can be scoped to specific primaries using the `applies_to_tracks` field.

### Multiple primary tracks

Multiple primary tracks let different client populations have fully independent demographics, enrollment patterns, and data quality rates. For example:

```json
"tracks": [
  { "name": "general_population", "type": "primary", ... },
  { "name": "veteran_population", "type": "primary", "enrollment_config": { ... }, ... }
]
```

Each primary track has its own:
- `new_clients_per_month` — spawn rate
- `household_templates` — demographic distributions
- `populations` and `transitions` — the housing journey state machine
- `enrollment_config` — disability, income, health/DV rates
- `data_quality` (optional) — overrides the global `data_quality` via deep merge

### Config storage

Simulation configurations are JSON blobs stored in `AppConfigProperty` (key prefix: `hmis_simulation/`). Sample files live in `drivers/hmis_simulation/config/sample/` — copy one, set `data_source_id`, and load it via rake task.

Configs are validated against a JSON Schema before any records are written. See `drivers/hmis_simulation/public/schemas/simulation_config.json` for the full schema definition.

### State tables

Five `hmis_simulation_*` tables track simulation progress so the engine can resume after a missed day:

- `hmis_simulation_clients` — current population, active enrollment, next transition date, `track_name`
- `hmis_simulation_household_groups` — household composition for re-enrollment continuity
- `hmis_simulation_concurrent_enrollments` — active concurrent enrollment state, `track_name`
- `hmis_simulation_lifecycle_enrollments` — CE enrollment state and close conditions
- `hmis_simulation_run_logs` — audit trail; `last_successful_run_date` is derived from this

### Engine

`HmisSimulation::Engine#run(date:)` processes one calendar day per call, in this order:

1. Spawn new clients (looped over all primary tracks)
2. Primary exits and entries (transitions, gap between programs), plus NBN bed nights for open ES NBN enrollments
3. Housing move-in — set `MoveInDate` on open PH enrollments whose configured delay has elapsed (see below)
4. Periodic CLS records (SO: every ~30 days; CE: every ~90 days)
5. Annual assessment collection (IncomeBenefits + EmploymentEducation with jitter + miss rate)
6. Concurrent enrollment tick (looped over all concurrent tracks)
7. Lifecycle enrollment tick (CE trigger, close conditions, mid-enrollment events)
8. Write `RunLog`

`MoveInDate` is **not** set at enrollment entry. It is deferred to step 3 so that some PH clients exit without ever being housed (they left before move-in), which mirrors real HMIS data. The roll is stable per enrollment (seeded by `EnrollmentID`), so a client's move-in date is determined at the first tick after entry and never changes. Configured under a primary track's `enrollment_config.ph_move_in`: `probability` (share of clients who ever receive a `MoveInDate`) and `delay_days` (distribution of days from `EntryDate` to `MoveInDate`).

Each daily run is idempotent — re-running the same date is a no-op.

---

## Fake identifier conventions

Every generated record is recognizably synthetic:

| Field | Convention | Example |
|---|---|---|
| PersonalID, EnrollmentID, etc. | `FAKE` prefix + 28 hex chars | `FAKE9a3f4b1c...` |
| SSN | Always starts with `999` | `999421783` |
| FirstName | US city or water body name + `_` | `Portland_`, `Tahoe_`, `Narragansett_` |
| LastName | Latin plant binomial + `_` | `Quercus Robur_`, `Betula Pendula_` |
| Project/Organization names | Configured names must end with `_` | `Harbor ES NBN_` |

---

## Setup

### 1. Copy and edit a sample config

```bash
cp drivers/hmis_simulation/config/sample/small_coc.json /tmp/my-demo-coc.json
```

Edit `/tmp/my-demo-coc.json`:
- Set `data_source_id` to the HMIS data source ID for this installation
- Optionally tune `coc_codes`, organization names, population probabilities, and `new_clients_per_month`

The sample ships with a realistic small-CoC configuration: ES NBN, ES Entry/Exit, TH, PSH, RRH, SO, CE, and case management; adult-only and adult+child household types; two concurrent SO/case management tracks; and one CE lifecycle track.

### 2. Validate the config

```bash
bundle exec rake driver:hmis_simulation:validate[/tmp/my-demo-coc.json]
```

Reports any structural or semantic errors (schema violations, unresolved `project_ref`, missing `entry_point`, etc.) before writing anything to the database.

### 3. Load config into AppConfigProperty

```bash
bundle exec rake driver:hmis_simulation:setup_from_file[/tmp/my-demo-coc.json]
```

Validates the config and saves it as an `AppConfigProperty` record. The key is derived from the config's `name` field (e.g. `hmis_simulation/demo-coc-small`).

Bootstrap runs automatically the first time you call `run_all`, `run`, or `run_range` — no separate step required. If you need to pre-create the project records before the first run (e.g. to inspect projects in the UI first), you can bootstrap explicitly:

```bash
bundle exec rake driver:hmis_simulation:bootstrap[hmis_simulation/demo-coc-small]
```

Creates organizations, projects, `ProjectCoc`, `Inventory`, `Funder`, `HmisParticipation`, and `CeParticipation` records idempotently. Safe to re-run.

---

## Running the simulation

### Generate a historical backfill

```bash
# One year of history
bundle exec rake driver:hmis_simulation:run_range[hmis_simulation/demo-coc-small,2025-06-01,2026-06-04]
```

Use this on first setup to give the demo environment a realistic history before enabling nightly automation.

### Advance one day manually

```bash
bundle exec rake driver:hmis_simulation:run[hmis_simulation/demo-coc-small,2026-06-05]
```

### Nightly automation

Set `ENABLE_HMIS_SIMULATION=true` on the server. The `HmisSimulation::RunnerJob` is scheduled via `whenever` to run at 4:30 am. It finds all `hmis_simulation/*` AppConfigProperty records and advances each simulation from `last_successful_run_date + 1` through today, catching up any missed days automatically.

To enqueue it manually:

```bash
bundle exec rake driver:hmis_simulation:run_all
```

### Warehouse sync

After all simulation days complete, `RunnerJob` runs `HmisSimulation::WarehouseSyncer` so simulated clients appear in reports. The first three steps run **synchronously**; the last two are **deferred** to a background `HmisSimulation::RefreshWarehouseViewsJob` so the rake task / job returns promptly — data appears in reports once that job completes (eventual consistency).

| Step | What it does | When |
|---|---|---|
| `GrdaWarehouse::Tasks::IdentifyDuplicates.run!` | Creates `GrdaWarehouse::WarehouseClient` and destination `GrdaWarehouse::Hud::Client` records for each simulated source client | Synchronous |
| `GrdaWarehouse::Tasks::IdentifyDuplicates.match_existing!` | Links any orphaned source clients to their destination | Synchronous |
| `GrdaWarehouse::Tasks::ServiceHistory::Enrollment.batch_process_unprocessed!` | Builds `ServiceHistoryEnrollment` and `ServiceHistoryService` rows that warehouse reports read | Synchronous |
| `GrdaWarehouse::ServiceHistoryServiceMaterialized.refresh!` | Updates the materialized view used by client search and most report queries | Deferred (`RefreshWarehouseViewsJob`) |
| `GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids:)` | Updates cached counts, scoped to the affected destination clients | Deferred (`RefreshWarehouseViewsJob`) |

`IdentifyDuplicates` and `batch_process_unprocessed!` are system-wide (they process all unlinked clients / unprocessed enrollments, not just the simulation data source); the deferred view refresh is scoped to the simulation's destination clients. The whole sync is skipped in the test environment.

Steps intentionally omitted for performance: `ProjectCleanup`, `ClientCleanup`, `SanityCheckServiceHistory`, `EarliestResidentialService`, and `ReportingSetupJob`. These will all run on the next nightly run.

---

## HUD compliance

The simulation generates a complete set of HUD 2026 HMIS records for each project type, driven by machine-readable rules in `drivers/hmis_simulation/public/compliance/project_type_rules.json`. Records are sampled from valid HUD code sets via `HudHelper.util`.

### Records generated per project type

| Record | Project types | When |
|---|---|---|
| `HmisParticipation` | All | Bootstrap |
| `CeParticipation` | CE (type 14) | Bootstrap |
| `ProjectCoC.Zip`, `.GeographyType` | All | Bootstrap |
| `Inventory.ESBedType`, sub-bed counts | Residential (0,1,2,3,8,9,10,13) | Bootstrap |
| `Service` (bed night) | ES NBN (type 1) | Daily, per open enrollment |
| `MoveInDate` | PH (3,9,10,13) | Deferred after entry (see Architecture → Engine) |
| `LivingSituation` + full 3.917 suite | All | Enrollment entry |
| `DateOfEngagement` | SO (type 4) | Enrollment entry |
| `ReferralSource` | All | Enrollment entry |
| `HealthAndDv` | All (entry); residential + SO (0,1,2,3,4,8,9,10,13) (exit) | Entry + exit |
| `EmploymentEducation` | Residential (0,1,2,3,8,9,10,13) | Entry, annual, exit |
| `CurrentLivingSituation` (periodic) | SO: ~30-day interval; CE: ~90-day interval | During enrollment |
| `Assessment` + `AssessmentResults` | CE (type 14) | At enrollment open |
| `Event` (opening, mid-enrollment, closing) | CE (type 14) | At open / mid / close |

#### 3.917 Prior Living Situation fields

`LivingSituation` is sampled from a per-population weighted distribution (configured via `prior_living_situation` in the population config, or project-type defaults). The following fields are derived or co-sampled:

- `LengthOfStay` — sampled from valid HUD codes
- `LOSUnderThreshold` — derived from `LengthOfStay` (1 if < 7 nights, 0 otherwise)
- `PreviousStreetESSH` — sampled (~40% yes, ~45% no, ~15% DNC)
- When `PreviousStreetESSH = 1`: `DateToStreetESSH`, `TimesHomelessPastThreeYears`, `MonthsHomelessPastThreeYears`

#### CE Event codes

| When | Event code | Description |
|---|---|---|
| Enrollment open | 3 | Referral to scheduled CE Crisis Needs Assessment |
| Mid-enrollment (≥30 days open) | 4 | Referral to scheduled CE Housing Needs Assessment |
| Close: `housing_move_in` | 14 | Referral to PSH (successful) |
| Close: `disengagement` | 9 | No availability in continuum services |
| Close: `pre_entry_exit` | 2 | Problem Solving / Diversion |

### Data quality and deliberate violations

`data_quality.record_miss_rate` (default `0.0`; the sample config sets `0.0025`) introduces a small chance that any required per-enrollment record is skipped. This simulates real-world gaps where a staff member forgets to complete an assessment, or a system import drops a record. The same seeded RNG is used for each record slot, so a given enrollment always produces the same miss result for a given simulation seed.

Field-level data quality (missing DOB, approximate DOB, missing SSN, missing name) is controlled separately by the existing `missing_dob_rate`, `approximate_dob_rate`, `missing_ssn_rate`, and `missing_name_rate` keys.

### Auditing compliance

After running the simulation, check generated data against the compliance rules:

```bash
bundle exec rake driver:hmis_simulation:validate_data[hmis_simulation/demo-coc-small]
```

Reports violations grouped by type with counts. Expects near-zero violations for a well-configured simulation (only the deliberate `record_miss_rate` gaps). Example output:

```
✓ No compliance violations found for data_source_id 42
```

Or with violations:

```
✗ 3 compliance violation(s) found:
  missing_date_of_engagement (2):
    - SO enrollment "FAKE..." in "Street Outreach Team_" is missing DateOfEngagement
    ...
```

---

## Config reference

The full annotated config with all options is in `drivers/hmis_simulation/config/sample/small_coc.json`. Key sections:

| Section | Purpose |
|---|---|
| `organizations` / `projects` | Defines the HMIS project structure; project names must end with `_` |
| `data_quality` | Global rates for missing/approximate DOB, SSN, and name. Each primary track may override via its own `data_quality` key (deep-merged on top of global). |
| `tracks` | Array of track configs. At least one `type: "primary"` is required. |

### Project config keys (inside `organizations[].projects[]`)

| Key | Purpose |
|---|---|
| `name` | Project name; must end with `_` |
| `project_type` | HUD project type integer |
| `capacity` | Bed count used for Inventory records |
| `funders` | Array of `{ funder, grant_id }` objects |
| `hmis_participation_type` | `1` (HMIS Participating) or `2` (HMIS Protected). Default: `1`. |
| `ce_participation` | CE participation flags (CE projects only): `access_point`, `prevention_assessment`, `crisis_assessment`, `housing_assessment`, `direct_services`, `receives_referrals` (all 0/1). |

### Primary track keys

| Key | Purpose |
|---|---|
| `new_clients_per_month` | Distribution controlling spawn rate. Steady-state ≈ (lambda/30) × avg_days_enrolled. |
| `household_cohesion_probability` | Per-member probability of re-including an existing household member on re-enrollment. |
| `household_templates` | Demographic distributions for adult-only, adult+child, and child-only households. |
| `populations` | Named stages in the housing journey; `entry_point` and `exit_point` are relative weights. Each population may have a `prior_living_situation` distribution (see below). |
| `transitions` | How clients move between populations; each has a `timing` distribution, optional `gap_before_entry`, and `exit_destinations`. |
| `enrollment_config` | Disability probabilities, income sources, health/DV rates, annual collection jitter, and `ph_move_in` (`probability` + `delay_days`) controlling deferred PH move-in dates. |
| `data_quality` | Per-track override; deep-merged with the top-level `data_quality`. |

#### Population `prior_living_situation`

Each population entry may include a `prior_living_situation` weighted distribution over valid HUD `LivingSituation` codes. Keys are HUD code strings; values are relative weights (normalized internally). Validated against `HudHelper.util.valid_prior_living_situations` at config load time.

```json
{
  "name": "street",
  "prior_living_situation": {
    "distribution": "weighted",
    "weights": { "116": 70, "101": 10, "118": 5, "99": 15 }
  }
}
```

If omitted, `LivingSituation` is sampled uniformly from all valid HUD codes.

### `data_quality` keys

| Key | Default | Purpose |
|---|---|---|
| `missing_dob_rate` | `0.0` | Probability DOB is set to nil + `DOBDataQuality: 99` |
| `approximate_dob_rate` | `0.0` | Probability DOB is year-only + `DOBDataQuality: 2` |
| `missing_ssn_rate` | `0.0` | Probability SSN is nil + `SSNDataQuality: 99` |
| `missing_name_rate` | `0.0` | Probability name is nil + `NameDataQuality: 99` |
| `record_miss_rate` | `0.0` | Probability any required per-enrollment record is skipped entirely (HealthAndDv at exit, EmploymentEducation, periodic CLS, CE Assessment, CE Event) |

### Concurrent track keys

| Key | Purpose |
|---|---|
| `applies_to_tracks` | Optional list of primary track names. Absent or empty = applies to all primary tracks. |
| `projects` | Array of project name strings (from `organizations`). One is selected per enrollment. |
| `count_distribution` | Map of count → relative weight. Controls how many concurrent enrollments a client receives. |
| `duration` | Distribution for concurrent enrollment length in days. |
| `reentry` | `{ gap: distribution, probability: float }` — controls re-enrollment after close. |

### Lifecycle track keys

| Key | Purpose |
|---|---|
| `applies_to_tracks` | Optional filter; absent = applies to all primary tracks. |
| `project_ref` | Project name (from `organizations`) for the lifecycle enrollment. |
| `trigger_populations` | Population names (from any primary track) that trigger this enrollment. |
| `trigger_probability` | Probability of enrollment when a client enters a trigger population. |
| `close_conditions` | `housing_move_in` (probability), `disengagement` (probability + after_days), `pre_entry_exit` (probability + after_days). Each is evaluated independently; first to fire wins. |

---

## Cleanup

To remove all simulated data for a data source, delete the associated `GrdaWarehouse::DataSource`. Because all generated records carry the simulation's `data_source_id`, this cascades cleanly.

To disable nightly automation, unset `ENABLE_HMIS_SIMULATION` and remove or archive the `AppConfigProperty` record.

---

## What this does not replace

- The existing `GrdaWarehouse::FakeData` class — that handles PII obfuscation for real-data exports (a separate use case)
- `Hmis::CreateFakeEnrollmentsJob` — a simpler one-shot seeder useful for local development
