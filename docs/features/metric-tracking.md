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
   which returns `{ count_change:, reference_value: }`. The calculator owns this because the
   correct comparison depends on the nature of the metric (see strategies below).
2. **Is that change significant?** — decided by the collector, comparing `count_change`
   (and a percent derived from `reference_value`) against the thresholds configured on the
   metric definition.

**Detection strategies** (the `change_metrics` half):

- **Absolute (default, `BaseCalculator`)**: `count_change = |calculated_value − initial_value|`,
  measured from the snapshot's original baseline. Used for static or discrete metrics where any
  deviation from the established value is meaningful (household sizes, CSV row counts). For these
  metrics `initial_value` and `current_value` stay equal, so there is no difference between
  "since baseline" and "since last run".
- **Per-run, gap-normalized (`HomelessDaysLastThreeYearsCalculator`)**: measures the change
  against the **previous run's** value (`current_value`) and divides by the days since that run:
  `count_change = |calculated_value − current_value| / days_elapsed` (with `days_elapsed`
  floored at 1). This suits a rolling-window total that drifts a little each day — a crossing
  fires only on a genuine per-day jump, not on gradual drift accumulating past the threshold,
  and a multi-day catch-up after a missed run is averaged rather than mistaken for a spike.

**Thresholds** (the collector half), configured per metric definition:
- **`count_change_threshold`**: Create new snapshot if `count_change` is at least N (e.g., 30 —
  for `days_homeless` this means 30+ days *per day*)
- **`percent_change_threshold`**: Create new snapshot if the change is at least N% of
  `reference_value` (e.g., 10%)
- **Both specified**: Requires **both** thresholds met (AND logic) to prevent false positives
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

**Household Size** (absolute detection, any change):
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
- `MinHouseholdSizeCalculator` - Analyzes enrollments across data sources (absolute detection)
- `MaxHouseholdSizeCalculator` - Analyzes enrollments across data sources (absolute detection)

A calculator that needs detection other than the default absolute-from-baseline comparison
overrides `change_metrics` (see Change Detection Logic). Most calculators inherit the default.

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

Storage scales with: (entities × metrics × change_rate × retention_period)

With range-based sparse storage:
- **Stable clients** (few changes): Minimal snapshots, cheap to track
- **Volatile clients** (frequent changes): More snapshots, but captures important change history
- **Overall**: 98%+ reduction compared to dense daily storage

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

See `app/models/grda_warehouse/monitoring/metric_snapshot.rb` for implementation.

## Implemented Metrics

### Client Metrics

| Metric Name | Display Name | Calculator | Threshold | Description |
|-------------|--------------|------------|-----------|-------------|
| `days_homeless_last_three_years` | Days Homeless (Last 3 Years) | `HomelessDaysLastThreeYearsCalculator` | 30 days/run* | Total days homeless from service history (per-run detection) |
| `max_household_size` | Maximum Household Size | `MaxHouseholdSizeCalculator` | 1* | Largest household client has been part of (absolute detection) |
| `min_household_size` | Minimum Household Size | `MinHouseholdSizeCalculator` | 1* | Smallest household client has been part of (absolute detection) |

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

### 1. Range-Based Sparse Storage

**Decision**: Each snapshot represents a time range where value stayed within threshold

**Rationale**:
- Most metrics are stable day-to-day (stable clients have minimal changes)
- Recording every value every day wastes 98%+ of storage
- Focus on tracking actual changes (the interesting data)
- Can detect spikes by analyzing snapshot duration

**Benefits**:
- **98%+ storage reduction** for typical workloads
- Naturally captures metric stability vs volatility
- Efficient for both stable and changing metrics

**Trade-offs**:
- Query logic must handle date ranges (between `initial_observation_date` and `current_observation_date`)
- More complex collection logic (update existing vs create new)
- Time series visualizations need to interpolate

**Implementation**:
- `initial_observation_date`: When value range started
- `current_observation_date`: Updated daily while value stays within threshold
- `initial_value` and `current_value`: Track value drift
- New snapshot created when the calculator-reported change exceeds the threshold (see Change Detection Logic for the absolute vs per-run strategies)

### 2. Single Integer Value Column

**Decision**: All metrics store integer values, no polymorphic value columns

**Rationale**:
- All current and planned metrics are count-based (days, enrollments, household sizes)
- Simplifies schema and eliminates NULL columns
- Database enforces type safety
- Easy to query and aggregate

**Trade-offs**:
- If non-integer metrics needed in future, would require schema change
- Acceptable given current requirements

### 3. Table Partitioning

**Decision**: Partition by `initial_observation_date` with quarterly partitions

**Rationale**:
- Enables efficient archival and deletion of old data
- Improves query performance for date-range queries
- Pre-create partitions (3 years past + 10 years future) to avoid maintenance

**Trade-offs**:
- Unique constraints must include partition key
- Requires PostgreSQL 10+
- More complex migration

### 4. AND Logic for Dual Thresholds

**Decision**: When both count and percent thresholds configured, require BOTH to be met

**Rationale**:
- Prevents false positives where small absolute changes in large values would trigger percent threshold
- More conservative approach ensures significant changes only

**Example**: If threshold is 30 days AND 10%:
- Value 100 → 115: Change is 15 days (< 30), 15% → No new snapshot (count not met)
- Value 100 → 135: Change is 35 days (> 30), 35% → New snapshot (both met)

### 5. Self-Configuring Calculators

**Decision**: Calculators define their own metric definitions via class methods

**Rationale**:
- Single source of truth for metric configuration
- No separate seed files or manual database updates
- Automatic registration via `MetricDefinition.maintain!`
- Easy to add new metrics (create calculator + register)

**Benefits**:
- Eliminates configuration drift
- Simplifies deployment (no seed step)
- Clear documentation in calculator class

### 6. Batch Processing with Single Queries

**Decision**: Calculators implement `calculate_batch` that processes 5,000 entities with single query

**Rationale**:
- Dramatically faster than per-entity queries
- Reduces database load
- Enables collection to complete in minutes, not hours

**Example**: Household size calculators use two queries for entire batch:
1. Count members per `[data_source_id, HouseholdID]`
2. Lookup households per client

**Benefits**:
- 5,000+ entities processed per batch
- Sub-minute calculation times
- Scalable to large datasets

### 7. Calculator-Owned Change Detection (`change_metrics`)

**Decision**: The calculator decides *how much* a value changed; the collector decides whether
that change is *significant* against the metric definition's thresholds.

**Rationale**:
- The correct comparison depends on the metric. A discrete attribute (household size) should
  alert on any deviation from its established value, while a rolling-window total (days homeless)
  drifts ~1/day — comparing it against a fixed baseline would eventually trip the threshold from
  accumulated drift alone, producing crossings whose day-over-day change is only ±1.
- Putting the comparison in the calculator keeps `should_create_new_snapshot?` generic (it only
  knows about thresholds, which live on the editable metric definition) and lets each metric opt
  into the strategy that fits without special-casing it in the shared collector.

**Strategies**:
- **Absolute (default)**: `|calculated_value − initial_value|`. Inherited by household-size and
  CSV row-count metrics, whose behavior is unchanged by this design.
- **Per-run, gap-normalized**: `|calculated_value − current_value| / days_elapsed`. Used by
  `HomelessDaysLastThreeYearsCalculator` so a crossing reflects a real per-day jump, not gradual
  accumulation or a multi-day catch-up after a missed run.

**Trade-offs**:
- Adds a small interface (`change_metrics` returning `{ count_change:, reference_value: }`) that
  every calculator inherits but few override.
- The displayed "Previous Value / New Value / Change" already reads the prior snapshot's
  `current_value` and the new snapshot's `initial_value`, which is consistent with per-run
  detection — no display changes were needed.
