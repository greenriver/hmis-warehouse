# Metric Tracking System - Implementation Plan

## Overview

This document provides a step-by-step implementation plan for the metric tracking system described in [/docs/architecture/metric-tracking.md](../architecture/metric-tracking.md).

## Key Design Decisions

### Range-Based Sparse Storage
Each snapshot represents a time range where a metric value stays within the configured threshold:
- `initial_observation_date`: When this value range started
- `current_observation_date`: When this value was last calculated/verified
- `initial_value`: Count value when first observed
- `current_value`: Count value as of last verification (updated daily)

**Benefits:**
- Stable clients with minimal change = few snapshots (cheap storage)
- Volatile clients with frequent changes = many snapshots (more expensive but captures change history)
- Can detect spikes by looking at snapshot duration and value change
- Supports linear interpolation for charting

### Calculation Run Tracking
Separate table tracks high-level statistics about each daily collection run:
- Entities evaluated
- Snapshots created vs updated
- Error counts
- Runtime information

### Simple 3-Year Retention
Delete any snapshot where `current_observation_date < 3 years ago`. Since stable clients naturally have few snapshots, no graduated retention policy is needed.

### Table Partitioning
Partition by `initial_observation_date` with quarterly partitions for efficient archival and query performance. Partitions are created upfront for past 3 years and future 10 years to avoid maintenance overhead.

## Implementation Status

**Current State:** Core functionality complete with admin UI, charting, and alert system. System is operational for production use.

**Next Steps:**
- Additional metrics as needed
- HasMetricSnapshots concern for entity-level convenience methods
- Enhanced reporting and analytics

### ✅ Phase 1: Foundation - COMPLETED

Created database schema and base models.

**Completed:**
- ✅ Database tables with range-based storage
- ✅ Base model classes with `GrdaWarehouse::Monitoring` namespace
- ✅ Calculator pattern implemented
- ✅ Calculation run tracking added
- ✅ All migrations applied successfully

**Implementation Notes:**
- All code includes Green River copyright notices
- Using ActiveRecord 7.1 migrations with `--database=warehouse`
- Simplified initial scope: VALID_CATEGORIES = `['days_homeless_in_the_last_three_years']`
- All scopes use ActiveRecord syntax (not Arel or string interpolation)
- Removed interpolation and charting methods (`value_on_date`, `spike?`) to keep code minimal
- Fixed PostgreSQL partitioning unique constraint to include partition key
- Fixed quarter calculation in partition creation (manual calculation instead of strftime)

**Tasks:**

#### 1.1 Create Metric Definitions Migration ✅

**Status:** Completed and applied

**File:** [db/warehouse/migrate/20251020141816_create_metric_definitions.rb](/Users/elliot/Sites/op/hmis-warehouse/db/warehouse/migrate/20251020141816_create_metric_definitions.rb)

Creates the catalog table for metric definitions with fields for name, calculator class, thresholds, and configuration.

#### 1.2 Create Metric Snapshots Migration (with Partitioning) ✅

**Status:** Completed and applied

**File:** [db/warehouse/migrate/20251020142047_create_metric_snapshots.rb](/Users/elliot/Sites/op/hmis-warehouse/db/warehouse/migrate/20251020142047_create_metric_snapshots.rb)

Creates the partitioned table for storing metric snapshots with:
- Range-based sparse storage (`initial_observation_date`, `current_observation_date`)
- Quarterly partitions (3 years past + 10 years future = 52 partitions)
- Unique constraint includes partition key per PostgreSQL requirement
- Quarter calculation uses manual logic: `(quarter_start.month / 3.0).ceil`

#### 1.3 Create Metric Calculation Runs Migration ✅

**Status:** Completed and applied

**File:** [db/warehouse/migrate/20251020142304_create_metric_calculation_runs.rb](/Users/elliot/Sites/op/hmis-warehouse/db/warehouse/migrate/20251020142304_create_metric_calculation_runs.rb)

Creates tracking table for calculation runs with high-level summary statistics (entities evaluated, snapshots created/updated, error counts).

#### 1.4 Create Base Models ✅

**Status:** Completed

Models created with `GrdaWarehouse::Monitoring` namespace:

- **[MetricDefinition](/Users/elliot/Sites/op/hmis-warehouse/app/models/grda_warehouse/monitoring/metric_definition.rb)**: Catalog of available metrics with simplified `VALID_CATEGORIES = ['days_homeless_in_the_last_three_years']`
- **[MetricSnapshot](/Users/elliot/Sites/op/hmis-warehouse/app/models/grda_warehouse/monitoring/metric_snapshot.rb)**: Time-series snapshots using ActiveRecord range syntax, removed charting methods
- **[MetricCalculationRun](/Users/elliot/Sites/op/hmis-warehouse/app/models/grda_warehouse/monitoring/metric_calculation_run.rb)**: Calculation run tracking

#### 1.5 Create Base Calculator ✅

**Status:** Completed

**File:** [app/models/grda_warehouse/monitoring/metric_calculators/base_calculator.rb](/Users/elliot/Sites/op/hmis-warehouse/app/models/grda_warehouse/monitoring/metric_calculators/base_calculator.rb)

Base class for all metric calculators with `calculate` method, versioning support, and lookback window helpers.

---

### ✅ Phase 2: Client Calculators - COMPLETED

Implemented metric calculators for client entities with efficient batch processing.

**Completed:**
- ✅ `HomelessDaysLastThreeYearsCalculator` with batch support
- ✅ `MinHouseholdSizeCalculator` with batch support
- ✅ `MaxHouseholdSizeCalculator` with batch support
- ✅ Efficient single-query batch calculation for 5,000+ entities
- ✅ Returns nil for clients without data (no false positives)
- ✅ Comprehensive test coverage

#### 2.1 HomelessDaysLastThreeYears Calculator ✅

**Status:** Completed

**File:** [app/models/grda_warehouse/monitoring/metric_calculators/homeless_days_last_three_years_calculator.rb](/Users/elliot/Sites/op/hmis-warehouse/app/models/grda_warehouse/monitoring/metric_calculators/homeless_days_last_three_years_calculator.rb)

**Data Source:**
- Table: `GrdaWarehouse::WarehouseClientsProcessed`
- Columns: `client_id`, `days_homeless_last_three_years`

**Implementation Notes:**
- Uses single SQL query for batch calculation (5,000 entities per batch)
- Returns hash of `{ client_id => value }` only for clients with data
- Clients without processed records return nil (no snapshot created)
- Self-configures with `metric_definition_attributes` class method
- Creates new snapshot when count changes by 30 or more

#### 2.2 Household Size Calculators ✅

**Status:** Completed

**Files:**
- [app/models/grda_warehouse/monitoring/metric_calculators/min_household_size_calculator.rb](/Users/elliot/Sites/op/hmis-warehouse/app/models/grda_warehouse/monitoring/metric_calculators/min_household_size_calculator.rb)
- [app/models/grda_warehouse/monitoring/metric_calculators/max_household_size_calculator.rb](/Users/elliot/Sites/op/hmis-warehouse/app/models/grda_warehouse/monitoring/metric_calculators/max_household_size_calculator.rb)

**Data Source:**
- Table: `GrdaWarehouse::Hud::Enrollment`
- Groups by: `[data_source_id, HouseholdID]` to count household members

**Implementation Notes:**
- Both calculators use efficient batch processing
- First query: count members per `[data_source_id, HouseholdID]` combination
- Second query: lookup which households each client belongs to
- Returns min/max household sizes across all client enrollments
- Correctly handles households spanning multiple data sources
- Creates new snapshot on any change (`count_change_threshold: 1`)
- Comprehensive test coverage (16 test cases covering edge cases)

**Design Decision:**
Split into two separate calculators (min and max) rather than one calculator returning both values, since each snapshot can only store a single integer value.

#### 2.3 Additional Calculators (Future)

Additional calculators (e.g., enrollment counts, service counts) will be implemented as needed based on usage patterns.

---

### ✅ Phase 3: Collection System - COMPLETED

Implemented efficient batch collection system with threshold-based snapshot creation.

**Completed:**
- ✅ `MetricSnapshotCollector` service with 5,000 entity batch processing
- ✅ `CollectClientMetricsJob` for background execution
- ✅ Integrated with hourly rake task (runs at 2:00 AM via `COLLECTION_HOUR`)
- ✅ Threshold-based snapshot creation (only create new snapshot on significant change)
- ✅ Range-based sparse storage (updates extend `current_observation_date`)
- ✅ 3-year retention cleanup
- ✅ Bulk insert/update using activerecord-import gem
- ✅ Comprehensive test coverage for thresholds, cleanup, and statistics

**Implementation Notes:**
- Uses `find_or_create_by!` for `MetricCalculationRun` to support reruns
- Explicitly specifies columns in import (excluding id) for partitioned table compatibility
- Errors log but don't halt batch processing; job retry handles failures
- Tracks detailed statistics: entities evaluated, metrics calculated, snapshots created/updated, errors

**Threshold Logic:**
- When only `count_change_threshold` is specified: creates new snapshot if count change exceeds threshold
- When only `percent_change_threshold` is specified: creates new snapshot if percent change exceeds threshold
- When BOTH thresholds are specified: requires BOTH to be met (AND logic) before creating new snapshot
- This prevents false positives where small absolute changes in large values would trigger alerts

---

### Phase 4: Query Interface (Partially Complete)

**Status:** Model-level methods implemented, entity concern pending

**Completed:**
- ✅ `MetricDefinition#threshold_crossing_data(days_back:)` - Chart data with initial observation exclusion
- ✅ `MetricDefinition#entity_label` - Human-readable entity type labels
- ✅ `MetricSnapshot` scopes: `for_entity`, `for_metric`, `active_as_of`, `current`, `stale`

**Pending:**
- `HasMetricSnapshots` concern for easy metric access from entity models
- Convenience methods like `client.metric_value('days_homeless_last_three_years')`
- Time series queries with interpolation
- Change detection helpers

**Usage Pattern (Current):**
```ruby
# Access via MetricDefinition
metric = MetricDefinition.find_by(name: 'days_homeless_last_three_years')
chart_data = metric.threshold_crossing_data(days_back: 90)

# Access via MetricSnapshot scopes
snapshots = MetricSnapshot.for_entity(client).for_metric(metric).current
```

---

### ✅ Phase 5: Metric Definition Maintenance - COMPLETED

Implemented self-configuring metric definitions with automatic maintenance before each collection run.

**Completed:**
- ✅ `MetricDefinition.maintain!` method for self-registration
- ✅ Calculators define their own configuration via `metric_definition_attributes`
- ✅ `available_calculators` array for easy extension
- ✅ Automatic maintenance before each collection run

**Implementation Notes:**
- `MetricDefinition::COLLECTION_HOUR = 2` (runs at 2:00 AM)
- `maintain!` is idempotent - safe to run multiple times
- Uses `find_or_create_by!` to preserve user modifications to existing definitions
- Each calculator class self-describes with name, thresholds, display_name, etc.
- Called at beginning of `MetricSnapshotCollector#run` to ensure definitions are current

**Design Decision: When to Call maintain!**

`maintain!` is called at the **beginning of each collection run** rather than via TaskQueue or at the end of runs:

**Benefits:**
- New calculators become available immediately after deployment (no app restart needed)
- Fast and idempotent (only creates/updates changed definitions)
- Runs before metrics are loaded, ensuring all calculators are registered

**Preserves User Changes:**
- Uses `find_or_create_by!` which only creates new definitions
- Existing definitions are NOT updated, preserving manual modifications
- This allows future admin UI to modify thresholds, display names, etc.

**Future: Admin UI Integration**

When implementing an admin interface for metric definitions:
1. Call `maintain!` on index page load to ensure UI shows all available calculators
2. Allow users to modify thresholds, display names, active status, etc.
3. User changes persist because `maintain!` doesn't update existing records
4. New calculators appear automatically without manual registration

---

### ✅ Phase 6: Admin UI & Charts - COMPLETED

Implemented CRUD interface for metric definitions and threshold crossing charts.

**Completed:**
- ✅ Admin controller with index, show, edit, update actions
- ✅ Routes under `/admin/metric_definitions`
- ✅ Menu integration in Warehouse Admin > Configuration > "Warehouse Metrics"
- ✅ Index view with table grouped by category
- ✅ Show view with metric details
- ✅ Edit view with form for editable fields
- ✅ Threshold crossing chart using Billboard.js
- ✅ Stimulus controller for chart rendering
- ✅ Fake data generator for development/testing

**Implementation Files:**

**Controller:**
- `app/controllers/admin/metric_definitions_controller.rb`
  - Permission: `can_edit_warehouse_alerts`
  - Calls `maintain!` on index to ensure definitions are current
  - Sets `@per_page_js` for chart JavaScript

**Views:**
- `app/views/admin/metric_definitions/index.haml` - Table view grouped by category
- `app/views/admin/metric_definitions/show.haml` - Detail view with chart
- `app/views/admin/metric_definitions/edit.haml` - Edit form

**Model Methods:**
- `MetricDefinition#threshold_crossing_data(days_back:)` - Query for chart data
  - Excludes initial observations (first snapshot per entity/metric)
  - Uses ActiveRecord with Arel for date casting
  - Returns array of `[date_string, count]`
- `MetricDefinition#entity_label` - Human-readable label for chart axis

**JavaScript:**
- `app/javascript/controllers/metric_threshold_chart_controller.js` - Stimulus controller
- `app/javascript/metric_threshold_chart.js` - Entrypoint for esbuild
- Uses Billboard.js bar chart with:
  - Date on X-axis (timeseries, rotated labels)
  - Entity count on Y-axis
  - Flexible entity label (Client, Project, etc.)
  - Tooltip with formatted date and count

**Fake Data Generator:**
- `BaseCalculator.generate_fake_data!(num_clients: 50, days_back: 90)`
- Only runs in development/test environments
- Uses real client IDs from database
- Generates realistic values and threshold crossings
- 70% stable clients (0-2 crossings), 30% volatile (5-10 crossings)
- Bulk insert for efficiency

**Usage in Rails console (development):**
```ruby
GrdaWarehouse::Monitoring::MetricCalculators::BaseCalculator.generate_fake_data!
```

**Editable Fields:**
- Display Name
- Description
- Count Change Threshold
- Percent Change Threshold
- Active status

**Read-Only Fields:**
- Metric Name (from calculator)
- Calculator Class (from calculator)
- Entity Type (from calculator)
- Category (from calculator)

**Chart Features:**
- Shows threshold crossings over last 90 days
- Excludes initial observations
- Flexible entity labeling for future entity types
- Empty state when no data available
- Page-specific JavaScript loading via `@per_page_js`

---

### ✅ Phase 7: Alert System Integration - COMPLETED

Implemented notification system that sends alerts when clients cross metric thresholds.

**Completed:**
- ✅ Two new alert types for client metrics (days homeless and household size)
- ✅ Automatic email notifications to subscribed users
- ✅ Limit of 50 clients per metric in emails with truncation notice
- ✅ Only non-initial observations trigger alerts (excludes baselines)
- ✅ Admin-assigned subscriptions through existing user management UI
- ✅ Alert definitions automatically seeded when viewing metric definitions
- ✅ Comprehensive test coverage for mailer and alert logic

**Implementation Notes:**
- Uses existing `AlertDefinition` and `ContactAlertSubscription` infrastructure
- Admins assign alert subscriptions to users (users cannot self-subscribe)
- Alerts are "system" category notifications
- Each metric calculator defines its `alert_code` for grouping
- Alert job runs after daily metric collection completes
- Visibility checks ensure alerts only show when metrics are active

**Implementation Files:**

**Alert Definitions:**
- Updated `app/models/grda_warehouse/alert_definition.rb`
  - Added `metric_days_homeless_threshold` alert
  - Added `metric_household_size_threshold` alert
  - Fixed `seed_initial_definitions` to exclude `visibility_check` from database assignment
  - Visibility checks ensure alerts only show when corresponding metrics are active

**Job:**
- Created `app/jobs/notify_metric_threshold_crossings_job.rb`
  - Queries threshold crossings grouped by alert code
  - Finds subscribed users for each alert
  - Sends batched notifications per user

**Mailer:**
- Updated `app/mailers/notify_user.rb`
  - Added `metric_threshold_crossed` method
  - Handles different alert codes with appropriate subjects
  - Returns early for inactive users

**Email Templates:**
- Created `app/views/notify_user/metric_threshold_crossed.html.haml` - HTML email with table
- Created `app/views/notify_user/metric_threshold_crossed.text.haml` - Plain text email
- Both show client ID, previous value, current value, and change
- Show truncation message when > 50 clients affected
- Date formatting uses `strftime('%B %d, %Y')` for compatibility

**Model Methods:**
- Updated `app/models/grda_warehouse/monitoring/metric_definition.rb`
  - Added `alert_code` instance method (retrieves from calculator)
  - Added `threshold_crossings_for_alerts(calculation_date, limit: 50)` class method
  - Queries snapshots created on given date
  - Excludes initial observations (requires previous snapshot)
  - Groups by alert code and metric name
  - Returns hash with data, total_count, and truncated flag
  - Updated `maintain!` to exclude `:alert_code` from database assignment

**Calculator Updates:**
- Updated three calculators to include `alert_code` in `metric_definition_attributes`:
  - `homeless_days_last_three_years_calculator.rb` → `'metric_days_homeless_threshold'`
  - `min_household_size_calculator.rb` → `'metric_household_size_threshold'`
  - `max_household_size_calculator.rb` → `'metric_household_size_threshold'`

**Integration:**
- Updated `app/models/grda_warehouse/monitoring/tasks/metric_snapshot_collector.rb`
  - Calls `NotifyMetricThresholdCrossingsJob.perform_later` after collection completes
  - Ensures alerts are sent for same-day threshold crossings

**Admin UI:**
- Updated `app/controllers/admin/metric_definitions_controller.rb`
  - Calls `AlertDefinition.seed_initial_definitions` on index
  - Ensures alert definitions are seeded when admins view metrics
- Alert subscriptions appear automatically in user edit form under "System Notifications"

**Bug Fixes:**
- Fixed `AlertDefinition.seed_initial_definitions` to exclude `visibility_check` (not a column)
- Fixed `MetricSnapshot` table name configuration (explicitly set to `'metric_snapshots'`)
- Fixed `GrdaWarehouseBase.connection` usage (was `ActiveRecord::Base.connection`)
- Fixed metric definition factory to use valid category (`'client_services'`)

**Data Structure:**
```ruby
# threshold_crossings_for_alerts returns:
{
  'metric_days_homeless_threshold' => {
    'Days Homeless (Last 3 Years)' => {
      data: [
        { entity_id: 123, current_value: 150, previous_value: 100 },
        # ... up to 50 clients
      ],
      total_count: 75,    # Total clients affected
      truncated: true     # True if > 50 clients
    }
  }
}
```

**Usage Pattern:**
1. Daily metric collection runs at 2:00 AM
2. After collection completes, `NotifyMetricThresholdCrossingsJob` runs
3. Job queries `MetricDefinition.threshold_crossings_for_alerts(Date.current)`
4. For each alert code with crossings:
   - Finds users subscribed to that alert
   - Sends email with client details to each subscribed user
5. Emails show up to 50 clients with previous/current values
6. If more than 50, shows total count and truncation notice

---

## Test Coverage

Comprehensive test suite covering all components of the metrics system:

### Model Tests

**[spec/models/grda_warehouse/monitoring/metric_definition_spec.rb](/Users/elliot/Sites/op/hmis-warehouse/spec/models/grda_warehouse/monitoring/metric_definition_spec.rb)**
- Validations (name, entity_type, calculator_class, category uniqueness)
- `maintain!` method (creates definitions, idempotent)
- `calculator_for` instantiation
- `calculate_value` delegation

**[spec/models/grda_warehouse/monitoring/metric_snapshot_spec.rb](/Users/elliot/Sites/op/hmis-warehouse/spec/models/grda_warehouse/monitoring/metric_snapshot_spec.rb)**
- Validations (required dates and values)
- Scopes (for_entity, for_metric, active_as_of, current, stale)
- `duration_days` calculation
- `total_change` calculation (positive and negative)

### Calculator Tests

**[spec/models/grda_warehouse/monitoring/metric_calculators/homeless_days_last_three_years_calculator_spec.rb](/Users/elliot/Sites/op/hmis-warehouse/spec/models/grda_warehouse/monitoring/metric_calculators/homeless_days_last_three_years_calculator_spec.rb)**
- Instance `calculate` method (nil for missing data, returns value, handles zero)
- Batch `calculate_batch` method (returns hash, uses single query, handles missing data)
- `metric_definition_attributes` (returns required attributes, includes display name)

**[spec/models/grda_warehouse/monitoring/metric_calculators/min_household_size_calculator_spec.rb](/Users/elliot/Sites/op/hmis-warehouse/spec/models/grda_warehouse/monitoring/metric_calculators/min_household_size_calculator_spec.rb)**
- Returns empty hash for clients without enrollments
- Returns min size for single household
- Returns min size for household with multiple members
- Returns minimum across multiple households
- Correctly handles households spanning multiple data sources
- Processes multiple clients in batch

**[spec/models/grda_warehouse/monitoring/metric_calculators/max_household_size_calculator_spec.rb](/Users/elliot/Sites/op/hmis-warehouse/spec/models/grda_warehouse/monitoring/metric_calculators/max_household_size_calculator_spec.rb)**
- Returns empty hash for clients without enrollments
- Returns max size for single household
- Returns max size for household with multiple members
- Returns maximum across multiple households
- Correctly handles households spanning multiple data sources
- Processes multiple clients in batch

### Collection Tests

**[spec/models/grda_warehouse/monitoring/tasks/metric_snapshot_collector_spec.rb](/Users/elliot/Sites/op/hmis-warehouse/spec/models/grda_warehouse/monitoring/tasks/metric_snapshot_collector_spec.rb)**
- `run_daily_collection` creates calculation run record
- Creates snapshots for entities with data
- Records statistics (entities evaluated, snapshots created)
- Reuses calculation run record on reruns
- Threshold detection (single threshold):
  - Updates existing snapshot when below threshold
  - Creates new snapshot when above threshold
- Threshold detection (both thresholds configured):
  - Updates when count met but percent not met (AND logic)
  - Updates when percent met but count not met (AND logic)
  - Creates new snapshot only when BOTH thresholds met
- Cleanup: deletes snapshots older than 3 years

### Factory Tests

**[spec/factories/grda_warehouse/monitoring.rb](/Users/elliot/Sites/op/hmis-warehouse/spec/factories/grda_warehouse/monitoring.rb)**
- Factory for `MetricDefinition` with sensible defaults
- Factory for `MetricSnapshot` with required associations
- Factory for `MetricCalculationRun` with default statistics

**[spec/factories/grda_warehouse/warehouse_clients_processed.rb](/Users/elliot/Sites/op/hmis-warehouse/spec/factories/grda_warehouse/warehouse_clients_processed.rb)**
- Factory for `WarehouseClientsProcessed` for testing calculators

**[spec/mailers/notify_user_spec.rb](/Users/elliot/Sites/op/hmis-warehouse/spec/mailers/notify_user_spec.rb)** (15 new tests for metric alerts)
- Email subject correctness for different alert types
- Recipient handling (active vs inactive users)
- Calculation date formatting in email body
- Metric name inclusion
- Client ID inclusion
- Value change display (previous → current)
- Client count display
- Truncation handling (showing "first 50 of X clients")
- Multiple metrics in the same alert
- Different alert codes (days homeless vs household size)

### Running Tests

```bash
# Run all monitoring tests
dcr spec bundle exec rspec spec/models/grda_warehouse/monitoring/

# Run specific test files
dcr spec bundle exec rspec spec/models/grda_warehouse/monitoring/metric_definition_spec.rb
dcr spec bundle exec rspec spec/models/grda_warehouse/monitoring/metric_snapshot_spec.rb
dcr spec bundle exec rspec spec/models/grda_warehouse/monitoring/metric_calculators/
dcr spec bundle exec rspec spec/models/grda_warehouse/monitoring/tasks/

# Run mailer tests (includes metric threshold alerts)
dcr spec bundle exec rspec spec/mailers/notify_user_spec.rb
```

---

## System Ready for Production

The metric tracking system is now fully implemented and tested:

✅ **Database schema** - Partitioned tables with range-based sparse storage
✅ **Calculator pattern** - Self-configuring with batch support
✅ **Collection system** - Efficient batch processing with thresholds
✅ **Initialization** - TaskQueue integration for metric definitions
✅ **Scheduling** - Hourly rake task runs at 2:00 AM
✅ **Test coverage** - Comprehensive specs for all components

### First Production Run

The system has been successfully deployed and run with production data:
- Processed all destination clients with processed service history records
- Created initial metric snapshots
- Verified threshold-based snapshot creation works correctly
- Confirmed 3-year retention cleanup runs properly

### Recent Updates (2025-01-28)

**Alert System Integration (Phase 7):**
- Implemented complete notification system for metric threshold crossings
- Two alert types: days homeless and household size thresholds
- Email notifications to subscribed users with client details
- Automatic alert definition seeding when viewing admin UI
- Comprehensive test coverage (15 new mailer tests)
- Handles large result sets (limits to 50 clients per email with truncation notice)

**Bug Fixes:**
- Fixed `AlertDefinition.seed_initial_definitions` to exclude non-column attributes
- Fixed `MetricSnapshot` table name configuration for partitioned table
- Fixed database connection usage for warehouse database
- Fixed metric definition factory for test compatibility

### Previous Updates (2025-01-20)

**Threshold Logic Enhancement:**
- Fixed threshold detection to use AND logic when both count and percent thresholds are configured
- Added comprehensive tests verifying AND behavior prevents false positives
- Updated collector to properly handle all three threshold scenarios

**Household Size Calculators:**
- Implemented `MinHouseholdSizeCalculator` and `MaxHouseholdSizeCalculator`
- Efficient batch processing with two-query approach:
  1. Count members per `[data_source_id, HouseholdID]`
  2. Lookup household memberships per client
- Correctly handles cross-data-source household isolation
- Creates new snapshot on any change (threshold = 1)
- Added 16 comprehensive test cases covering all edge cases

**Factories:**
- Created factories for all monitoring models
- Separated `WarehouseClientsProcessed` factory into its own file
- All factories include frozen string literal comments

**Design Decisions Documented:**
- Entity type remains `GrdaWarehouse::Hud::Client` (not `WarehouseClientsProcessed`)
- Rationale: Users conceptualize metrics in terms of clients, not processed records
- Collection logic already filters to clients with processed records

### Next Steps

1. **Monitor daily collections**: Check `metric_calculation_runs` table for statistics
2. **Monitor alert notifications**: Check that subscribed users receive emails after collection runs
3. **Add new calculators**: Follow the pattern in household size calculators
4. **Phase 4: Query Interface**: Implement `HasMetricSnapshots` concern when ready to expose metrics
5. **Subscribe users to alerts**: Admins can assign alert subscriptions via user edit form

---

## Original Implementation Plan

The sections below contain the original detailed implementation plan. Sections marked as completed above have been implemented with the noted modifications.

---

### Original Phase 3 Specification: Collection System

#### 3.1 Create Collector Service

**File:** `app/models/grda_warehouse/tasks/metric_snapshot_collector.rb`

```ruby
module GrdaWarehouse
  module Tasks
    class MetricSnapshotCollector
      BATCH_SIZE = 5_000

      def self.run_daily_collection(
        entity_type:,
        calculation_date: Date.current,
        entity_ids: nil,
        metric_names: nil
      )
        new(
          entity_type: entity_type,
          calculation_date: calculation_date,
          entity_ids: entity_ids,
          metric_names: metric_names
        ).run
      end

      def initialize(entity_type:, calculation_date:, entity_ids: nil, metric_names: nil)
        @entity_type = entity_type
        @calculation_date = calculation_date
        @entity_ids = entity_ids
        @metric_names = metric_names
        @run_stats = {
          entities_evaluated: 0,
          metrics_calculated: 0,
          snapshots_created: 0,
          snapshots_updated: 0,
          errors: 0
        }
      end

      def run
        run_record = create_run_record

        begin
          metrics = load_metrics
          entities = load_entities

          Rails.logger.info "Collecting #{metrics.count} metrics for #{entities.count} #{@entity_type} records"

          entities.in_groups_of(BATCH_SIZE, false) do |entity_batch|
            collect_batch(entity_batch, metrics)
          end

          cleanup_old_snapshots
          complete_run_record(run_record, 'completed')

        rescue => e
          Rails.logger.error "Metric collection failed: #{e.message}\n#{e.backtrace.join("\n")}"
          complete_run_record(run_record, 'failed', e.message)
          raise
        end
      end

      private

      def create_run_record
        GrdaWarehouse::MetricCalculationRun.create!(
          entity_type: @entity_type,
          calculation_date: @calculation_date,
          started_at: Time.current,
          status: 'running'
        )
      end

      def complete_run_record(run_record, status, error_message = nil)
        run_record.update!(
          completed_at: Time.current,
          status: status,
          error_message: error_message,
          entities_evaluated_count: @run_stats[:entities_evaluated],
          metrics_calculated_count: @run_stats[:metrics_calculated],
          snapshots_created_count: @run_stats[:snapshots_created],
          snapshots_updated_count: @run_stats[:snapshots_updated],
          calculation_errors_count: @run_stats[:errors]
        )
      end

      def load_metrics
        scope = GrdaWarehouse::MetricDefinition
          .active
          .for_entity_type(@entity_type)

        scope = scope.where(name: @metric_names) if @metric_names.present?

        scope.to_a
      end

      def load_entities
        entity_class = @entity_type.constantize

        if @entity_ids.present?
          entity_class.where(id: @entity_ids)
        else
          get_active_entities(entity_class)
        end
      end

      def get_active_entities(entity_class)
        case @entity_type
        when 'GrdaWarehouse::Hud::Client'
          lookback = @calculation_date - 3.years
          entity_class
            .destination
            .joins(:service_history_services)
            .where('service_history_services.date >= ?', lookback)
            .where('service_history_services.date <= ?', @calculation_date)
            .distinct
        when 'GrdaWarehouse::Hud::Project'
          entity_class.viewable
        when 'GrdaWarehouse::DataSource'
          entity_class.all
        else
          entity_class.all
        end
      end

      def collect_batch(entities, metrics)
        @run_stats[:entities_evaluated] += entities.count

        # Load all current snapshots for this batch to minimize queries
        current_snapshots = load_current_snapshots_for_batch(entities, metrics)

        snapshots_to_create = []
        snapshots_to_update = []

        entities.each do |entity|
          metrics.each do |metric|
            @run_stats[:metrics_calculated] += 1

            begin
              process_metric_for_entity(
                entity,
                metric,
                current_snapshots,
                snapshots_to_create,
                snapshots_to_update
              )
            rescue => e
              Rails.logger.error "Failed to calculate #{metric.name} for #{entity.class.name}##{entity.id}: #{e.message}"
              @run_stats[:errors] += 1
            end
          end
        end

        # Bulk create and update
        import_snapshots(snapshots_to_create)
        update_snapshots(snapshots_to_update)
      end

      def load_current_snapshots_for_batch(entities, metrics)
        entity_ids = entities.map(&:id)
        metric_ids = metrics.map(&:id)

        # Find the most recent snapshot for each entity/metric combination
        GrdaWarehouse::MetricSnapshot
          .where(entity_type: @entity_type, entity_id: entity_ids)
          .where(metric_definition_id: metric_ids)
          .where('current_observation_date >= ?', @calculation_date - 1.day)
          .order(:entity_id, :metric_definition_id, current_observation_date: :desc)
          .select('DISTINCT ON (entity_id, metric_definition_id) *')
          .index_by { |s| [s.entity_id, s.metric_definition_id] }
      end

      def process_metric_for_entity(entity, metric, current_snapshots, snapshots_to_create, snapshots_to_update)
        calculator = metric.calculator_for(entity, @calculation_date)
        calculated_value = calculator.calculate

        current_snapshot = current_snapshots[[entity.id, metric.id]]

        if should_create_new_snapshot?(metric, current_snapshot, calculated_value)
          # Significant change detected - create new snapshot
          snapshot = build_new_snapshot(entity, metric, calculated_value, calculator.version)
          snapshots_to_create << snapshot
          @run_stats[:snapshots_created] += 1
        elsif current_snapshot
          # Value within threshold - update current_value and extend current_observation_date
          current_snapshot.current_value = calculated_value
          current_snapshot.current_observation_date = @calculation_date
          snapshots_to_update << current_snapshot
          @run_stats[:snapshots_updated] += 1
        else
          # First time calculating this metric for this entity
          snapshot = build_new_snapshot(entity, metric, calculated_value, calculator.version)
          snapshots_to_create << snapshot
          @run_stats[:snapshots_created] += 1
        end
      end

      def should_create_new_snapshot?(metric, current_snapshot, calculated_value)
        # No current snapshot = first time, create new
        return true unless current_snapshot

        # Compare calculated value to initial_value (baseline)
        # This detects threshold crossings from the baseline
        baseline_value = current_snapshot.initial_value

        # Handle nil/null values
        return true if calculated_value.nil? != baseline_value.nil?
        return false if calculated_value.nil? && baseline_value.nil?

        # If no thresholds specified, create new snapshot on any change
        count_threshold = metric.count_change_threshold
        percent_threshold = metric.percent_change_threshold
        return calculated_value != baseline_value if count_threshold.nil? && percent_threshold.nil?

        # Calculate change from baseline
        change = (calculated_value - baseline_value).abs

        # Check count threshold
        return true if count_threshold && change >= count_threshold

        # Check percent threshold
        if percent_threshold && baseline_value != 0
          percent_change = (change.to_f / baseline_value.abs * 100)
          return true if percent_change >= percent_threshold
        end

        # No threshold crossed, update existing snapshot
        false
      end

      def build_new_snapshot(entity, metric, value, calculation_version)
        GrdaWarehouse::MetricSnapshot.new(
          entity: entity,
          metric_definition: metric,
          initial_observation_date: @calculation_date,
          current_observation_date: @calculation_date,
          initial_value: value,
          current_value: value,
          calculation_version: calculation_version
        )
      end

      def import_snapshots(snapshots)
        return if snapshots.empty?

        GrdaWarehouse::MetricSnapshot.import(
          snapshots,
          on_duplicate_key_update: {
            conflict_target: [
              :entity_type,
              :entity_id,
              :metric_definition_id,
              :current_observation_date
            ],
            columns: [
              :initial_value,
              :current_value,
              :calculation_version,
              :updated_at
            ]
          }
        )
      end

      def update_snapshots(snapshots)
        return if snapshots.empty?

        # Bulk update current_value and current_observation_date
        GrdaWarehouse::MetricSnapshot.import(
          snapshots,
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: [:current_value, :current_observation_date, :updated_at]
          }
        )
      end

      def cleanup_old_snapshots
        cutoff_date = @calculation_date - 3.years

        deleted_count = GrdaWarehouse::MetricSnapshot
          .where('current_observation_date < ?', cutoff_date)
          .delete_all

        Rails.logger.info "Cleaned up #{deleted_count} snapshots with current_observation_date before #{cutoff_date}"
      end
    end
  end
end
```

#### 3.2 Create Background Jobs

**File:** `app/jobs/collect_client_metrics_job.rb`

```ruby
class CollectClientMetricsJob < ApplicationJob
  queue_as :default

  def perform(calculation_date = Date.current)
    GrdaWarehouse::Tasks::MetricSnapshotCollector.run_daily_collection(
      entity_type: 'GrdaWarehouse::Hud::Client',
      calculation_date: calculation_date
    )
  end
end
```

**File:** `app/jobs/collect_project_metrics_job.rb`

```ruby
class CollectProjectMetricsJob < ApplicationJob
  queue_as :default

  def perform(calculation_date = Date.current)
    GrdaWarehouse::Tasks::MetricSnapshotCollector.run_daily_collection(
      entity_type: 'GrdaWarehouse::Hud::Project',
      calculation_date: calculation_date
    )
  end
end
```

**File:** `app/jobs/collect_data_source_metrics_job.rb`

```ruby
class CollectDataSourceMetricsJob < ApplicationJob
  queue_as :default

  def perform(calculation_date = Date.current)
    GrdaWarehouse::Tasks::MetricSnapshotCollector.run_daily_collection(
      entity_type: 'GrdaWarehouse::DataSource',
      calculation_date: calculation_date
    )
  end
end
```

#### 3.3 Schedule Daily Collection

**File:** `config/schedule.rb` (if using whenever gem)

```ruby
every 1.day, at: '2:00 am' do
  runner "CollectClientMetricsJob.perform_later"
end
```

Or configure via cron, Sidekiq scheduler, or your scheduling system.

**Test manually:**
```bash
dcr shell bundle exec rails runner "CollectClientMetricsJob.perform_now"
```

---

### Original Phase 4 Specification: Query Interface

Add concern for easy metric access.

#### 4.1 Create HasMetricSnapshots Concern

**File:** `app/models/concerns/has_metric_snapshots.rb`

```ruby
module HasMetricSnapshots
  extend ActiveSupport::Concern

  included do
    has_many :metric_snapshots,
      as: :entity,
      class_name: 'GrdaWarehouse::MetricSnapshot',
      dependent: :destroy
  end

  # Get value on a specific date
  def metric_value(metric_name, as_of_date: Date.current)
    metric_def = GrdaWarehouse::MetricDefinition.find_by(
      name: metric_name,
      entity_type: self.class.name
    )

    return nil unless metric_def

    snapshot = metric_snapshots
      .where(metric_definition: metric_def)
      .active_as_of(as_of_date)
      .first

    return nil unless snapshot

    snapshot.value_on_date(as_of_date)
  end

  # Detect significant change in metric
  def metric_change(metric_name, days_back: 1)
    current_value = metric_value(metric_name, as_of_date: Date.current)
    past_value = metric_value(metric_name, as_of_date: days_back.days.ago.to_date)

    return nil if current_value.nil? || past_value.nil?

    current_value - past_value
  end

  # Get all current metrics as hash
  def all_metrics(as_of_date: Date.current)
    metric_snapshots
      .joins(:metric_definition)
      .active_as_of(as_of_date)
      .each_with_object({}) do |snapshot, hash|
        hash[snapshot.metric_definition.name] = snapshot.value_on_date(as_of_date)
      end
  end
end
```

#### 4.2 Include Concern in Client Model

**File:** `app/models/grda_warehouse/hud/client.rb`

```ruby
module GrdaWarehouse::Hud
  class Client < GrdaWarehouseBase
    include HasMetricSnapshots

    # ... existing code ...
  end
end
```

---

### Original Phase 5 Specification: Seed Initial Metrics

Create metric definitions for client metrics.

#### 5.1 Create Seed File

**File:** `db/seeds/metric_definitions.rb`

```ruby
module Seeds
  class MetricDefinitions
    def self.seed!
      create_client_metrics
    end

    private

    def self.create_client_metrics
      [
        {
          name: 'days_homeless_last_three_years',
          display_name: 'Days Homeless (Last 3 Years)',
          description: 'Total days with homeless services in the last 3 years (includes ES, SO, SH, TH)',
          entity_type: 'GrdaWarehouse::Hud::Client',
          calculator_class: 'GrdaWarehouse::MetricCalculators::Client::HomelessDaysCalculator',
          category: 'housing',
          calculation_window_days: 1095,
          count_change_threshold: 5,
          percent_change_threshold: nil,
          active: true
        },
        {
          name: 'source_client_count',
          display_name: 'Source Client Count',
          description: 'Number of source client records merged into this destination client',
          entity_type: 'GrdaWarehouse::Hud::Client',
          calculator_class: 'GrdaWarehouse::MetricCalculators::Client::SourceClientCountCalculator',
          category: 'data_quality',
          calculation_window_days: nil,
          count_change_threshold: 1,
          percent_change_threshold: nil,
          active: true
        },
        {
          name: 'max_household_size',
          display_name: 'Maximum Household Size',
          description: 'Largest household size client has been part of (last 3 years)',
          entity_type: 'GrdaWarehouse::Hud::Client',
          calculator_class: 'GrdaWarehouse::MetricCalculators::Client::MaxHouseholdSizeCalculator',
          category: 'demographics',
          calculation_window_days: 1095,
          count_change_threshold: 1,
          percent_change_threshold: nil,
          active: true
        },
        {
          name: 'min_household_size',
          display_name: 'Minimum Household Size',
          description: 'Smallest household size client has been part of (last 3 years)',
          entity_type: 'GrdaWarehouse::Hud::Client',
          calculator_class: 'GrdaWarehouse::MetricCalculators::Client::MinHouseholdSizeCalculator',
          category: 'demographics',
          calculation_window_days: 1095,
          count_change_threshold: 1,
          percent_change_threshold: nil,
          active: true
        },
        {
          name: 'enrollment_count_last_three_years',
          display_name: 'Enrollment Count (Last 3 Years)',
          description: 'Number of enrollments in the last 3 years',
          entity_type: 'GrdaWarehouse::Hud::Client',
          calculator_class: 'GrdaWarehouse::MetricCalculators::Client::EnrollmentCountCalculator',
          category: 'services',
          calculation_window_days: 1095,
          count_change_threshold: 1,
          percent_change_threshold: nil,
          active: true
        },
        {
          name: 'unique_projects_last_three_years',
          display_name: 'Unique Projects (Last 3 Years)',
          description: 'Number of distinct projects served in during the last 3 years',
          entity_type: 'GrdaWarehouse::Hud::Client',
          calculator_class: 'GrdaWarehouse::MetricCalculators::Client::UniqueProjectsCalculator',
          category: 'services',
          calculation_window_days: 1095,
          count_change_threshold: 1,
          percent_change_threshold: nil,
          active: true
        },
        {
          name: 'current_living_situation_count',
          display_name: 'Current Living Situation Records',
          description: 'Number of current living situation assessments recorded (last 3 years)',
          entity_type: 'GrdaWarehouse::Hud::Client',
          calculator_class: 'GrdaWarehouse::MetricCalculators::Client::CurrentLivingSituationCountCalculator',
          category: 'assessments',
          calculation_window_days: 1095,
          count_change_threshold: 1,
          percent_change_threshold: nil,
          active: true
        },
        {
          name: 'service_count',
          display_name: 'Service Count',
          description: 'Total number of service records (last 3 years)',
          entity_type: 'GrdaWarehouse::Hud::Client',
          calculator_class: 'GrdaWarehouse::MetricCalculators::Client::ServiceCountCalculator',
          category: 'services',
          calculation_window_days: 1095,
          count_change_threshold: 10,
          percent_change_threshold: nil,
          active: true
        }
      ].each do |attrs|
        GrdaWarehouse::MetricDefinition.find_or_create_by!(
          name: attrs[:name],
          entity_type: attrs[:entity_type]
        ) do |metric|
          metric.assign_attributes(attrs)
        end
      end

      Rails.logger.info "Seeded #{GrdaWarehouse::MetricDefinition.for_entity_type('GrdaWarehouse::Hud::Client').count} client metrics"
    end
  end
end
```

#### 5.2 Run Seed

**Option 1: Migration**

```ruby
# db/migrate/YYYYMMDDHHMMSS_seed_initial_client_metrics.rb
class SeedInitialClientMetrics < ActiveRecord::Migration[7.0]
  def up
    require_relative '../seeds/metric_definitions'
    Seeds::MetricDefinitions.seed!
  end

  def down
    GrdaWarehouse::MetricDefinition
      .where(entity_type: 'GrdaWarehouse::Hud::Client')
      .destroy_all
  end
end
```

**Option 2: Rails runner**

```bash
dcr shell bundle exec rails runner "require './db/seeds/metric_definitions'; Seeds::MetricDefinitions.seed!"
```

---

### Original Phase 6 Specification: Initial Data Collection

Run first collection and verify data.

#### 6.1 Test Collection on Sample

Test with a small sample first:

```ruby
# Get 100 sample client IDs
sample_ids = GrdaWarehouse::Hud::Client.destination.limit(100).pluck(:id)

# Run collection for sample
GrdaWarehouse::Tasks::MetricSnapshotCollector.run_daily_collection(
  entity_type: 'GrdaWarehouse::Hud::Client',
  calculation_date: Date.current,
  entity_ids: sample_ids
)

# Verify snapshots created
puts "Created #{GrdaWarehouse::MetricSnapshot.count} snapshots"

# Check sample values
client = GrdaWarehouse::Hud::Client.find(sample_ids.first)
puts "Homeless days: #{client.metric_value('days_homeless_last_three_years')}"
puts "Enrollments: #{client.metric_value('enrollment_count_last_three_years')}"
```

#### 6.2 Run Full Collection

```bash
# Via job (recommended)
dcr shell bundle exec rails runner "CollectClientMetricsJob.perform_now"
```

**Monitor:**
- Check logs for progress
- Watch `metric_snapshots` table row count
- Verify no errors in calculation
- Review `metric_calculation_runs` table for statistics

#### 6.3 Verify Data Quality

```sql
-- Count snapshots per metric
SELECT
  md.name,
  md.display_name,
  COUNT(*) as snapshot_count
FROM metric_snapshots ms
JOIN metric_definitions md ON md.id = ms.metric_definition_id
WHERE ms.current_observation_date = CURRENT_DATE
GROUP BY md.id, md.name, md.display_name
ORDER BY md.name;

-- Check value distribution
SELECT
  md.name,
  MIN(ms.current_value) as min_value,
  AVG(ms.current_value) as avg_value,
  MAX(ms.current_value) as max_value
FROM metric_snapshots ms
JOIN metric_definitions md ON md.id = ms.metric_definition_id
WHERE ms.current_observation_date = CURRENT_DATE
GROUP BY md.name
ORDER BY md.name;

-- Check calculation run statistics
SELECT
  calculation_date,
  status,
  entities_evaluated_count,
  snapshots_created_count,
  snapshots_updated_count,
  calculation_errors_count,
  completed_at - started_at as duration
FROM metric_calculation_runs
ORDER BY calculation_date DESC
LIMIT 10;

-- Verify partitions were created
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE tablename LIKE 'metric_snapshots_%'
ORDER BY tablename;
```

---

### Original Phase 7 Specification: Testing & Validation

#### 7.1 Test Scenarios for Range-Based Storage

Document key test scenarios to ensure sparse storage works correctly:

**Test Case 1: Value Stays Within Threshold**
- Days 1-60: value fluctuates 100-104 (threshold = 5)
- Expected: One snapshot with initial=100, current=104, spanning 60 days
- Verify: No false positive alerts

**Test Case 2: Temporary Spike**
- Days 1-30: value = 100
- Day 31: value = 200 (spike)
- Days 32-60: value = 100 (recovery)
- Expected: Three snapshots
  1. initial=100, current=104, days 1-30
  2. initial=200, current=200, day 31 (duration=0, identified as spike)
  3. initial=100, current=102, days 32-60

**Test Case 3: Gradual Drift**
- Days 1-5: 100, 101, 102, 103, 104
- Day 6: 106 (crosses threshold from initial 100)
- Expected: Two snapshots
  1. initial=100, current=104, days 1-5
  2. initial=106, current=106, day 6

**Test Case 4: Client Becomes Inactive**
- Days 1-30: active, value stable
- Days 31-90: not in active query
- Day 91: active again, different value
- Expected: `current_observation_date` stops at day 30, can detect staleness

#### 7.2 Unit Tests

Test calculators and models:

```bash
dcr spec bundle exec rspec spec/models/grda_warehouse/metric_calculators/
dcr spec bundle exec rspec spec/models/grda_warehouse/metric_definition_spec.rb
dcr spec bundle exec rspec spec/models/grda_warehouse/metric_snapshot_spec.rb
dcr spec bundle exec rspec spec/models/grda_warehouse/metric_calculation_run_spec.rb
dcr spec bundle exec rspec spec/models/concerns/has_metric_snapshots_spec.rb
```

#### 7.3 Integration Tests

Test full collection flow:

```ruby
# spec/jobs/collect_client_metrics_job_spec.rb
require 'rails_helper'

RSpec.describe CollectClientMetricsJob do
  let!(:client) { create(:grda_warehouse_hud_client) }
  let!(:metric_definition) do
    create(
      :metric_definition,
      name: 'days_homeless_last_three_years',
      entity_type: 'GrdaWarehouse::Hud::Client',
      calculator_class: 'GrdaWarehouse::MetricCalculators::Client::HomelessDaysCalculator'
    )
  end

  it 'creates snapshots for active clients' do
    expect {
      described_class.perform_now
    }.to change { GrdaWarehouse::MetricSnapshot.count }
  end

  it 'creates calculation run record' do
    expect {
      described_class.perform_now
    }.to change { GrdaWarehouse::MetricCalculationRun.count }.by(1)
  end
end
```

---

## Rollout Checklist

### Pre-Deployment

- [ ] All migrations created and tested in development
- [ ] All models created with tests passing
- [ ] Calculator classes implemented and tested
- [ ] Collection system tested with sample data
- [ ] Retention logic verified (3-year cutoff)
- [ ] Query methods tested
- [ ] Documentation complete

### Initial Deployment

- [ ] Deploy migrations (non-breaking)
- [ ] Verify partitions created correctly
- [ ] Deploy model code
- [ ] Seed metric definitions
- [ ] Verify no errors in application

### Data Collection Start

- [ ] Run initial collection manually on sample
- [ ] Verify data quality
- [ ] Monitor performance metrics
- [ ] Run full collection
- [ ] Enable scheduled collection
- [ ] Monitor for 1 week

### Go Live

- [ ] Enable query methods in application code
- [ ] Monitor usage and performance
- [ ] Track calculation run statistics

---

## Troubleshooting

### Common Issues

**Issue: Collection takes too long**
- Reduce `BATCH_SIZE`
- Add indexes to frequently queried columns
- Optimize calculator queries
- Consider processing specific cohorts only

**Issue: High memory usage**
- Verify batch size is reasonable
- Check for N+1 queries in calculators
- Use `.find_each` instead of `.each` for large sets

**Issue: Incorrect metric values**
- Verify calculator logic with known test cases
- Check date range handling (inclusive vs exclusive)
- Verify data sources (source vs destination clients)

**Issue: Missing snapshots**
- Check if metrics are marked `active: true`
- Verify entity is included in active entity query
- Check logs for calculation errors
- Review `metric_calculation_runs` for error counts

**Issue: Too many snapshots (storage growing too fast)**
- Review threshold settings - may be too sensitive
- Check for metrics with no thresholds (creating snapshots on every change)
- Verify cleanup is running (check `current_observation_date < 3 years ago`)

**Issue: Partitioning errors on inserts**
- Check that partition exists for the `initial_observation_date` being inserted
- If inserting data beyond 10 years in the future, create additional partitions manually
- Query existing partitions: `SELECT tablename FROM pg_tables WHERE tablename LIKE 'metric_snapshots_%' ORDER BY tablename`

---

## Maintenance

### Regular Tasks

- **Monitor collection job**: Ensure runs daily without errors via `metric_calculation_runs`
- **Check disk space**: Monitor `metric_snapshots` table size
- **Verify data quality**: Spot-check metric values
- **Review performance**: Monitor query times and calculation duration

### Periodic Tasks

- **Monitor partition availability**: Around year 2032, need to create additional quarterly partitions
- **Add new metrics**: Follow extensibility pattern
- **Update calculators**: Version and migrate when logic changes
- **Drop very old partitions**: If retaining data beyond 3 years, manually drop ancient partitions to free space

---

## Storage Estimates

With range-based sparse storage:

- **Stable client** (3 years, 2-3 changes): 2-3 snapshots per metric
- **Moderately stable** (3 years, monthly changes): ~36 snapshots per metric
- **Volatile client** (3 years, weekly changes): ~150 snapshots per metric

**Example: 200k clients × 8 metrics over 3 years**
- Assuming 70% stable, 25% moderate, 5% volatile
- Estimated total: ~30-50 million rows
- Storage: ~3-5 GB (very manageable)

---

## Next Steps

### Future Enhancements

1. **HasMetricSnapshots Concern** - Add convenience methods to entity models
   ```ruby
   client.metric_value('days_homeless_last_three_years')
   client.metric_time_series('days_homeless_last_three_years', start_date:, end_date:)
   ```

2. **Additional Metrics** - Implement remaining planned client metrics:
   - `source_client_count`
   - `enrollment_count_last_three_years`
   - `unique_projects_last_three_years`
   - `current_living_situation_count`
   - `service_count`

3. **Additional Entity Types** - Extend to Projects, Data Sources, Organizations

4. **Advanced Charting** - Time series with interpolation for detailed trend analysis

5. **Metric Metadata** - Store additional context (JSONB column):
   - Data quality flags
   - Confidence scores
   - Contributing factors for changes

### Development/Testing Tools

**Generate Fake Data:**
```ruby
# In Rails console (development only)
GrdaWarehouse::Monitoring::MetricCalculators::BaseCalculator.generate_fake_data!(
  num_clients: 50,
  days_back: 90
)
```

**Manually Run Collection:**
```ruby
# Run for specific date
CollectClientMetricsJob.perform_now(calculation_date: Date.current)

# Or via collector directly
GrdaWarehouse::Monitoring::Tasks::MetricSnapshotCollector.run_daily_collection(
  entity_type: 'GrdaWarehouse::Hud::Client',
  calculation_date: Date.current
)
```

**Access Charts:**
- Navigate to: Admin > Warehouse Admin > Configuration > Warehouse Metrics
- Click metric name to view details and threshold crossing chart
