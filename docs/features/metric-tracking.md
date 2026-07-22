# Threshold Monitoring System - Architecture

## Overview

This document outlines the design for a flexible, performant threshold monitoring system that monitors changes in client data over time. The system enables trend analysis, alerting, and reporting on key client metrics while handling hundreds of thousands of client records efficiently.

## Goals

1. Track key client metrics over time with daily granularity
2. Support multiple entity types (clients, projects, data sources, organizations)
3. Make metrics extensible without schema changes
4. Provide performant queries for time-series data and change detection
5. Maintain reasonable storage requirements through intelligent data retention
6. Enable integration with alerting and reporting systems

## Use Cases

- **Change Detection**: Identify when a client metric makes a significant move in a single collection run (e.g., days homeless jumps by 30+ since the previous run)
- **Trend Analysis**: Chart how metrics evolve over time for individuals or cohorts
- **Alerting**: Trigger notifications when metrics cross thresholds
- **Reporting**: Aggregate metrics across populations for analytics
- **Historical Tracking**: Maintain audit trail of metric evolution

## Data Model Architecture

### Core Design Principles

1. **Polymorphic Entities**: Track metrics for any entity type (Client, Project, DataSource, etc.)
2. **Simple Values**: Thresholds monitor changes that can be expressed as integers
3. **Pluggable Calculators**: Separate metric calculation logic from storage
4. **Single Table Storage**: Simplified querying with intelligent retention policy
5. **Performance Optimized**: Batch processing, bulk upserts, composite indexes

### Schema

#### Metric Definitions Table (`metric_definitions`)

Stores the catalog of available metrics and how to calculate them.

**Design Decision: Single Value Type**

All metrics store integer values in a single column. This simplifies the schema and is appropriate since all current and planned metrics are count-based (days, enrollments, household sizes, etc.).

#### Metric Snapshots Table (`metric_snapshots`)

Stores time-range snapshots using range-based sparse storage. Each snapshot represents a period where a metric value stayed within the configured threshold. The table is partitioned by `initial_observation_date` with quarterly partitions (3 years past + 10 years future).

**Design Decisions:**

- **Range-Based Sparse Storage**: Each snapshot represents a time range where values stayed within threshold
  - `initial_observation_date`: When this value range started
  - `current_observation_date`: When this value was last calculated (updated daily)
  - `initial_value`: Count value when first observed
  - `current_value`: Count value as of last verification
- **Single Integer Value**: All metrics are count-based, eliminating need for multiple value columns
- **Table Partitioning**: Partitioned by `initial_observation_date` with quarterly partitions
  - Pre-created partitions: 3 years past + 10 years future
  - Enables efficient archival and query performance
- **Composite indexes**: Optimized for common query patterns (time series, change detection)

#### Metric Calculation Runs Table (`metric_calculation_runs`)

Logs each execution of the metric collection job, tracking statistics and status for monitoring and debugging.

### Sparse Storage Strategy

**Key Insight**: Most metrics don't change daily. Recording every value every day wastes massive storage.

**Solution**: Use range-based sparse storage. Only create a new snapshot when the value changes beyond the configured threshold.

#### Range-Based Sparse Storage

Each snapshot represents a time range where a metric stayed within threshold:

- **Stable periods**: One snapshot with `initial_observation_date` through `current_observation_date`
- **Significant changes**: New snapshot created when threshold exceeded
- **Daily updates**: Existing snapshots have `current_observation_date` and `current_value` updated daily

**Benefits:**
- Stable clients = few snapshots (cheap storage)
- Volatile clients = many snapshots (captures change history)
- Can detect spikes by analyzing snapshot duration and value change

#### Change Detection Logic

Change detection has two halves, split between the calculator and the collector:

1. **How much did it change?** — computed by the calculator's
   `change_metrics(previous_snapshot:, calculated_value:, calculation_date:)` class method,
   which returns `{ count_change:, percent_change: }`. The calculator owns **both** magnitudes
   so the count and percent always share the same basis and normalization — the collector never
   re-derives a percent from mismatched units. `percent_change` is `nil` when the previous value
   is zero (percent undefined). The correct comparison depends on the nature of the metric
   (see strategies below).
2. **Is that change significant?** — decided by the collector, comparing `count_change` and
   `percent_change` against the thresholds configured on the metric definition.

Both quantities are measured **since the last observed value** (the snapshot's `current_value`),
never from the original `initial_value`. Measuring from `initial_value` would let gradual
day-over-day drift accumulate past the threshold and fire a crossing whose per-run change is only
±1 — the bug this design exists to prevent. Because thresholds are admin-editable per metric, this
must hold for any configuration, not just the seeded defaults.

**Detection strategies** (the `change_metrics` half):

- **Default (`BaseCalculator`)**: `count_change = |calculated_value − current_value|`, with
  `percent_change = count_change / |current_value| * 100`. A per-run comparison with no
  elapsed-day normalization — appropriate for static or discrete metrics (household sizes, CSV
  row counts) where a change should register regardless of how many days passed since the last
  run. Only a genuine per-run jump past the threshold creates a crossing.
- **Per-run, gap-normalized (`HomelessDaysLastThreeYearsCalculator`)**: same `current_value`
  basis, but divides by the days since the last run: `count_change = |calculated_value −
  current_value| / days_elapsed` (with `days_elapsed` floored at 1), and `percent_change` is
  normalized the same way so it stays aligned with `count_change`. This suits a rolling-window
  total that drifts a little each day — a crossing fires only on a real per-day jump, and a
  multi-day catch-up after a missed run is averaged rather than mistaken for a spike.

**Thresholds** (the collector half), configured per metric definition:
- **`count_change_threshold`**: Create new snapshot if `count_change` is at least N (e.g., 30 —
  for `days_homeless` this means 30+ days *per day*)
- **`percent_change_threshold`**: Create new snapshot if `percent_change` is at least N% (e.g.,
  10%). For per-run-normalized calculators this is a *per-day* percent, consistent with the
  count threshold.
- **Both specified**: Requires **both** thresholds met (AND logic) to prevent false positives —
  e.g. with a 30-day AND 10% threshold, a 100 → 115 change (15 days, 15%) does not cross because
  the count threshold isn't met, but a 100 → 135 change (35 days, 35%) crosses because both are.
- **Neither specified**: Create new snapshot on any change (dense storage)

Implementation: `GrdaWarehouse::Monitoring::Tasks::MetricSnapshotCollector#should_create_new_snapshot?`
performs the threshold comparison and delegates the change calculation to
`BaseCalculator.change_metrics` (and its per-calculator overrides).

#### Storage Efficiency

**Example: 200K clients × 3 metrics over 3 years**

With range-based sparse storage:
- **Stable client** (2-3 changes): 2-3 snapshots per metric
- **Moderately stable** (monthly changes): ~36 snapshots per metric
- **Volatile client** (weekly changes): ~150 snapshots per metric

Assuming 70% stable, 25% moderate, 5% volatile:
- **Estimated total: ~10-15 million rows** (vs 657M for dense daily storage)
- **Storage: ~1-2 GB** (vs ~100 GB for dense storage)
- **98%+ storage reduction!**

#### Query Implications

Range-based storage requires queries to:
- Find the snapshot active for a given date (where date is between `initial_observation_date` and `current_observation_date`)
- Interpolate values for time series visualization
- Analyze snapshot duration to detect stability vs volatility

Implementation: See `GrdaWarehouse::Monitoring::MetricSnapshot` model scopes.

#### Example Metric Configurations

**Days Homeless** (per-run, gap-normalized detection):
```ruby
count_change_threshold: 30  # seeded default; editable on the admin Edit Metric page
percent_change_threshold: nil
# New snapshot only when the value moves 30+ days vs the previous run, per elapsed day.
# Uses the per-run detection strategy (see Change Detection Logic).
```

**Household Size** (default per-run detection, any change):
```ruby
count_change_threshold: 1
percent_change_threshold: nil
# Creates new snapshot on any household size change vs the established value
```

> Threshold values shown are the seeded defaults from each calculator's
> `metric_definition_attributes`. They are editable in the admin UI (Change Detection
> Thresholds), so a running deployment may use different values.

### Calculator Pattern

Metrics are calculated by pluggable calculator classes that follow a standard interface.

**Base Class**: `GrdaWarehouse::Monitoring::MetricCalculators::BaseCalculator`

**Key Features:**
- **Self-Configuring**: Each calculator defines its own metric definition via `metric_definition_attributes` class method
- **Batch Processing**: Calculators implement `calculate_batch(entities, calculation_date)` for efficient bulk calculation
- **Versioning**: Track when calculation logic changes via `version` method
- **Separation of Concerns**: Calculation logic isolated from storage

**Implemented Calculators:**
- `HomelessDaysLastThreeYearsCalculator` - Uses `GrdaWarehouse::WarehouseClientsProcessed` table; overrides `change_metrics` for per-run, gap-normalized detection
- `MinHouseholdSizeCalculator` - Analyzes enrollments across data sources (default per-run detection)
- `MaxHouseholdSizeCalculator` - Analyzes enrollments across data sources (default per-run detection)

A calculator that needs detection other than the default per-run comparison (e.g. gap
normalization, or cumulative-from-baseline) overrides `change_metrics` (see Change Detection
Logic). Most calculators inherit the default.

**Benefits:**
- Easy to unit test calculators independently
- Add new metrics by creating calculator class and adding to `MetricDefinition.available_calculators`
- Efficient batch processing handles 5,000+ entities per batch with single queries

## Data Collection Strategy

**Implementation**: `GrdaWarehouse::Monitoring::Tasks::MetricSnapshotCollector`

**Job**: `CollectClientMetricsJob`

### Batch Processing

- Processes 5,000 entities per batch for efficient memory usage
- Uses bulk imports via `activerecord-import` gem
- Tracks statistics per run: entities evaluated, snapshots created/updated, errors

### Active Entity Filtering

Only calculate metrics for entities with recent activity:
- **Clients**: Destination clients with service history in last 3 years

### Scheduled Execution

Collection runs once per day at 2:00 AM. The hourly maintenance rake task (`lib/tasks/grda_warehouse.rake`) enqueues `CollectClientMetricsJob` only when the current hour matches `MetricDefinition::COLLECTION_HOUR` (`2`).

Integrated with TaskQueue for initialization: `MetricDefinition.maintain!` creates/updates metric definitions on startup

## Data Retention Strategy

### Simple 3-Year Retention

Delete any snapshot where `current_observation_date < 3 years ago`.

**Retention Rules:**
- Keep **all snapshots** where `current_observation_date` is within the last **3 years**
- Delete snapshots where last verification is older than 3 years

**Cleanup**: Runs automatically during daily collection

**Example Timeline:**

```
Snapshot Record                              Retention Status (as of Jan 1, 2025)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
initial: Jan 15, 2024                       Kept (current_observation_date within 3 years)
current: Dec 28, 2024
(stable period, 348 days)

initial: Dec 29, 2024                       Kept (current_observation_date within 3 years)
current: Jan 1, 2025
(recent change)

initial: Mar 1, 2021                        DELETED (current_observation_date > 3 years ago)
current: Dec 31, 2021
(old snapshot, no longer relevant)
```

**Benefits:**
- Simple, easy to understand policy
- Range-based storage means stable clients naturally have few snapshots
- Partitioning by quarter enables efficient archival and deletion
- No complex graduated retention logic needed

**Result:**
- Full history for 3 years (compliance and trend analysis)
- Automatic cleanup keeps storage manageable
- Storage naturally concentrates on volatile clients

### Storage Efficiency

Storage scales with: (entities × metrics × change_rate × retention_period). See "Storage
Efficiency" under Sparse Storage Strategy above for the concrete row/GB estimate — the same
98%+ reduction applies here since retention only prunes snapshots that are already sparse.

## Query Patterns & API

**Status**: Query interface not yet implemented (Phase 4)

**Planned**: `HasMetricSnapshots` concern for easy metric access from entity models

**Current Access**: Direct queries via `GrdaWarehouse::Monitoring::MetricSnapshot` model

The model includes scopes for common query patterns:
- `for_entity(entity)` - All snapshots for a specific entity
- `for_metric(metric_definition)` - All snapshots for a specific metric
- `active_as_of(date)` - Snapshots active on a given date
- `current` - Snapshots still being updated (not stale)
- `stale` - Snapshots that haven't been updated recently
- `crossed_threshold_on_date(date)` - Snapshots created (i.e. crossed a threshold) on a given date
- `for_date_range(start_date, end_date)` - Snapshots overlapping a date range

See `app/models/grda_warehouse/monitoring/metric_snapshot.rb` for implementation.

## Implemented Metrics

### Client Metrics

| Metric Name | Display Name | Calculator | Threshold | Description |
|-------------|--------------|------------|-----------|-------------|
| `days_homeless_last_three_years` | Days Homeless (Last 3 Years) | `HomelessDaysLastThreeYearsCalculator` | 30 days/run* | Total days homeless from service history (per-run detection) |
| `max_household_size` | Maximum Household Size | `MaxHouseholdSizeCalculator` | 1* | Largest household client has been part of (default per-run detection) |
| `min_household_size` | Minimum Household Size | `MinHouseholdSizeCalculator` | 1* | Smallest household client has been part of (default per-run detection) |

\* Seeded default; editable per metric in the admin UI.

**Data Sources:**
- Days homeless: `GrdaWarehouse::WarehouseClientsProcessed` table
- Household sizes: `GrdaWarehouse::Hud::Enrollment` table, grouped by `[data_source_id, HouseholdID]`

### Future Client Metrics

Additional metrics to implement based on usage patterns:

| Metric Name | Display Name | Description |
|-------------|--------------|-------------|
| `source_client_count` | Source Client Count | Number of source records merged into this client |
| `enrollment_count_last_three_years` | Enrollment Count (Last 3 Years) | Number of enrollments |
| `unique_projects_last_three_years` | Unique Projects (Last 3 Years) | Number of distinct projects served in |
| `current_living_situation_count` | Current Living Situation Records | Number of CLS assessments |
| `service_count` | Service Count | Total service records |

### Future Entity Types

**Project Metrics:**
- `active_client_count` - Clients with services on snapshot date
- `bed_utilization_rate` - Percentage of beds occupied

**Data Source Metrics:**
- `import_freshness` - Days since last successful import
- `total_record_count` - Total records in data source

**Organization Metrics:**
- `total_enrollments` - Active enrollments across all projects
- `data_quality_score` - Calculated data quality metric

## Performance Characteristics

### Expected Runtime (200,000 clients, 3 metrics)

*Design-time estimate, not a measured benchmark — treat as directional until validated against
a production-scale run.*

```
Operation                           Time
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Query active clients                ~5s
Calculate 40 batches (5k each)     ~15s
Bulk inserts/updates                ~3s
Cleanup old snapshots               ~1s
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total                              ~24s
```

*Note: Actual runtime varies based on data volume and metric volatility*

### Optimization Techniques

1. **Batch Processing**: Process 5,000 entities per batch to limit memory usage
2. **Bulk Operations**: Use `activerecord-import` for efficient inserts/updates
3. **Efficient Calculators**: Single-query batch calculation for all entities
4. **Active Entity Filtering**: Only process clients with recent service history
5. **Partitioned Tables**: Quarterly partitions improve query performance and archival
6. **Composite Indexes**: Cover common query patterns for fast lookups
7. **Sparse Storage**: Threshold-based snapshot creation minimizes writes

## Integration Points

### Alert System Integration

Metrics can drive alerts through change detection.  Alerts for system-level thresholds can be enabled on the user edit screen.  Alerts for project or organization level thresholds can be applied on the contact pages for projects and organizations.  At this time there are no project or organization level thresholds.

## Extensibility

### Adding a New Metric

1. **Create Calculator Class** in `app/models/grda_warehouse/monitoring/metric_calculators/`
   - Inherit from `BaseCalculator`
   - Implement `calculate_batch(entities, calculation_date)` class method
   - Define `metric_definition_attributes` class method with configuration
   - Include batch processing for efficiency (single query for all entities)

2. **Register Calculator**
   - Add to `available_calculators` array in `MetricDefinition`

3. **Run Maintenance Task**
   - `MetricDefinition.maintain!` will create the metric definition

4. **Enable the New Threshold**
   - Visit the threshold monitoring page in the admin section and enable the threshold monitoring

5. **Next Collection Run**: New metric automatically calculated for all active entities


## Testing Strategy

### Unit Tests

- **Calculators**: Test calculation logic with known inputs, batch processing efficiency
- **Models**: Test associations, validations, scopes
- **Threshold Logic**: Test AND logic when both count and percent thresholds configured

### Integration Tests

- **Collection Flow**: End-to-end batch collection with threshold detection
- **Data Retention**: Verify 3-year cleanup preserves correct records
- **Statistics Tracking**: Verify calculation run records track correct counts

## Key Design Decisions

Rationale for range-based sparse storage, the single-integer-value schema, quarterly table
partitioning, self-configuring calculators, and single-query batch processing is covered inline
above (see Schema, Change Detection Logic, Calculator Pattern, and Batch Processing). The one
decision not already covered elsewhere:

### Calculator-Owned Change Detection (`change_metrics`)

**Decision**: The calculator decides *how much* a value changed; the collector decides whether
that change is *significant* against the metric definition's thresholds.

**Rationale**:
- Every strategy measures change **since the last observed value** (`current_value`), never from
  the original `initial_value`. Measuring from `initial_value` let a rolling-window total that
  drifts ~1/day accumulate past the threshold and fire a crossing whose per-run change was only
  ±1. This was a real production bug. Because thresholds are admin-editable, the same drift bug
  would appear for *any* metric configured with a count threshold above 1 — so the fix belongs in
  the shared default, not just the one metric that exposed it.
- The calculator returns **both** `count_change` and `percent_change` so the two share a single
  basis and normalization. Earlier the collector re-derived percent from an un-normalized
  reference while the count was normalized — a latent unit mismatch that would understate percent
  after a multi-day gap. Owning both in the calculator removes that class of bug.
- Putting the comparison in the calculator keeps `should_create_new_snapshot?` generic (it only
  knows about thresholds, which live on the editable metric definition) and lets each metric opt
  into the strategy that fits without special-casing it in the shared collector.

**Strategies** (both return `{ count_change:, percent_change: }`, measured since `current_value`):
- **Default (`BaseCalculator`)**: `count_change = |calculated_value − current_value|`, no
  elapsed-day normalization. Inherited by household-size and CSV row-count metrics.
- **Per-run, gap-normalized (`HomelessDaysLastThreeYearsCalculator`)**: additionally divides by
  `days_elapsed`, and normalizes `percent_change` the same way, so a crossing reflects a real
  per-day jump, not gradual accumulation or a multi-day catch-up after a missed run.

**Trade-offs**:
- The default strategy is per-run rather than cumulative-from-baseline; a future metric that
  genuinely wants cumulative-from-`initial_value` detection would override `change_metrics`.
- The displayed "Previous Value / New Value / Change" already reads the prior snapshot's
  `current_value` and the new snapshot's `initial_value`, which is consistent with per-run
  detection — no display changes were needed.
