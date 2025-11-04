###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Monitoring
  class MetricSnapshot < GrdaWarehouseBase
    self.table_name = 'metric_snapshots'

    belongs_to :entity, polymorphic: true
    belongs_to :metric_definition,
               class_name: 'GrdaWarehouse::Monitoring::MetricDefinition'

    validates :initial_observation_date, presence: true
    validates :current_observation_date, presence: true
    validates :initial_value, presence: true
    validates :current_value, presence: true

    validates :current_observation_date, uniqueness: {
      scope: [:entity_type, :entity_id, :metric_definition_id],
      message: 'Only one active snapshot per entity/metric',
    }

    # Scopes
    scope :for_date_range, ->(start_date, end_date) {
      where(initial_observation_date: ..end_date).
        where(current_observation_date: start_date..)
    }

    scope :for_entity, ->(entity) {
      where(entity_type: entity.class.name, entity_id: entity.id)
    }

    scope :for_metric, ->(metric_definition) {
      where(metric_definition_id: metric_definition.id)
    }

    scope :active_as_of, ->(date) {
      where(initial_observation_date: ..date).
        where(current_observation_date: date..)
    }

    scope :current, -> {
      where(current_observation_date: 30.days.ago.to_date..)
    }

    scope :stale, -> {
      where(current_observation_date: ...30.days.ago.to_date)
    }

    # Duration of this snapshot in days
    def duration_days
      (current_observation_date - initial_observation_date).to_i
    end

    # Total change over the range
    def total_change
      current_value - initial_value
    end
  end
end
