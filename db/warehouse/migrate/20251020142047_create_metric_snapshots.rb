###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateMetricSnapshots < ActiveRecord::Migration[7.1]
  def up
    safety_assured do
      # Create parent table as partitioned table
      execute <<-SQL
        CREATE TABLE metric_snapshots (
          id bigserial,
          entity_type varchar NOT NULL,
          entity_id bigint NOT NULL,
          metric_definition_id bigint NOT NULL,

          -- Range tracking: this snapshot is valid from initial through current observation
          initial_observation_date date NOT NULL,
          current_observation_date date NOT NULL,

          -- Count values (all metrics are counts/integers)
          initial_value bigint NOT NULL,
          current_value bigint NOT NULL,

          calculation_version varchar(20),
          created_at timestamp(6) NOT NULL,
          updated_at timestamp(6) NOT NULL,

          PRIMARY KEY (id, initial_observation_date)
        ) PARTITION BY RANGE (initial_observation_date);
      SQL

      execute "COMMENT ON TABLE metric_snapshots IS 'Time-series snapshots of metric counts (sparse, range-based storage)'"
      execute "COMMENT ON COLUMN metric_snapshots.initial_observation_date IS 'Date this value range started'"
      execute "COMMENT ON COLUMN metric_snapshots.current_observation_date IS 'Last date this value was calculated/verified'"
      execute "COMMENT ON COLUMN metric_snapshots.initial_value IS 'Count value when first observed at initial_observation_date'"
      execute "COMMENT ON COLUMN metric_snapshots.current_value IS 'Count value as of current_observation_date (updated daily)'"

      # Unique constraint: only one "open" snapshot per entity/metric
      # Must include partition key (initial_observation_date) per PostgreSQL requirement
      add_index :metric_snapshots,
                [:entity_type, :entity_id, :metric_definition_id, :initial_observation_date, :current_observation_date],
                unique: true,
                name: 'index_metric_snapshots_unique'

      # For finding snapshots that span a specific date
      add_index :metric_snapshots,
                [:entity_type, :entity_id, :metric_definition_id, :initial_observation_date, :current_observation_date],
                name: 'index_metric_snapshots_for_date_range'

      # For cleanup queries
      add_index :metric_snapshots,
                [:metric_definition_id, :current_observation_date],
                name: 'index_metric_snapshots_for_cleanup'

      # For time series queries ordered by start date
      add_index :metric_snapshots,
                [:entity_type, :entity_id, :metric_definition_id, :initial_observation_date],
                name: 'index_metric_snapshots_for_time_series'

      # Foreign key
      add_foreign_key :metric_snapshots, :metric_definitions

      # Create partitions for last 3 years + next 10 years (13 years = 52 quarterly partitions)
      # This avoids needing maintenance tasks to create future partitions
      create_quarterly_partitions(3.years.ago, 10.years.from_now)

      # Create default partition for any dates outside the range
      # This is useful for tests and for data older than 3 years
      execute <<-SQL
        CREATE TABLE metric_snapshots_default PARTITION OF metric_snapshots DEFAULT;
      SQL
    end
  end

  def down
    drop_table :metric_snapshots
  end

  private

  def create_quarterly_partitions(start_date, end_date)
    current_quarter = start_date.beginning_of_quarter

    while current_quarter <= end_date
      quarter_start = current_quarter.beginning_of_quarter
      quarter_end = current_quarter.end_of_quarter
      next_quarter_start = quarter_end + 1.day

      year = quarter_start.year
      quarter_num = (quarter_start.month / 3.0).ceil
      partition_name = "metric_snapshots_#{year}_q#{quarter_num}"

      execute <<-SQL
        CREATE TABLE #{partition_name} PARTITION OF metric_snapshots
        FOR VALUES FROM ('#{quarter_start}') TO ('#{next_quarter_start}');
      SQL

      current_quarter += 3.months
    end
  end
end
