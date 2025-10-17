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

  t.string :value_type, null: false, default: 'integer', comment: 'Data type: integer, float, string, boolean, json'

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
- `value_type`: Data type for validation and polymorphic storage
- `calculation_window_days`: Lookback period (e.g., 1095 days = 3 years)
- `category`: Grouping for UI and reporting

#### Metric Snapshots Table (`metric_snapshots`)

Stores daily snapshots of metric values with intelligent retention.

```ruby
create_table :metric_snapshots, comment: 'Time-series snapshots of metric values (sparse storage)' do |t|
  t.references :entity, polymorphic: true, null: false, comment: 'Entity being measured'
  t.references :metric_definition, null: false, foreign_key: true, comment: 'Which metric this snapshot is for'
  t.date :snapshot_date, null: false, comment: 'Date this snapshot was taken'

  t.bigint :value_integer, comment: 'Value storage for integer metrics'
  t.decimal :value_float, precision: 20, scale: 6, comment: 'Value storage for float metrics'
  t.string :value_string, limit: 500, comment: 'Value storage for string metrics'
  t.boolean :value_boolean, comment: 'Value storage for boolean metrics'
  t.jsonb :value_json, comment: 'Value storage for JSON metrics'

  t.string :calculation_version, limit: 20, comment: 'Version of calculator that produced this value'

  t.timestamps

  t.index [:entity_type, :entity_id, :metric_definition_id, :snapshot_date],
          unique: true,
          name: 'index_metric_snapshots_unique'
  t.index :snapshot_date
  t.index [:metric_definition_id, :snapshot_date]
  t.index [:entity_type, :entity_id, :snapshot_date]
  t.index [:entity_type, :entity_id, :metric_definition_id, :snapshot_date],
          name: 'index_metric_snapshots_for_time_series'
end
```

**Design Decisions:**

- **Sparse Storage**: Only record snapshots when values change significantly (see Sparse Storage Strategy)
- **Polymorphic Storage**: Single `value_*` column used based on `value_type` (reduces NULL columns)
- **No calculated_at field**: Use `created_at` timestamp (eliminates redundancy)
- **Single table**: No separate weekly table (see Data Retention Strategy)
- **Composite indexes**: Optimized for common query patterns (time series, change detection)

### Sparse Storage Strategy

**Key Insight**: Most metrics don't change daily. Recording every value every day wastes massive storage.

**Solution**: Only record a snapshot when the value changes by a meaningful amount.

#### Change Detection Logic

Each metric definition specifies threshold(s):
- **`count_change_threshold`**: Record if value changed by at least N (e.g., 5 days)
- **`percent_change_threshold`**: Record if value changed by at least N% (e.g., 10%)
- If both specified, record if **either** threshold is met
- If neither specified, record **every** calculation (dense storage)

#### Implementation

```ruby
def should_record_snapshot?(entity, metric_definition, new_value)
  # Always record first snapshot
  return true unless previous_snapshot = find_latest_snapshot(entity, metric_definition)

  previous_value = previous_snapshot.value

  # Handle nil/null values
  return true if new_value.nil? != previous_value.nil?
  return false if new_value.nil? && previous_value.nil?

  # Check thresholds
  count_threshold = metric_definition.count_change_threshold
  percent_threshold = metric_definition.percent_change_threshold

  # No thresholds = always record
  return true if count_threshold.nil? && percent_threshold.nil?

  change = (new_value - previous_value).abs

  # Count threshold
  if count_threshold && change >= count_threshold
    return true
  end

  # Percent threshold
  if percent_threshold && previous_value != 0
    percent_change = (change.to_f / previous_value.abs * 100)
    return true if percent_change >= percent_threshold
  end

  false
end
```

#### Benefits

**Storage Reduction Example** (200K clients, 8 metrics):

Without sparse storage:
- Daily (30 days): 200K × 8 × 30 = 48M rows
- Weekly (5 years): 200K × 8 × 260 = 416M rows
- **Total: 464M rows (~70 GB)**

With sparse storage (assuming 10% change rate):
- Daily (30 days): 200K × 8 × 30 × 0.10 = 4.8M rows
- Weekly (5 years): 200K × 8 × 260 × 0.10 = 41.6M rows
- **Total: 46.4M rows (~7 GB)**

**90% storage reduction!**

#### Query Implications

Since we only record changes, queries must handle gaps:

```ruby
# Get current value (find most recent snapshot)
def metric_value(metric_name, as_of_date: Date.current)
  metric_snapshots
    .where(metric_definition: metric_def)
    .where('snapshot_date <= ?', as_of_date)
    .order(snapshot_date: :desc)
    .first
    &.value
end

# Time series returns actual recorded values (with gaps)
def metric_time_series(metric_name, start_date:, end_date:)
  metric_snapshots
    .where(metric_definition: metric_def)
    .where(snapshot_date: start_date..end_date)
    .order(:snapshot_date)
    .pluck(:snapshot_date, :value)
  # Returns: [[date1, value1], [date5, value2], [date12, value3], ...]
  # UI can interpolate or show actual change points
end
```

#### Example Metric Configurations

**Volatile Metrics** (record more frequently):
```ruby
# Days homeless - record every 5 day change
count_change_threshold: 5
percent_change_threshold: nil
```

**Stable Metrics** (record less frequently):
```ruby
# Source client count - record every 1 client change
count_change_threshold: 1
percent_change_threshold: nil
```

**Percentage-based**:
```ruby
# Enrollment count - record 10% changes
count_change_threshold: nil
percent_change_threshold: 10.0
```

**Both thresholds**:
```ruby
# Service count - record if changes by 50 services OR 20%
count_change_threshold: 50
percent_change_threshold: 20.0
```

**Dense storage** (always record):
```ruby
# Critical metrics - record every day
count_change_threshold: nil
percent_change_threshold: nil
```

### Calculator Pattern

Metrics are calculated by pluggable calculator classes following a standard interface:

```ruby
# Base calculator class
class GrdaWarehouse::MetricCalculators::BaseCalculator
  attr_reader :entity, :snapshot_date

  def initialize(entity, snapshot_date)
    @entity = entity
    @snapshot_date = snapshot_date
  end

  # Subclasses must implement
  def calculate
    raise NotImplementedError
  end

  # Version for tracking calculation logic changes
  def version
    '1.0.0'
  end

  # Helper methods
  def lookback_window
    metric_definition.calculation_window_days&.days || 3.years
  end

  def lookback_start_date
    snapshot_date - lookback_window
  end
end

# Example calculator
class GrdaWarehouse::MetricCalculators::Client::HomelessDaysCalculator < BaseCalculator
  def calculate
    GrdaWarehouse::ServiceHistoryService
      .where(client_id: entity.id)
      .where(date: lookback_start_date..snapshot_date)
      .where(homeless: true)
      .select(:date)
      .distinct
      .count
  end
end
```

**Benefits:**

- **Separation of Concerns**: Calculation logic isolated from storage
- **Testability**: Easy to unit test calculators independently
- **Versioning**: Track when calculation logic changes
- **Extensibility**: Add new metrics by creating calculator classes

## Data Collection Strategy

### Batch Processing

Daily collection runs in batches to handle large datasets efficiently:

```ruby
# Process 5,000 entities per batch
BATCH_SIZE = 5_000

entities.in_groups_of(BATCH_SIZE, false) do |batch|
  calculate_batch(batch, metrics)
end
```

### Bulk Upserts

Use `activerecord-import` gem for efficient batch inserts:

```ruby
GrdaWarehouse::MetricSnapshot.import(
  snapshots,
  on_duplicate_key_update: {
    conflict_target: [:entity_type, :entity_id, :metric_definition_id, :snapshot_date],
    columns: [:value_integer, :calculation_version, :updated_at]
  }
)
```

### Active Entity Filtering

Only calculate metrics for entities with recent activity:

```ruby
# For clients: those with service activity in last 3 years
GrdaWarehouse::Hud::Client
  .destination  # Only consolidated destination clients
  .joins(:service_history_services)
  .where('service_history_services.date >= ?', 3.years.ago)
  .where('service_history_services.date <= ?', snapshot_date)
  .distinct
```

### Scheduled Execution

Daily batch job runs at 2 AM (after overnight data imports):

```ruby
# config/schedule.rb
every 1.day, at: '2:00 am' do
  runner "CollectClientMetricsJob.perform_later"
  runner "CollectProjectMetricsJob.perform_later"
  runner "CollectDataSourceMetricsJob.perform_later"
end
```

## Data Retention Strategy

### Single-Table Retention with Weekly Anchors

Instead of maintaining separate daily and weekly tables, we use a single table with intelligent cleanup:

**Retention Rules:**
- Keep **all daily snapshots** for the last **30 days**
- Keep **weekly snapshots** (every Wednesday) **indefinitely**
- Delete all other snapshots older than 30 days

**Cleanup Logic:**

```ruby
DAILY_RETENTION_DAYS = 30
WEEKLY_ANCHOR_DAY = 3  # Wednesday (0=Sunday, 1=Monday, etc.)

cutoff_date = Date.current - DAILY_RETENTION_DAYS.days

# Delete snapshots older than 30 days, except Wednesdays
GrdaWarehouse::MetricSnapshot
  .where(entity_type: 'GrdaWarehouse::Hud::Client')
  .where('snapshot_date < ?', cutoff_date)
  .where('EXTRACT(DOW FROM snapshot_date) != ?', WEEKLY_ANCHOR_DAY)
  .delete_all
```

**Example Timeline:**

```
Date        Retention Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Jan 1 Mon   Kept (within 30 days)
Jan 2 Tue   Kept (within 30 days)
Jan 3 Wed   Kept (weekly anchor)
...
Jan 31 Wed  Kept (weekly anchor)
Feb 1 Thu   Kept (within 30 days)
            Cleanup: Jan 1 deleted (>30 days, not Wed)
Feb 2 Fri   Kept (within 30 days)
            Cleanup: Jan 2 deleted (>30 days, not Wed)
Feb 3 Sat   Kept (within 30 days)
            Cleanup: Jan 3 KEPT (Wednesday!)
            Cleanup: Jan 4 deleted (>30 days, not Wed)
```

**Result:**
- Daily granularity for recent data (trend analysis)
- Weekly granularity for historical data (long-term tracking)
- Single table to query (simplified logic)

### Storage Efficiency

**For 200,000 clients × 8 metrics:**

**Without sparse storage (dense):**
- Last 30 days (all): 8 × 200,000 × 30 = 48M rows
- Historical (Wednesdays): 8 × 200,000 × 260 weeks = 416M rows
- **Total: 464M rows (~70 GB)**

**With sparse storage (10% change rate):**
- Last 30 days: 8 × 200,000 × 30 × 0.10 = 4.8M rows
- Historical (Wednesdays): 8 × 200,000 × 260 × 0.10 = 41.6M rows
- **Total: 46.4M rows (~7 GB)**

**90% storage reduction!** Actual reduction depends on metric volatility and threshold settings.

**With additional entity types (sparse):**
- Projects (500 × 2 metrics × 0.10): ~3K rows/month
- Data Sources (10 × 2 metrics × 0.10): ~60 rows/month

Storage scales with: (entities × metrics × change_rate × retention_period)

## Query Patterns & API

### Instance Methods (via Concern)

```ruby
# Include in any model that has metrics
module HasMetricSnapshots
  extend ActiveSupport::Concern

  included do
    has_many :metric_snapshots, as: :entity
  end

  # Get latest value
  def metric_value(metric_name, as_of_date: Date.current)
    # Returns value for specified metric
  end

  # Get time series
  def metric_time_series(metric_name, start_date: 90.days.ago, end_date: Date.current)
    # Returns [[date, value], [date, value], ...]
  end

  # Detect change
  def metric_change(metric_name, days_back: 1)
    # Returns numeric change or boolean for change detection
  end

  # Get all metrics as hash
  def all_metrics(as_of_date: Date.current)
    # Returns { 'metric_name' => value, ... }
  end
end

# Usage:
client = GrdaWarehouse::Hud::Client.find(123)
homeless_days = client.metric_value('days_homeless_last_three_years')
time_series = client.metric_time_series('days_homeless_last_three_years', start_date: 90.days.ago)
weekly_change = client.metric_change('days_homeless_last_three_years', days_back: 7)
```

### Class Methods (Batch Queries)

```ruby
# Get latest values for metric across entities
GrdaWarehouse::MetricSnapshot.latest_values_for(
  metric_name: 'days_homeless_last_three_years',
  entity_type: 'GrdaWarehouse::Hud::Client',
  entity_ids: [123, 456, 789]
)
# => {123 => 45, 456 => 67, 789 => 12}

# Find entities with significant changes
GrdaWarehouse::MetricSnapshot.entities_with_change(
  metric_name: 'days_homeless_last_three_years',
  entity_type: 'GrdaWarehouse::Hud::Client',
  threshold: 30,
  days_back: 7
)
# => [#<Client id=456>, #<Client id=789>]

# Aggregate across entities
GrdaWarehouse::MetricSnapshot.aggregate_metric(
  metric_name: 'days_homeless_last_three_years',
  entity_type: 'GrdaWarehouse::Hud::Client',
  aggregation: :sum  # or :avg, :min, :max, :count
)
# => 123456
```

## Initial Metrics

### Client Metrics (3-year lookback window)

| Metric Name | Display Name | Calculator | Description |
|-------------|--------------|------------|-------------|
| `days_homeless_last_three_years` | Days Homeless (Last 3 Years) | `HomelessDaysCalculator` | Total days with homeless services (ES, SO, SH, TH) |
| `source_client_count` | Source Client Count | `SourceClientCountCalculator` | Number of source records merged into this client |
| `max_household_size` | Maximum Household Size | `MaxHouseholdSizeCalculator` | Largest household client has been part of |
| `min_household_size` | Minimum Household Size | `MinHouseholdSizeCalculator` | Smallest household client has been part of |
| `enrollment_count_last_three_years` | Enrollment Count (Last 3 Years) | `EnrollmentCountCalculator` | Number of enrollments |
| `unique_projects_last_three_years` | Unique Projects (Last 3 Years) | `UniqueProjectsCalculator` | Number of distinct projects served in |
| `current_living_situation_count` | Current Living Situation Records | `CurrentLivingSituationCountCalculator` | Number of CLS assessments |
| `service_count` | Service Count | `ServiceCountCalculator` | Total service records |

### Future Metrics (Examples)

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

### Expected Runtime (200,000 clients, 8 metrics)

```
Operation                           Time
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Query active clients                ~5s
Calculate 40 batches (5k each)     ~20s
Bulk inserts                        ~5s
Cleanup old snapshots               ~2s
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total                              ~32s
```

### Query Performance

- **Single metric value**: <10ms (indexed lookup)
- **Time series (90 days)**: <50ms (date range scan)
- **Change detection**: <20ms (2 indexed lookups)
- **Batch values (1000 entities)**: <200ms (DISTINCT ON)
- **Aggregation (200k entities)**: <2s (full table scan with index)

### Optimization Techniques

1. **Composite Indexes**: Cover common query patterns
2. **DISTINCT ON**: PostgreSQL-specific efficient latest value queries
3. **Batch Processing**: Limit memory usage with 5k batch size
4. **Bulk Upserts**: Single transaction per batch
5. **Service History Tables**: Pre-calculated denormalized data
6. **Active Entity Filtering**: Only process clients with recent activity

## Integration Points

### Alert System Integration

Metrics can drive alerts through change detection:

```ruby
# Example: Alert when homeless days increase by 30+
class HomelessDaysIncreaseAlert
  def check_client(client_id)
    change = GrdaWarehouse::MetricSnapshot.detect_changes(
      client_id,
      'days_homeless_last_three_years',
      threshold: 30
    )

    if change && change > 0
      trigger_alert(
        client_id: client_id,
        message: "Client has #{change} additional homeless days"
      )
    end
  end
end
```

### Reporting Integration

Metrics provide time-series data for dashboards and reports:

- Trend charts (Chart.js, D3.js)
- Cohort analysis (compare metric trends across groups)
- Change reports (entities with significant changes)
- Aggregate statistics (sum, average, percentiles)

### API Integration

Expose metrics via API endpoints:

```ruby
GET /api/v1/clients/:id/metrics
GET /api/v1/clients/:id/metrics/:metric_name
GET /api/v1/clients/:id/metrics/:metric_name/time_series
```

## Extensibility

### Adding a New Metric

1. **Create Calculator Class**
   ```ruby
   class GrdaWarehouse::MetricCalculators::Client::NewMetricCalculator < BaseCalculator
     def calculate
       # Calculation logic
     end
   end
   ```

2. **Add Metric Definition**
   ```ruby
   GrdaWarehouse::MetricDefinition.create!(
     name: 'new_metric',
     display_name: 'New Metric',
     entity_type: 'GrdaWarehouse::Hud::Client',
     calculator_class: 'GrdaWarehouse::MetricCalculators::Client::NewMetricCalculator',
     value_type: 'integer',
     category: 'custom',
     calculation_window_days: 365
   )
   ```

3. **Next Daily Run**: New metric automatically calculated for all active entities

**No schema changes required!**

### Adding a New Entity Type

1. **Include Concern**
   ```ruby
   class MyEntity < ApplicationRecord
     include HasMetricSnapshots
   end
   ```

2. **Create Calculators** for metrics applicable to this entity

3. **Add Collection Job**
   ```ruby
   class CollectMyEntityMetricsJob < ApplicationJob
     def perform(snapshot_date = Date.current)
       GrdaWarehouse::Tasks::MetricSnapshotCollector.run_daily_collection(
         entity_type: 'MyEntity',
         snapshot_date: snapshot_date
       )
     end
   end
   ```

## Testing Strategy

### Unit Tests

- **Calculators**: Test calculation logic with known inputs
- **Models**: Test associations, validations, scopes
- **Concerns**: Test metric accessor methods

### Integration Tests

- **Collection Flow**: End-to-end batch collection
- **Data Retention**: Verify cleanup logic preserves correct records
- **Query API**: Test time series, change detection, aggregations

### Performance Tests

- **Benchmarks**: Measure collection time with realistic dataset sizes
- **Query Performance**: Ensure queries remain fast as data grows
- **Memory Usage**: Verify batch processing stays within limits

## Key Design Decisions

### 1. Polymorphic Entities

**Decision**: Use polymorphic association for `entity`

**Rationale**:
- Supports multiple entity types without duplicate tables
- Rails pattern (well-understood, good ORM support)
- Enables code reuse through concerns

**Trade-offs**:
- Slightly less efficient joins (requires entity_type check)
- Foreign key constraints require careful management

### 2. Polymorphic Value Storage

**Decision**: Multiple `value_*` columns instead of serialized column

**Rationale**:
- Type safety (database enforces integer, float constraints)
- Query efficiency (can filter/aggregate on typed columns)
- Index support (can index integer/float values)

**Trade-offs**:
- More NULL columns per row
- Requires accessor methods to hide complexity

### 3. Single Table Retention

**Decision**: Keep daily and weekly snapshots in one table

**Rationale**:
- Simpler queries (no need to UNION daily + weekly tables)
- Easier to understand and maintain
- Cleanup handled by single DELETE query

**Trade-offs**:
- Slightly less efficient storage (weekly rows have same schema overhead as daily)
- Cleanup must run carefully to preserve weekly anchors

### 4. Calculator Pattern

**Decision**: Separate calculator classes vs. inline calculation

**Rationale**:
- Testability (unit test calculators independently)
- Versioning (track when calculation logic changes)
- Reusability (calculators can be composed)
- Maintainability (clear separation of concerns)

**Trade-offs**:
- More files/classes to manage
- Slight performance overhead (class instantiation)

### 5. Wednesday as Weekly Anchor

**Decision**: Use Wednesday for weekly historical snapshots

**Rationale**:
- Mid-week (avoids weekend effects and Monday/Friday edge cases)
- Consistent day-of-week for historical comparisons
- Arbitrary but reasonable choice

**Alternative**: Make configurable per metric definition

### 6. Use created_at Instead of calculated_at

**Decision**: Eliminate redundant calculated_at timestamp

**Rationale**:
- `created_at` already tracks when record was created
- Reduces storage and index overhead
- Simplifies schema

**Trade-offs**:
- Less explicit naming (must document that created_at = calculated_at)

### 7. Sparse Storage with Change Thresholds

**Decision**: Only record snapshots when values change by meaningful amounts

**Rationale**:
- Most metrics are stable day-to-day (e.g., client demographics, enrollment counts)
- Recording every value every day wastes 90%+ of storage
- Focus on tracking actual changes (the interesting data)
- Thresholds configurable per metric for flexibility

**Benefits**:
- **90% storage reduction** for typical workloads
- Faster queries (less data to scan)
- Focus on meaningful changes (noise reduction)
- Still preserves ability to do dense storage when needed

**Trade-offs**:
- Query logic must handle gaps in time series
- Need to track previous value to detect changes (one extra query per entity)
- Slightly more complex collection logic
- Time series visualizations need to interpolate or show step functions

**Implementation Notes**:
- Always record first snapshot (establish baseline)
- Always record if value changes from NULL to non-NULL or vice versa
- Use OR logic: record if count threshold OR percent threshold met
- If no thresholds specified, default to dense storage (backward compatible)

## Migration Plan

See [implementation-working-documents/metric-tracking-implementation.md](../implementation-working-documents/metric-tracking-implementation.md) for detailed implementation steps.

## Future Enhancements

### Metric Dependencies

Support metrics that depend on other metrics:

```ruby
class DependentCalculator < BaseCalculator
  depends_on :days_homeless_last_three_years, :enrollment_count_last_three_years

  def calculate
    homeless_days = dependencies[:days_homeless_last_three_years]
    enrollments = dependencies[:enrollment_count_last_three_years]

    # Calculate derived metric
    homeless_days.to_f / enrollments if enrollments > 0
  end
end
```

### Metric Metadata

Store additional context with snapshots:

```ruby
add_column :metric_snapshots, :metadata, :jsonb
```

Examples:
- Data quality flags
- Confidence scores
- Contributing factors
- Drill-down links

### Real-Time Metrics

Support on-demand calculation for specific entities:

```ruby
client.calculate_metric('days_homeless_last_three_years', force: true)
```

### Metric Annotations

Allow users to annotate significant changes:

```ruby
create_table :metric_annotations do |t|
  t.references :metric_snapshot
  t.references :user
  t.text :note
  t.timestamps
end
```

### Predictive Metrics

Use historical snapshots to train predictive models:

```ruby
class PredictedHomelessDaysCalculator < BaseCalculator
  def calculate
    historical_values = entity.metric_time_series('days_homeless_last_three_years')
    model = load_trained_model
    model.predict(historical_values)
  end
end
```

## References

- HUD Data Model: `/docs/hud_data_model.md`
- Service History Tables: `app/models/grda_warehouse/service_history_service.rb`
- Warehouse Clients Processed: `app/models/grda_warehouse/warehouse_clients_processed.rb`
- Alert System: `/docs/architecture/alerting.md`
