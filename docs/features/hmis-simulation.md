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

### Three enrollment tracks

Each simulated client can carry up to three parallel enrollment tracks:

| Track | Example | Lifecycle |
|---|---|---|
| **Primary** | ES → PSH journey | Sequential; one active enrollment at a time; exits and re-enters based on configured transitions |
| **Concurrent** | Street Outreach contacts, Case Management | Independent timer-based enrollments that overlap with primary; may reopen after a gap |
| **Lifecycle** | Coordinated Entry | Opens when client enters a trigger population; closes on housing move-in, disengagement timeout, or pre-entry exit |

### Config storage

Simulation configurations are JSON blobs stored in `AppConfigProperty` (key prefix: `hmis_simulation/`). Sample files live in `drivers/hmis_simulation/config/sample/` — copy one, set `data_source_id`, and load it via rake task.

### State tables

Five `hmis_simulation_*` tables track simulation progress so the engine can resume after a missed day:

- `hmis_simulation_clients` — current population, active enrollment, next transition date
- `hmis_simulation_household_groups` — household composition for re-enrollment continuity
- `hmis_simulation_concurrent_enrollments` — active concurrent enrollment state
- `hmis_simulation_lifecycle_enrollments` — CE enrollment state and close conditions
- `hmis_simulation_run_logs` — audit trail; `last_successful_run_date` is derived from this

### Engine

`HmisSimulation::Engine#run(date:)` processes one calendar day per call, in this order:

1. Spawn new clients (scaled from `new_clients_per_month`)
2. Primary exits and entries (transitions, gap between programs)
3. Annual assessment collection (IncomeBenefits with jitter + miss rate)
4. Concurrent enrollment tick (expire, reopen)
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

The sample ships with a realistic small-CoC configuration: ES NBN, ES Entry/Exit, TH, PSH, RRH, SO, CE, and case management; adult-only and adult+child household types; concurrent SO contacts; and CE lifecycle enrollments.

### 2. Validate the config

```bash
bundle exec rake driver:hmis_simulation:validate[/tmp/my-demo-coc.json]
```

Reports any structural errors (unresolved `project_ref`, missing `entry_point`, etc.) before writing anything to the database.

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
| `household_templates` | Demographic distributions for adult-only, adult+child, and child-only households |
| `populations` | Named stages in a client's journey; `entry_point` and `exit_point` are relative weights |
| `transitions` | How clients move between populations; each has a `timing` distribution (enrollment length), optional `gap_before_entry`, and `exit_destinations` |
| `concurrent_enrollments` | Timed overlapping enrollments (SO, SSO); `count_distribution` controls how many per client |
| `lifecycle_enrollments` | CE enrollments; close on `housing_move_in`, `disengagement`, or `pre_entry_exit` conditions |
| `enrollment_config` | Disability probabilities, income sources, health/DV rates, annual collection jitter |
| `data_quality` | Rates for missing or approximate DOB, SSN, and name — generates realistic data quality issues |

---

## Cleanup

To remove all simulated data for a data source, delete the associated `GrdaWarehouse::DataSource`. Because all generated records carry the simulation's `data_source_id`, this cascades cleanly.

To disable nightly automation, unset `ENABLE_HMIS_SIMULATION` and remove or archive the `AppConfigProperty` record.

---

## What this does not replace

- The existing `GrdaWarehouse::FakeData` class — that handles PII obfuscation for real-data exports (a separate use case)
- `Hmis::CreateFakeEnrollmentsJob` — a simpler one-shot seeder useful for local development
