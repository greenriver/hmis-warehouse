###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Monitoring::MetricCalculators
  class BaseCalculator
    attr_reader :entity, :calculation_date

    def initialize(entity, calculation_date)
      @entity = entity
      @calculation_date = calculation_date
    end

    # Instance method - calculate for single entity
    # Subclasses should implement this OR override calculate_batch
    def calculate
      raise NotImplementedError, "#{self.class} must implement #calculate"
    end

    # Class method - calculate for batch of entities
    # Returns hash of { entity_id => value }
    # Subclasses should override this for efficient batch processing
    def self.calculate_batch(entities, calculation_date)
      entities.to_h do |entity|
        [entity.id, new(entity, calculation_date).calculate]
      end
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
      calculation_date - lookback_window
    end

    private

    def metric_definition
      @metric_definition ||= GrdaWarehouse::Monitoring::MetricDefinition.find_by(
        calculator_class: self.class.name,
      )
    end
  end
end
