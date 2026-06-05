# HMIS Simulation Engine

Generates realistic, obviously-fake HMIS data for demo and staging environments. The engine populates `Hmis::Hud::*` tables directly — the same tables that back the HMIS front-end and warehouse reports — so generated clients appear in the UI and flow through to all standard HUD reports (APR, LSA, SPM, etc.).

Related issue: open-path/Green-River#8210

---

## Why

Demo and staging environments need data that is:

- **Fresh** — updated daily so the demo always looks like a live system
- **Realistic** — enough variety in program types, client demographics, and enrollment patterns that HUD reports produce non-trivial output
- **Obviously fake** — unambiguously synthetic so no simulated record can be mistaken for real client data

The simulation generates all records with recognizable fake identifiers (see below) and is driven by a JSON config that controls populations, project mix, volume, and data quality rates.

---

## Architecture

### Tracks

A simulation config has a `tracks` array. Each track has a `type` (`primary`, `concurrent`, or `lifecycle`) and a `name`. At least one `primary` track is required.

| Track type | Example | Lifecycle |
|---|---|---|
| **primary** | General population ES → PSH journey | Sequential state machine; one active enrollment at a time; exits and re-enters based on configured transitions |
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
2. Primary exits and entries (transitions, gap between programs)
3. Annual assessment collection (IncomeBenefits with jitter + miss rate)
4. Concurrent enrollment tick (looped over all concurrent tracks)
5. Lifecycle enrollment tick (CE trigger, close conditions)
6. Write `RunLog`

Each daily run is idempotent — re-running the same date is a no-op.

---

## Fake identifier conventions

Every generated record is recognizably synthetic:

| Field | Convention | Example |
|---|---|---|
| PersonalID, EnrollmentID, etc. | `FAKE` prefix + 28 hex chars | `FAKE9a3f4b1c...` |
| SSN | Always starts with `999` | `999421783` |
| FirstName | US city name + `_` | `Portland_` |
| LastName | River/water body name + `_` | `Columbia_` |
| Project/Org names | Configured names must end with `_` | `Harbor ES NBN_` |

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

### 4. Bootstrap HUD records

```bash
bundle exec rake driver:hmis_simulation:bootstrap[hmis_simulation/demo-coc-small]
```

Creates organizations, projects, `ProjectCoc`, `Inventory`, and `Funder` records idempotently. Safe to re-run.

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

---

## Config reference

The full annotated config with all options is in `drivers/hmis_simulation/config/sample/small_coc.json`. Key sections:

| Section | Purpose |
|---|---|
| `organizations` / `projects` | Defines the HMIS project structure; project names must end with `_` |
| `data_quality` | Global rates for missing/approximate DOB, SSN, and name. Each primary track may override via its own `data_quality` key (deep-merged on top of global). |
| `tracks` | Array of track configs. At least one `type: "primary"` is required. |

### Primary track keys

| Key | Purpose |
|---|---|
| `new_clients_per_month` | Distribution controlling spawn rate. Steady-state ≈ (lambda/30) × avg_days_enrolled. |
| `household_cohesion_probability` | Per-member probability of re-including an existing household member on re-enrollment. |
| `household_templates` | Demographic distributions for adult-only, adult+child, and child-only households. |
| `populations` | Named stages in the housing journey; `entry_point` and `exit_point` are relative weights. |
| `transitions` | How clients move between populations; each has a `timing` distribution, optional `gap_before_entry`, and `exit_destinations`. |
| `enrollment_config` | Disability probabilities, income sources, health/DV rates, annual collection jitter. |
| `data_quality` | Per-track override; deep-merged with the top-level `data_quality`. |

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
