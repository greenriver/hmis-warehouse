# Metric Tracking System - Implementation Plan

## Overview

This document provides a step-by-step implementation plan for the metric tracking system described in [/docs/architecture/metric-tracking.md](../architecture/metric-tracking.md).

## Implementation Phases

### Phase 1: Foundation (Sprint 1)

Create database schema and base models.

**Goals:**
- Set up database tables
- Create base model classes
- Implement calculator pattern
- Deploy without affecting existing functionality

**Tasks:**

#### 1.1 Create Metric Definitions Migration

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_metric_definitions.rb

class CreateMetricDefinitions < ActiveRecord::Migration[7.0]
  def change
    create_table :metric_definitions, comment: 'Catalog of available metrics and calculation rules' do |t|
      t.string :name, null: false, limit: 100, comment: 'Unique identifier (e.g., days_homeless_last_three_years)'
      t.string :display_name, null: false, comment: 'Human-readable name for UI'
      t.text :description, comment: 'Detailed description of what this metric measures'
      t.string :entity_type, null: false, comment: 'Entity class this metric applies to (e.g., GrdaWarehouse::Hud::Client)'
      t.string :calculator_class, null: false, comment: 'Ruby class that implements calculation logic'
      t.string :value_type, null: false, default: 'integer', comment: 'Data type: integer, float, string, boolean, json'
      t.string :category, limit: 50, comment: 'Grouping category for UI organization'
      t.integer :calculation_window_days, comment: 'Lookback period in days (e.g., 1095 for 3 years)'
      t.integer :count_change_threshold, comment: 'Only record snapshot if value changes by at least this amount (sparse storage)'
      t.decimal :percent_change_threshold, precision: 5, scale: 2, comment: 'Only record snapshot if value changes by at least this percentage (sparse storage)'
      t.boolean :active, default: true, null: false, comment: 'Whether this metric is actively being calculated'

      t.timestamps

      t.index [:entity_type, :name], unique: true, name: 'index_metric_defs_on_entity_and_name'
      t.index :active
      t.index :category
    end
  end
end
```

**Run:** `dcr shell bundle exec rails db:migrate`

#### 1.2 Create Metric Snapshots Migration

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_metric_snapshots.rb

class CreateMetricSnapshots < ActiveRecord::Migration[7.0]
  def change
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
  end
end
```

**Run:** `dcr shell bundle exec rails db:migrate`

#### 1.3 Create Base Models

**File:** `app/models/grda_warehouse/metric_definition.rb`

```ruby
module GrdaWarehouse
  class MetricDefinition < GrdaWarehouseBase
    VALID_CATEGORIES = %w[
      housing
      services
      demographics
      assessments
      data_quality
      utilization
      import
    ].freeze

    VALID_VALUE_TYPES = %w[
      integer
      float
      string
      boolean
      json
    ].freeze

    has_many :metric_snapshots, dependent: :destroy

    validates :name, presence: true, uniqueness: { scope: :entity_type }
    validates :entity_type, presence: true
    validates :calculator_class, presence: true
    validates :value_type, inclusion: { in: VALID_VALUE_TYPES }
    validates :category, inclusion: { in: VALID_CATEGORIES }, allow_nil: true

    scope :active, -> { where(active: true) }
    scope :for_entity_type, ->(type) { where(entity_type: type) }
    scope :by_category, ->(category) { where(category: category) }

    # Instantiate calculator for given entity
    def calculator_for(entity, snapshot_date)
      calculator_class.constantize.new(entity, snapshot_date)
    end

    # Calculate and return value
    def calculate_value(entity, snapshot_date)
      calculator_for(entity, snapshot_date).calculate
    end
  end
end
```

**File:** `app/models/grda_warehouse/metric_snapshot.rb`

```ruby
module GrdaWarehouse
  class MetricSnapshot < GrdaWarehouseBase
    belongs_to :entity, polymorphic: true
    belongs_to :metric_definition

    validates :snapshot_date, uniqueness: {
      scope: [:entity_type, :entity_id, :metric_definition_id]
    }

    # Polymorphic value accessor
    def value
      case metric_definition.value_type
      when 'integer' then value_integer
      when 'float' then value_float
      when 'string' then value_string
      when 'boolean' then value_boolean
      when 'json' then value_json
      end
    end

    def value=(val)
      case metric_definition.value_type
      when 'integer' then self.value_integer = val
      when 'float' then self.value_float = val
      when 'string' then self.value_string = val
      when 'boolean' then self.value_boolean = val
      when 'json' then self.value_json = val
      end
    end

    # Scopes
    scope :for_date_range, ->(start_date, end_date) {
      where(snapshot_date: start_date..end_date)
    }

    scope :for_entity, ->(entity) {
      where(entity_type: entity.class.name, entity_id: entity.id)
    }

    scope :for_metric, ->(metric_definition) {
      where(metric_definition_id: metric_definition.id)
    }

    scope :latest_for_entities, ->(entity_type, entity_ids) {
      where(entity_type: entity_type, entity_id: entity_ids)
        .select('DISTINCT ON (entity_id, metric_definition_id) *')
        .order(:entity_id, :metric_definition_id, snapshot_date: :desc)
    }

    scope :weekly_anchors, ->(anchor_day = 3) {
      where('EXTRACT(DOW FROM snapshot_date) = ?', anchor_day)
    }
  end
end
```

#### 1.4 Create Base Calculator

**File:** `app/models/grda_warehouse/metric_calculators/base_calculator.rb`

```ruby
module GrdaWarehouse
  module MetricCalculators
    class BaseCalculator
      attr_reader :entity, :snapshot_date

      def initialize(entity, snapshot_date)
        @entity = entity
        @snapshot_date = snapshot_date
      end

      # Subclasses must implement
      def calculate
        raise NotImplementedError, "#{self.class} must implement #calculate"
      end

      # Return calculation version
      def version
        '1.0.0'
      end

      # Helper: get lookback window
      def lookback_window
        metric_definition&.calculation_window_days&.days || 3.years
      end

      def lookback_start_date
        snapshot_date - lookback_window
      end

      private

      def metric_definition
        @metric_definition ||= GrdaWarehouse::MetricDefinition.find_by(
          calculator_class: self.class.name
        )
      end
    end
  end
end
```

**Verification:**
- Models load without errors: `dcr shell bundle exec rails runner "puts GrdaWarehouse::MetricDefinition.name"`
- Migrations applied: Check `schema.rb` includes new tables

---

### Phase 2: Client Calculators (Sprint 1-2)

Implement the 8 initial client metric calculators.

#### 2.1 Create Calculator Directory Structure

```bash
mkdir -p app/models/grda_warehouse/metric_calculators/client
```

#### 2.2 Implement Client Calculators

**File:** `app/models/grda_warehouse/metric_calculators/client/homeless_days_calculator.rb`

```ruby
module GrdaWarehouse
  module MetricCalculators
    module Client
      class HomelessDaysCalculator < BaseCalculator
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
    end
  end
end
```

**File:** `app/models/grda_warehouse/metric_calculators/client/source_client_count_calculator.rb`

```ruby
module GrdaWarehouse
  module MetricCalculators
    module Client
      class SourceClientCountCalculator < BaseCalculator
        def calculate
          entity.source_clients.count
        end
      end
    end
  end
end
```

**File:** `app/models/grda_warehouse/metric_calculators/client/max_household_size_calculator.rb`

```ruby
module GrdaWarehouse
  module MetricCalculators
    module Client
      class MaxHouseholdSizeCalculator < BaseCalculator
        def calculate
          household_sizes = GrdaWarehouse::ServiceHistoryEnrollment
            .where(client_id: entity.id)
            .where('first_date_in_program <= ?', snapshot_date)
            .where('last_date_in_program >= ? OR last_date_in_program IS NULL', lookback_start_date)
            .joins(
              <<-SQL
                INNER JOIN service_history_enrollments AS household_members
                ON household_members.household_id = service_history_enrollments.household_id
                AND household_members.data_source_id = service_history_enrollments.data_source_id
                AND household_members.project_id = service_history_enrollments.project_id
              SQL
            )
            .group(:household_id, :data_source_id, :project_id)
            .count('DISTINCT household_members.client_id')

          household_sizes.values.max || 0
        end
      end
    end
  end
end
```

**File:** `app/models/grda_warehouse/metric_calculators/client/min_household_size_calculator.rb`

```ruby
module GrdaWarehouse
  module MetricCalculators
    module Client
      class MinHouseholdSizeCalculator < BaseCalculator
        def calculate
          household_sizes = GrdaWarehouse::ServiceHistoryEnrollment
            .where(client_id: entity.id)
            .where('first_date_in_program <= ?', snapshot_date)
            .where('last_date_in_program >= ? OR last_date_in_program IS NULL', lookback_start_date)
            .joins(
              <<-SQL
                INNER JOIN service_history_enrollments AS household_members
                ON household_members.household_id = service_history_enrollments.household_id
                AND household_members.data_source_id = service_history_enrollments.data_source_id
                AND household_members.project_id = service_history_enrollments.project_id
              SQL
            )
            .group(:household_id, :data_source_id, :project_id)
            .count('DISTINCT household_members.client_id')

          household_sizes.values.min || 0
        end
      end
    end
  end
end
```

**File:** `app/models/grda_warehouse/metric_calculators/client/enrollment_count_calculator.rb`

```ruby
module GrdaWarehouse
  module MetricCalculators
    module Client
      class EnrollmentCountCalculator < BaseCalculator
        def calculate
          GrdaWarehouse::ServiceHistoryEnrollment
            .where(client_id: entity.id)
            .where('first_date_in_program <= ?', snapshot_date)
            .where('last_date_in_program >= ? OR last_date_in_program IS NULL', lookback_start_date)
            .count
        end
      end
    end
  end
end
```

**File:** `app/models/grda_warehouse/metric_calculators/client/unique_projects_calculator.rb`

```ruby
module GrdaWarehouse
  module MetricCalculators
    module Client
      class UniqueProjectsCalculator < BaseCalculator
        def calculate
          GrdaWarehouse::ServiceHistoryEnrollment
            .where(client_id: entity.id)
            .where('first_date_in_program <= ?', snapshot_date)
            .where('last_date_in_program >= ? OR last_date_in_program IS NULL', lookback_start_date)
            .select(:project_id, :data_source_id)
            .distinct
            .count
        end
      end
    end
  end
end
```

**File:** `app/models/grda_warehouse/metric_calculators/client/current_living_situation_count_calculator.rb`

```ruby
module GrdaWarehouse
  module MetricCalculators
    module Client
      class CurrentLivingSituationCountCalculator < BaseCalculator
        def calculate
          GrdaWarehouse::Hud::CurrentLivingSituation
            .joins(enrollment: :client)
            .where('Client.id IN (?)', entity.source_clients.pluck(:id))
            .where(InformationDate: lookback_start_date..snapshot_date)
            .count
        end
      end
    end
  end
end
```

**File:** `app/models/grda_warehouse/metric_calculators/client/service_count_calculator.rb`

```ruby
module GrdaWarehouse
  module MetricCalculators
    module Client
      class ServiceCountCalculator < BaseCalculator
        def calculate
          GrdaWarehouse::ServiceHistoryService
            .where(client_id: entity.id)
            .where(date: lookback_start_date..snapshot_date)
            .count
        end
      end
    end
  end
end
```

#### 2.3 Test Calculators

Create RSpec tests for each calculator:

**File:** `spec/models/grda_warehouse/metric_calculators/client/homeless_days_calculator_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe GrdaWarehouse::MetricCalculators::Client::HomelessDaysCalculator do
  let(:client) { create(:grda_warehouse_hud_client) }
  let(:snapshot_date) { Date.current }
  let(:calculator) { described_class.new(client, snapshot_date) }

  describe '#calculate' do
    context 'with no services' do
      it 'returns 0' do
        expect(calculator.calculate).to eq(0)
      end
    end

    context 'with homeless services in last 3 years' do
      before do
        # Create test data
        create(:service_history_service,
          client: client,
          date: 30.days.ago,
          homeless: true
        )
        create(:service_history_service,
          client: client,
          date: 60.days.ago,
          homeless: true
        )
      end

      it 'returns count of distinct homeless service days' do
        expect(calculator.calculate).to eq(2)
      end
    end

    # Add more test cases
  end
end
```

**Run tests:** `dcr spec bundle exec rspec spec/models/grda_warehouse/metric_calculators/`

---

### Phase 3: Collection System (Sprint 2)

Build the batch collection and retention system.

#### 3.1 Create Collector Service

**File:** `app/models/grda_warehouse/tasks/metric_snapshot_collector.rb`

```ruby
module GrdaWarehouse
  module Tasks
    class MetricSnapshotCollector
      BATCH_SIZE = 5_000
      DAILY_RETENTION_DAYS = 30
      WEEKLY_ANCHOR_DAY = 3  # Wednesday

      def self.run_daily_collection(
        entity_type:,
        snapshot_date: Date.current,
        entity_ids: nil,
        metric_names: nil
      )
        new(
          entity_type: entity_type,
          snapshot_date: snapshot_date,
          entity_ids: entity_ids,
          metric_names: metric_names
        ).run
      end

      def initialize(entity_type:, snapshot_date:, entity_ids: nil, metric_names: nil)
        @entity_type = entity_type
        @snapshot_date = snapshot_date
        @entity_ids = entity_ids
        @metric_names = metric_names
      end

      def run
        metrics = load_metrics
        entities = load_entities

        Rails.logger.info "Collecting #{metrics.count} metrics for #{entities.count} #{@entity_type} records"

        entities.in_groups_of(BATCH_SIZE, false) do |entity_batch|
          collect_batch(entity_batch, metrics)
        end

        cleanup_old_snapshots
      end

      private

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
          lookback = @snapshot_date - 3.years
          entity_class
            .destination
            .joins(:service_history_services)
            .where('service_history_services.date >= ?', lookback)
            .where('service_history_services.date <= ?', @snapshot_date)
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
        snapshots = []

        entities.each do |entity|
          metrics.each do |metric|
            snapshot = calculate_snapshot(entity, metric)
            snapshots << snapshot if snapshot
          end
        end

        import_snapshots(snapshots)
      end

      def calculate_snapshot(entity, metric)
        calculator = metric.calculator_for(entity, @snapshot_date)
        new_value = calculator.calculate

        # Sparse storage: only record if value changed significantly
        return nil unless should_record_snapshot?(entity, metric, new_value)

        snapshot = GrdaWarehouse::MetricSnapshot.new(
          entity: entity,
          metric_definition: metric,
          snapshot_date: @snapshot_date,
          calculation_version: calculator.version
        )

        snapshot.value = new_value
        snapshot

      rescue => e
        Rails.logger.error "Failed to calculate #{metric.name} for #{entity.class.name}##{entity.id}: #{e.message}"
        nil
      end

      def should_record_snapshot?(entity, metric, new_value)
        # Find most recent snapshot for this entity/metric
        previous_snapshot = GrdaWarehouse::MetricSnapshot
          .where(
            entity_type: entity.class.name,
            entity_id: entity.id,
            metric_definition: metric
          )
          .where('snapshot_date < ?', @snapshot_date)
          .order(snapshot_date: :desc)
          .first

        # Always record first snapshot (establish baseline)
        return true unless previous_snapshot

        previous_value = previous_snapshot.value

        # Handle nil/null values
        return true if new_value.nil? != previous_value.nil?
        return false if new_value.nil? && previous_value.nil?

        # If no thresholds specified, always record (dense storage)
        count_threshold = metric.count_change_threshold
        percent_threshold = metric.percent_change_threshold
        return true if count_threshold.nil? && percent_threshold.nil?

        # Calculate change
        change = (new_value - previous_value).abs

        # Check count threshold
        return true if count_threshold && change >= count_threshold

        # Check percent threshold
        if percent_threshold && previous_value != 0
          percent_change = (change.to_f / previous_value.abs * 100)
          return true if percent_change >= percent_threshold
        end

        # No threshold met, don't record
        false
      end

      def import_snapshots(snapshots)
        return if snapshots.empty?

        snapshots.group_by { |s| s.metric_definition.value_type }.each do |value_type, typed_snapshots|
          value_column = "value_#{value_type}"

          GrdaWarehouse::MetricSnapshot.import(
            typed_snapshots,
            on_duplicate_key_update: {
              conflict_target: [:entity_type, :entity_id, :metric_definition_id, :snapshot_date],
              columns: [
                value_column.to_sym,
                :calculation_version,
                :updated_at
              ]
            }
          )
        end
      end

      def cleanup_old_snapshots
        cutoff_date = @snapshot_date - DAILY_RETENTION_DAYS.days

        deleted_count = GrdaWarehouse::MetricSnapshot
          .where(entity_type: @entity_type)
          .where('snapshot_date < ?', cutoff_date)
          .where('EXTRACT(DOW FROM snapshot_date) != ?', WEEKLY_ANCHOR_DAY)
          .delete_all

        Rails.logger.info "Cleaned up #{deleted_count} old #{@entity_type} snapshots (preserved Wednesdays)"
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

  def perform(snapshot_date = Date.current)
    GrdaWarehouse::Tasks::MetricSnapshotCollector.run_daily_collection(
      entity_type: 'GrdaWarehouse::Hud::Client',
      snapshot_date: snapshot_date
    )
  end
end
```

**File:** `app/jobs/collect_project_metrics_job.rb`

```ruby
class CollectProjectMetricsJob < ApplicationJob
  queue_as :default

  def perform(snapshot_date = Date.current)
    GrdaWarehouse::Tasks::MetricSnapshotCollector.run_daily_collection(
      entity_type: 'GrdaWarehouse::Hud::Project',
      snapshot_date: snapshot_date
    )
  end
end
```

**File:** `app/jobs/collect_data_source_metrics_job.rb`

```ruby
class CollectDataSourceMetricsJob < ApplicationJob
  queue_as :default

  def perform(snapshot_date = Date.current)
    GrdaWarehouse::Tasks::MetricSnapshotCollector.run_daily_collection(
      entity_type: 'GrdaWarehouse::DataSource',
      snapshot_date: snapshot_date
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
```ruby
dcr shell bundle exec rails runner "CollectClientMetricsJob.perform_now"
```

---

### Phase 4: Query Interface (Sprint 3)

Add concern and query methods for easy metric access.

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

  # Get latest value for a metric
  def metric_value(metric_name, as_of_date: Date.current)
    metric_def = GrdaWarehouse::MetricDefinition.find_by(
      name: metric_name,
      entity_type: self.class.name
    )

    return nil unless metric_def

    snapshot = metric_snapshots
      .where(metric_definition: metric_def)
      .where('snapshot_date <= ?', as_of_date)
      .order(snapshot_date: :desc)
      .first

    snapshot&.value
  end

  # Get time series for a metric
  def metric_time_series(
    metric_name,
    start_date: 90.days.ago,
    end_date: Date.current
  )
    metric_def = GrdaWarehouse::MetricDefinition.find_by(
      name: metric_name,
      entity_type: self.class.name
    )

    return [] unless metric_def

    metric_snapshots
      .where(metric_definition: metric_def)
      .where('snapshot_date >= ?', start_date)
      .where('snapshot_date <= ?', end_date)
      .order(:snapshot_date)
      .pluck(:snapshot_date, value_column_for_metric(metric_def))
  end

  # Detect change in a metric
  def metric_change(metric_name, days_back: 1)
    metric_def = GrdaWarehouse::MetricDefinition.find_by(
      name: metric_name,
      entity_type: self.class.name
    )

    return nil unless metric_def

    snapshots = metric_snapshots
      .where(metric_definition: metric_def)
      .order(snapshot_date: :desc)
      .limit(days_back + 1)

    return nil if snapshots.count < 2

    current = snapshots.first.value
    previous = snapshots[days_back].value

    case metric_def.value_type
    when 'integer', 'float'
      current - previous
    when 'boolean'
      current != previous
    else
      nil
    end
  end

  # Get all metrics as hash
  def all_metrics(as_of_date: Date.current)
    metric_snapshots
      .joins(:metric_definition)
      .where('snapshot_date <= ?', as_of_date)
      .select('DISTINCT ON (metric_definition_id) *')
      .order(:metric_definition_id, snapshot_date: :desc)
      .each_with_object({}) do |snapshot, hash|
        hash[snapshot.metric_definition.name] = snapshot.value
      end
  end

  private

  def value_column_for_metric(metric_def)
    case metric_def.value_type
    when 'integer' then :value_integer
    when 'float' then :value_float
    when 'string' then :value_string
    when 'boolean' then :value_boolean
    when 'json' then :value_json
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

#### 4.3 Add Batch Query Methods to MetricSnapshot

**File:** `app/models/grda_warehouse/metric_snapshot.rb` (additions)

```ruby
# Add these class methods to existing model

class << self
  # Get latest values for a metric across multiple entities
  def latest_values_for(metric_name:, entity_type:, entity_ids: nil, as_of_date: Date.current)
    metric_def = GrdaWarehouse::MetricDefinition.find_by(
      name: metric_name,
      entity_type: entity_type
    )

    return {} unless metric_def

    scope = where(metric_definition: metric_def)
      .where(entity_type: entity_type)
      .where('snapshot_date <= ?', as_of_date)

    scope = scope.where(entity_id: entity_ids) if entity_ids.present?

    scope
      .select("DISTINCT ON (entity_id) entity_id, snapshot_date, #{value_column_name(metric_def)}")
      .order(:entity_id, snapshot_date: :desc)
      .each_with_object({}) do |snapshot, hash|
        hash[snapshot.entity_id] = snapshot.value
      end
  end

  # Find entities where metric changed significantly
  def entities_with_change(
    metric_name:,
    entity_type:,
    threshold:,
    days_back: 1,
    as_of_date: Date.current
  )
    metric_def = GrdaWarehouse::MetricDefinition.find_by(
      name: metric_name,
      entity_type: entity_type
    )

    return [] unless metric_def
    return [] unless ['integer', 'float'].include?(metric_def.value_type)

    value_col = value_column_name(metric_def)
    comparison_date = as_of_date - days_back.days

    # Self-join to compare current vs previous
    current = arel_table
    previous = arel_table.alias('previous_snapshots')

    query = current
      .project(current[:entity_id])
      .join(previous)
      .on(
        current[:entity_id].eq(previous[:entity_id])
        .and(current[:metric_definition_id].eq(previous[:metric_definition_id]))
        .and(current[:entity_type].eq(previous[:entity_type]))
      )
      .where(current[:metric_definition_id].eq(metric_def.id))
      .where(current[:entity_type].eq(entity_type))
      .where(current[:snapshot_date].eq(as_of_date))
      .where(previous[:snapshot_date].eq(comparison_date))
      .where(
        Arel::Nodes::NamedFunction.new('ABS', [
          current[value_col].-(previous[value_col])
        ]).gteq(threshold)
      )

    where(entity_id: connection.select_values(query.to_sql))
      .where(snapshot_date: as_of_date)
      .where(metric_definition: metric_def)
      .includes(:entity)
      .map(&:entity)
  end

  # Aggregate metrics across entities
  def aggregate_metric(
    metric_name:,
    entity_type:,
    aggregation: :sum,
    as_of_date: Date.current,
    entity_ids: nil
  )
    metric_def = GrdaWarehouse::MetricDefinition.find_by(
      name: metric_name,
      entity_type: entity_type
    )

    return nil unless metric_def

    value_col = value_column_name(metric_def)

    scope = where(metric_definition: metric_def)
      .where(entity_type: entity_type)
      .where('snapshot_date <= ?', as_of_date)

    scope = scope.where(entity_id: entity_ids) if entity_ids.present?

    latest_snapshots = scope
      .select("DISTINCT ON (entity_id) entity_id, #{value_col}")
      .order(:entity_id, snapshot_date: :desc)

    case aggregation
    when :sum
      connection.select_value("SELECT SUM(#{value_col}) FROM (#{latest_snapshots.to_sql}) AS latest")
    when :avg
      connection.select_value("SELECT AVG(#{value_col}) FROM (#{latest_snapshots.to_sql}) AS latest")
    when :min
      connection.select_value("SELECT MIN(#{value_col}) FROM (#{latest_snapshots.to_sql}) AS latest")
    when :max
      connection.select_value("SELECT MAX(#{value_col}) FROM (#{latest_snapshots.to_sql}) AS latest")
    when :count
      latest_snapshots.count
    end
  end

  private

  def value_column_name(metric_def)
    "value_#{metric_def.value_type}"
  end
end
```

---

### Phase 5: Seed Initial Metrics (Sprint 3)

Create metric definitions for the 8 client metrics.

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
          value_type: 'integer',
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
          value_type: 'integer',
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
          value_type: 'integer',
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
          value_type: 'integer',
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
          value_type: 'integer',
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
          value_type: 'integer',
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
          value_type: 'integer',
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
          value_type: 'integer',
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

### Phase 6: Initial Data Collection (Sprint 3-4)

Run first collection and verify data.

#### 6.1 Test Collection on Sample

Test with a small sample first:

```ruby
# Get 100 sample client IDs
sample_ids = GrdaWarehouse::Hud::Client.destination.limit(100).pluck(:id)

# Run collection for sample
GrdaWarehouse::Tasks::MetricSnapshotCollector.run_daily_collection(
  entity_type: 'GrdaWarehouse::Hud::Client',
  snapshot_date: Date.current,
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

# Or directly
dcr shell bundle exec rails runner "
  GrdaWarehouse::Tasks::MetricSnapshotCollector.run_daily_collection(
    entity_type: 'GrdaWarehouse::Hud::Client'
  )
"
```

**Monitor:**
- Check logs for progress
- Watch `metric_snapshots` table row count
- Verify no errors in calculation

#### 6.3 Verify Data Quality

```sql
-- Count snapshots per metric
SELECT
  md.name,
  md.display_name,
  COUNT(*) as snapshot_count
FROM metric_snapshots ms
JOIN metric_definitions md ON md.id = ms.metric_definition_id
WHERE ms.snapshot_date = CURRENT_DATE
GROUP BY md.id, md.name, md.display_name
ORDER BY md.name;

-- Check value distribution
SELECT
  md.name,
  MIN(ms.value_integer) as min_value,
  AVG(ms.value_integer) as avg_value,
  MAX(ms.value_integer) as max_value
FROM metric_snapshots ms
JOIN metric_definitions md ON md.id = ms.metric_definition_id
WHERE ms.snapshot_date = CURRENT_DATE
  AND md.value_type = 'integer'
GROUP BY md.name
ORDER BY md.name;
```

---

### Phase 7: Historical Backfill (Optional, Sprint 4)

Backfill historical data for trend analysis.

#### 7.1 Create Backfill Script

**File:** `lib/tasks/backfill_metrics.rake`

```ruby
namespace :metrics do
  desc 'Backfill historical metric snapshots'
  task :backfill, [:start_date, :end_date] => :environment do |t, args|
    start_date = Date.parse(args[:start_date])
    end_date = Date.parse(args[:end_date] || Date.current.to_s)

    puts "Backfilling metrics from #{start_date} to #{end_date}"

    (start_date..end_date).each do |date|
      # Skip weekends to reduce load (optional)
      next if date.saturday? || date.sunday?

      puts "\nProcessing #{date}..."

      CollectClientMetricsJob.perform_now(date)

      # Add delay to avoid overwhelming database (optional)
      sleep 5
    end

    puts "\nBackfill complete!"
  end
end
```

#### 7.2 Run Backfill

```bash
# Backfill last 30 days
dcr shell bundle exec rails metrics:backfill[2025-01-01,2025-01-31]

# Or incrementally
dcr shell bundle exec rails metrics:backfill[2025-01-01,2025-01-07]
dcr shell bundle exec rails metrics:backfill[2025-01-08,2025-01-14]
# ...
```

**Note:** Backfill can be time-consuming for large date ranges. Consider:
- Running off-hours
- Limiting to specific client cohorts first
- Monitoring database load

---

### Phase 8: Testing & Validation (Throughout)

#### 8.1 Unit Tests

Test calculators, models, and concern methods:

```bash
dcr spec bundle exec rspec spec/models/grda_warehouse/metric_calculators/
dcr spec bundle exec rspec spec/models/grda_warehouse/metric_definition_spec.rb
dcr spec bundle exec rspec spec/models/grda_warehouse/metric_snapshot_spec.rb
dcr spec bundle exec rspec spec/models/concerns/has_metric_snapshots_spec.rb
```

#### 8.2 Integration Tests

Test full collection flow:

```ruby
# spec/jobs/collect_client_metrics_job_spec.rb
require 'rails_helper'

RSpec.describe CollectClientMetricsJob do
  let!(:client) { create(:grda_warehouse_hud_client) }
  let!(:metric_definition) do
    create(:metric_definition,
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
end
```

#### 8.3 Performance Tests

Monitor query performance:

```ruby
# spec/performance/metric_queries_spec.rb
require 'rails_helper'

RSpec.describe 'Metric Query Performance' do
  before do
    # Create test data
    100.times { create(:metric_snapshot) }
  end

  it 'retrieves latest value quickly' do
    client = GrdaWarehouse::Hud::Client.first

    time = Benchmark.realtime do
      client.metric_value('days_homeless_last_three_years')
    end

    expect(time).to be < 0.05  # 50ms threshold
  end
end
```

---

### Phase 9: Documentation & Training (Sprint 4-5)

#### 9.1 Add Inline Documentation

Document usage in models:

```ruby
# app/models/grda_warehouse/hud/client.rb

module GrdaWarehouse::Hud
  class Client < GrdaWarehouseBase
    include HasMetricSnapshots

    # Example usage:
    #
    #   client = GrdaWarehouse::Hud::Client.find(123)
    #
    #   # Get current metric value
    #   homeless_days = client.metric_value('days_homeless_last_three_years')
    #
    #   # Get time series for charting
    #   data = client.metric_time_series('days_homeless_last_three_years', start_date: 90.days.ago)
    #
    #   # Detect change
    #   change = client.metric_change('days_homeless_last_three_years', days_back: 7)

    # ... rest of model
  end
end
```

#### 9.2 Create Usage Examples

**File:** `docs/examples/metric_tracking_usage.md`

```markdown
# Metric Tracking Usage Examples

## Single Client Queries

### Get Latest Metric Value
client = GrdaWarehouse::Hud::Client.find(123)
homeless_days = client.metric_value('days_homeless_last_three_years')

### Get Time Series for Chart
time_series = client.metric_time_series(
  'days_homeless_last_three_years',
  start_date: 90.days.ago
)
# => [[Date, value], [Date, value], ...]

### Detect Change
weekly_change = client.metric_change('days_homeless_last_three_years', days_back: 7)
# => 5 (increased by 5 days)

## Batch Queries

### Get Values for Multiple Clients
values = GrdaWarehouse::MetricSnapshot.latest_values_for(
  metric_name: 'days_homeless_last_three_years',
  entity_type: 'GrdaWarehouse::Hud::Client',
  entity_ids: [123, 456, 789]
)
# => {123 => 45, 456 => 67, 789 => 12}

### Find Clients with Significant Changes
clients = GrdaWarehouse::MetricSnapshot.entities_with_change(
  metric_name: 'days_homeless_last_three_years',
  entity_type: 'GrdaWarehouse::Hud::Client',
  threshold: 30,
  days_back: 7
)

### Aggregate Across Population
total = GrdaWarehouse::MetricSnapshot.aggregate_metric(
  metric_name: 'days_homeless_last_three_years',
  entity_type: 'GrdaWarehouse::Hud::Client',
  aggregation: :sum
)
```

---

## Rollout Checklist

### Pre-Deployment

- [ ] All migrations created and tested in development
- [ ] All models created with tests passing
- [ ] Calculator classes implemented and tested
- [ ] Collection system tested with sample data
- [ ] Retention logic verified
- [ ] Query methods tested
- [ ] Documentation complete

### Initial Deployment

- [ ] Deploy migrations (non-breaking)
- [ ] Deploy model code
- [ ] Seed metric definitions
- [ ] Verify no errors in application

### Data Collection Start

- [ ] Run initial collection manually
- [ ] Verify data quality
- [ ] Monitor performance metrics
- [ ] Enable scheduled collection
- [ ] Monitor for 1 week

### Backfill (Optional)

- [ ] Test backfill on sample date range
- [ ] Run full backfill during off-hours
- [ ] Verify historical data

### Go Live

- [ ] Enable query methods in application code
- [ ] Add UI components (charts, reports)
- [ ] Train users on new features
- [ ] Monitor usage and performance

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

---

## Maintenance

### Regular Tasks

- **Monitor collection job**: Ensure runs daily without errors
- **Check disk space**: Monitor `metric_snapshots` table size
- **Verify data quality**: Spot-check metric values
- **Review performance**: Monitor query times

### Periodic Tasks

- **Add new metrics**: Follow extensibility pattern
- **Archive old data**: Beyond retention policy if needed
- **Update calculators**: Version and migrate when logic changes

---

## Success Metrics

Track these to measure implementation success:

- **Collection completion time** (target: < 60 seconds for 200k clients)
- **Query performance** (target: < 50ms for single value retrieval)
- **Storage growth** (target: ~300 MB/month for 200k clients × 8 metrics)
- **Error rate** (target: < 0.1% failed calculations)
- **User adoption** (track usage of metric query methods)

---

## Next Steps After Implementation

1. **Alert Integration**: Use metrics for change-based alerts
2. **Reporting**: Build dashboards showing metric trends
3. **API Endpoints**: Expose metrics via REST API
4. **Additional Entity Types**: Extend to projects, organizations
5. **Predictive Analytics**: Use historical data for forecasting
