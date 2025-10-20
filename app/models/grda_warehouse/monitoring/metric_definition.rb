###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Monitoring
  class MetricDefinition < GrdaWarehouseBase
    VALID_CATEGORIES = ['days_homeless_in_the_last_three_years', 'household_calculations'].freeze
    COLLECTION_HOUR = 2 # Hour of day (0-23) to run daily metric collection

    has_many :metric_snapshots,
             class_name: 'GrdaWarehouse::Monitoring::MetricSnapshot',
             dependent: :destroy

    validates :name, presence: true, uniqueness: { scope: :entity_type }
    validates :entity_type, presence: true
    validates :calculator_class, presence: true
    validates :category, inclusion: { in: VALID_CATEGORIES }, allow_nil: true

    scope :active, -> { where(active: true) }
    scope :for_entity_type, ->(type) { where(entity_type: type) }

    # Instantiate calculator for given entity
    def calculator_for(entity, calculation_date)
      calculator_class.constantize.new(
        entity,
        calculation_date,
      )
    end

    # Calculate and return value
    def calculate_value(entity, calculation_date)
      calculator_for(
        entity,
        calculation_date,
      ).calculate
    end

    # List of all available calculator classes
    def self.available_calculators
      [
        GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator,
        GrdaWarehouse::Monitoring::MetricCalculators::MinHouseholdSizeCalculator,
        GrdaWarehouse::Monitoring::MetricCalculators::MaxHouseholdSizeCalculator,
      ]
    end

    # Initialize default metric definitions
    # Called once via TaskQueue to populate the table
    def self.maintain!
      available_calculators.each do |calculator_class|
        attrs = calculator_class.metric_definition_attributes
        find_or_create_by!(
          name: attrs[:name],
          entity_type: attrs[:entity_type],
        ) do |metric|
          metric.assign_attributes(attrs)
        end
      end
    end
  end
end
