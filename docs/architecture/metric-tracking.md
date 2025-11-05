# Metric Tracking System - Architecture

## Overview

This document outlines the design for a flexible, performant metric tracking system that monitors changes in client data over time. The system enables trend analysis, alerting, and reporting on key client metrics while handling hundreds of thousands of client records efficiently.

## Goals

1. Track key client metrics over time with daily granularity
2. Support multiple entity types (clients, projects, data sources, organizations)
3. Make metrics extensible without schema changes
4. Provide performant queries for time-series data and change detection
5. Maintain reasonable storage requirements through intelligent data retention
6. Enable integration with alerting and reporting systems

## Use Cases

- **Change Detection**: Identify when client metrics change significantly (e.g., days homeless increases by 30+)
- **Trend Analysis**: Chart how metrics evolve over time for individuals or cohorts
- **Alerting**: Trigger notifications when metrics cross thresholds
- **Reporting**: Aggregate metrics across populations for analytics
- **Historical Tracking**: Maintain audit trail of metric evolution

## Data Model Architecture

### Core Design Principles

1. **Polymorphic Entities**: Track metrics for any entity type (Client, Project, DataSource, etc.)
2. **Flexible Values**: Support multiple data types (integer, float, string, boolean, JSON)
3. **Pluggable Calculators**: Separate metric calculation logic from storage
4. **Single Table Storage**: Simplified querying with intelligent retention policy
5. **Performance Optimized**: Batch processing, bulk upserts, composite indexes

### Schema

#### Metric Definitions Table (`metric_definitions`)

Stores the catalog of available metrics and how to calculate them.

```ruby
create_table :metric_definitions, comment: 'Catalog of available metrics and calculation rules' do |t|
  t.string :name, null: false, limit: 100, comment: 'Unique identifier (e.g., days_homeless_last_three_years)'
  t.string :display_name, null: false, comment: 'Human-readable name for UI'
  t.text :description, comment: 'Detailed description of what this metric measures'

  t.string :entity_type, null: false, comment: 'Entity class this metric applies to (e.g., GrdaWarehouse::Hud::Client)'
  t.string :calculator_class, null: false, comment: 'Ruby class that implements calculation logic'
  t.integer :calculation_window_days, comment: 'Lookback period in days (e.g., 1095 for 3 years)'

  t.integer :count_change_threshold, comment: 'Only record snapshot if value changes by at least this amount (sparse storage)'
  t.decimal :percent_change_threshold, precision: 5, scale: 2, comment: 'Only record snapshot if value changes by at least this percentage (sparse storage)'

  t.string :category, limit: 50, comment: 'Grouping category for UI organization'
  t.boolean :active, default: true, null: false, comment: 'Whether this metric is actively being calculated'

  t.timestamps

  t.index [:entity_type, :name], unique: true, name: 'index_metric_defs_on_entity_and_name'
  t.index :active
  t.index :category
end
```

**Key Fields:**

- `name`: Unique identifier within entity type (used in code)
- `entity_type`: What this metric applies to (Client, Project, etc.)
- `calculator_class`: Ruby class that implements calculation logic
- `calculation_window_days`: Lookback period (e.g., 1095 days = 3 years)
- `category`: Grouping for UI and reporting

**Design Decision: Single Value Type**

All metrics store integer values in a single column. This simplifies the schema and is appropriate since all current and planned metrics are count-based (days, enrollments, household sizes, etc.).

#### Metric Snapshots Table (`metric_snapshots`)

Stores time-range snapshots using range-based sparse storage. Each snapshot represents a period where a metric value stayed within the configured threshold.

```ruby
create_table :metric_snapshots, comment: 'Time-series snapshots of metric values (range-based sparse storage)',
             partition_by: { type: :range, key: :initial_observation_date } do |t|
  t.references :entity, polymorphic: true, null: false, comment: 'Entity being measured'
  t.references :metric_definition, null: false, foreign_key: true, comment: 'Which metric this snapshot is for'

  t.date :initial_observation_date, null: false, comment: 'Date this value range started'
  t.date :current_observation_date, null: false, comment: 'Date this value was last calculated/verified'

  t.integer :initial_value, null: false, comment: 'Value when first observed'
  t.integer :current_value, null: false, comment: 'Value as of last verification (updated daily)'

  t.string :calculation_version, limit: 20, comment: 'Version of calculator that produced this value'

  t.timestamps

  t.index [:entity_type, :entity_id, :metric_definition_id, :current_observation_date, :initial_observation_date],
          unique: true,
          name: 'index_metric_snapshots_unique'
  t.index [:metric_definition_id, :current_observation_date]
  t.index [:entity_type, :entity_id, :current_observation_date]
end
```

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

Each metric definition specifies threshold(s):
- **`count_change_threshold`**: Create new snapshot if value changed by at least N (e.g., 30 days)
- **`percent_change_threshold`**: Create new snapshot if value changed by at least N% (e.g., 10%)
- **Both specified**: Requires **both** thresholds met (AND logic) to prevent false positives
- **Neither specified**: Create new snapshot on any change (dense storage)

Implementation: See `GrdaWarehouse::Monitoring::Tasks::MetricSnapshotCollector#should_create_new_snapshot?`

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

**Days Homeless** (significant changes only):
```ruby
count_change_threshold: 30
percent_change_threshold: nil
# Only creates new snapshot when days change by 30+
```

**Household Size** (any change):
```ruby
count_change_threshold: 1
percent_change_threshold: nil
# Creates new snapshot on any household size change
```

### Calculator Pattern

Metrics are calculated by pluggable calculator classes that follow a standard interface.

**Base Class**: `GrdaWarehouse::Monitoring::MetricCalculators::BaseCalculator`

**Key Features:**
- **Self-Configuring**: Each calculator defines its own metric definition via `metric_definition_attributes` class method
- **Batch Processing**: Calculators implement `calculate_batch(entities, calculation_date)` for efficient bulk calculation
- **Versioning**: Track when calculation logic changes via `version` method
- **Separation of Concerns**: Calculation logic isolated from storage

**Implemented Calculators:**
- `HomelessDaysLastThreeYearsCalculator` - Uses `GrdaWarehouse::WarehouseClientsProcessed` table
- `MinHouseholdSizeCalculator` - Analyzes enrollments across data sources
- `MaxHouseholdSizeCalculator` - Analyzes enrollments across data sources

**Benefits:**
- Easy to unit test calculators independently
- Add new metrics by creating calculator class and adding to `MetricDefinition::AVAILABLE_CALCULATORS`
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

Runs hourly via rake task at 2:00 AM (configured via `MetricDefinition::COLLECTION_HOUR`)

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

### Client Metrics (3-year lookback window)

| Metric Name | Display Name | Calculator | Threshold | Description |
|-------------|--------------|------------|-----------|-------------|
| `days_homeless_last_three_years` | Days Homeless (Last 3 Years) | `HomelessDaysLastThreeYearsCalculator` | 30 days | Total days homeless from service history |
| `max_household_size` | Maximum Household Size | `MaxHouseholdSizeCalculator` | 1 | Largest household client has been part of |
| `min_household_size` | Minimum Household Size | `MinHouseholdSizeCalculator` | 1 | Smallest household client has been part of |

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

### Future: Alert System Integration

Metrics can drive alerts through change detection:
- Alert when homeless days increase significantly
- Notify case managers of household composition changes
- Track data quality metrics and flag issues

### Future: Reporting Integration

Metrics provide time-series data for dashboards and reports:
- Trend charts showing metric evolution over time
- Cohort analysis comparing metric trends across groups
- Change reports highlighting entities with significant changes
- Aggregate statistics (sum, average, percentiles)

### Future: API Integration

Expose metrics via API endpoints for external consumption

## Extensibility

### Adding a New Metric

1. **Create Calculator Class** in `app/models/grda_warehouse/monitoring/metric_calculators/`
   - Inherit from `BaseCalculator`
   - Implement `calculate_batch(entities, calculation_date)` class method
   - Define `metric_definition_attributes` class method with configuration
   - Include batch processing for efficiency (single query for all entities)

2. **Register Calculator**
   - Add to `AVAILABLE_CALCULATORS` array in `MetricDefinition`

3. **Run Maintenance Task**
   - `MetricDefinition.maintain!` will create the metric definition
   - Or restart application (runs automatically via TaskQueue)

4. **Next Collection Run**: New metric automatically calculated for all active entities

**No schema changes or manual database updates required!**

### Adding a New Entity Type

1. **Create Calculators** for metrics applicable to this entity

2. **Update Active Entity Filtering** in `MetricSnapshotCollector#get_active_entities`

3. **Create Collection Job** (or extend existing job to handle multiple entity types)

## Testing Strategy

### Unit Tests

- **Calculators**: Test calculation logic with known inputs, batch processing efficiency
- **Models**: Test associations, validations, scopes
- **Threshold Logic**: Test AND logic when both count and percent thresholds configured

### Integration Tests

- **Collection Flow**: End-to-end batch collection with threshold detection
- **Data Retention**: Verify 3-year cleanup preserves correct records
- **Statistics Tracking**: Verify calculation run records track correct counts

**Test Location**: `spec/models/grda_warehouse/monitoring/`

**Run Tests**: `dcr spec bundle exec rspec spec/models/grda_warehouse/monitoring/`

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
- New snapshot created when threshold exceeded

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

## Migration Plan

See [implementation-working-documents/metric-tracking-implementation.md](../implementation-working-documents/metric-tracking-implementation.md) for detailed implementation steps.

## Future Enhancements

### Query Interface (Phase 4)

Implement `HasMetricSnapshots` concern for easy metric access from entity models:
- `client.metric_value('days_homeless_last_three_years')`
- `client.metric_time_series('days_homeless_last_three_years', start_date:, end_date:)`
- `client.metric_change('days_homeless_last_three_years', days_back: 7)`

### Additional Metrics

Implement remaining planned client metrics:
- Enrollment counts
- Unique projects served
- Service counts
- Current living situation assessments
- Source client counts

### Alert System

Use metrics for change-based alerting:
- Detect significant increases in homeless days
- Monitor household composition changes
- Track data quality indicators

### Reporting & Visualization

Build dashboards showing:
- Trend charts with interpolation
- Cohort analysis across client groups
- Change detection reports
- Population-level aggregations

### Metric Metadata

Store additional context with snapshots (JSONB column):
- Data quality flags
- Confidence scores
- Contributing factors for changes

### Additional Entity Types

Extend to Projects, Data Sources, and Organizations with relevant metrics

## References

### Implementation Files

**Models:**
- `app/models/grda_warehouse/monitoring/metric_definition.rb`
- `app/models/grda_warehouse/monitoring/metric_snapshot.rb`
- `app/models/grda_warehouse/monitoring/metric_calculation_run.rb`

**Calculators:**
- `app/models/grda_warehouse/monitoring/metric_calculators/base_calculator.rb`
- `app/models/grda_warehouse/monitoring/metric_calculators/homeless_days_last_three_years_calculator.rb`
- `app/models/grda_warehouse/monitoring/metric_calculators/min_household_size_calculator.rb`
- `app/models/grda_warehouse/monitoring/metric_calculators/max_household_size_calculator.rb`

**Collection:**
- `app/models/grda_warehouse/monitoring/tasks/metric_snapshot_collector.rb`
- `app/jobs/collect_client_metrics_job.rb`

**Migrations:**
- `db/warehouse/migrate/20251020141816_create_metric_definitions.rb`
- `db/warehouse/migrate/20251020142047_create_metric_snapshots.rb`
- `db/warehouse/migrate/20251020142304_create_metric_calculation_runs.rb`

**Tests:**
- `spec/models/grda_warehouse/monitoring/`

### Related Documentation

- Implementation Details: `docs/implementation-working-documents/metric-tracking-implementation.md`
- Warehouse Clients Processed: `app/models/grda_warehouse/warehouse_clients_processed.rb`
- Service History: `app/models/grda_warehouse/service_history_service.rb`
