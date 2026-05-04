# frozen_string_literal: true

require 'dentaku'

module Hmis::Ce::Match::Expression
  module CalculatorFactory
    # Resolves +identifier+ to a +GrdaWarehouse::Cohort+ id for match expressions (+COHORT+).
    # Accepts a numeric id or an exact cohort name (string). Duplicate names use the lowest id and log a warning.
    def self.resolve_cohort_id(identifier)
      return nil if identifier.nil?

      case identifier
      when Integer
        id = identifier
      when Numeric
        id = identifier.to_i
      when String
        rows = GrdaWarehouse::Cohort.where(name: identifier).order(:id).pluck(:id)
        return nil if rows.empty?

        if rows.size > 1
          Rails.logger.warn(
            "[CE COHORT] Multiple cohorts named #{identifier.inspect} (#{rows.size} rows); using id=#{rows.first}",
          )
        end
        id = rows.first
      else
        return nil
      end

      return nil unless GrdaWarehouse::Cohort.where(id: id).exists?

      id
    end

    # calculator with custom functions
    def self.build
      calculator = Dentaku::Calculator.new(case_sensitive: true) # CDED keys are case sensitive, so Dentaku expressions should be too
      calculator.add_function(
        :INCLUDES,
        :logical,
        ->(a, b) do
          return false if a.nil? || b.nil?

          Array(a).include?(b)
        end,
      )
      calculator.add_function(
        :EXCLUDES,
        :logical,
        ->(a, b) do
          return false if a.nil? || b.nil?

          !Array(a).include?(b)
        end,
      )
      calculator.add_function(
        :PROJECT_TYPE,
        :string,
        ->(identifier) do
          return nil if identifier.nil?

          HudHelper.util.hmis_project_type_key(identifier, true)
        end,
      )
      calculator.add_function(
        :COHORT,
        :numeric,
        ->(identifier) do
          Hmis::Ce::Match::Expression::CalculatorFactory.resolve_cohort_id(identifier)
        end,
      )
      calculator.add_function(
        :EPOCH_SECONDS,
        :numeric,
        ->(value) {
          return nil if value.nil?

          case value
          when ActiveSupport::TimeWithZone, Time
            value.in_time_zone.to_i
          when Date
            Time.zone.local(value.year, value.month, value.day).to_i
          when String
            parsed = Time.zone.parse(value)
            raise ArgumentError, "Cannot cast #{value.inspect} to seconds" unless parsed

            parsed.to_i
          else
            raise ArgumentError, "Cannot cast #{value.inspect} to seconds"
          end
        },
      )

      return calculator
    end
  end
end
