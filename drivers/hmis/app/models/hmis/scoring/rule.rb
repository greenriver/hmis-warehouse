###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  module Scoring
    class Rule < ::GrdaWarehouseBase
      self.table_name = 'hmis_scoring_rules'

      RANGE = 'range'
      EXACT_MATCH = 'exact_match'
      VALUE = 'value'
      INCLUDE = 'include'
      CRITERIA_TYPES = [RANGE, EXACT_MATCH, VALUE, INCLUDE].freeze

      validates :link_id, :form_definition_identifier, :algorithm, :criteria_type, :weight, presence: true
      validates :criteria_type, inclusion: { in: CRITERIA_TYPES }
      validate :valid_criteria_config

      scope :for_algorithm, ->(algorithm) { where(algorithm: algorithm) }
      scope :for_form, ->(form_definition_identifier) { where(form_definition_identifier: form_definition_identifier) }

      # Evaluate this rule against a response value and return the score contribution
      def evaluate(response_value)
        weighted_value = 0

        weighted_value = 1 if criteria_type == RANGE && range_match?(response_value)
        weighted_value = 1 if criteria_type == EXACT_MATCH && exact_match?(response_value)
        weighted_value = 1 if criteria_type == INCLUDE && include?(response_value)
        weighted_value = convert_to_numeric(response_value) || 0 if criteria_type == VALUE

        weighted_value * weight
      end

      private

      def range_match?(value)
        numeric_value = convert_to_numeric(value)
        return false if numeric_value.nil?

        # gather up all the range-related criteria in a list and check if they all match.
        criteria_config.all? do |operator, threshold|
          case operator
          when 'gt' then numeric_value > threshold
          when 'gte' then numeric_value >= threshold
          when 'lt' then numeric_value < threshold
          when 'lte' then numeric_value <= threshold
          else true # ignore unknown operators
          end
        end
      end

      def exact_match?(value)
        match_value = criteria_config['match_value']

        # Handle nil matching explicitly
        return value.nil? if match_value.nil?

        # For non-nil values, convert both to strings for comparison
        value.to_s == match_value.to_s
      end

      def include?(value)
        include_value = criteria_config['include']
        return false if include_value.nil? || value.nil?

        # Check if the response array includes the target value (convert both to strings for comparison)
        Array.wrap(value).map(&:to_s).include?(include_value.to_s)
      end

      def convert_to_numeric(value)
        case value
        when Numeric
          value
        when String
          begin
            # Try integer first, then float
            value.match?(/\A-?\d+\z/) ? Integer(value) : Float(value)
          rescue ArgumentError
            nil
          end
        end
      end

      def valid_criteria_config
        validate_range_config if criteria_type == RANGE
        validate_exact_match_config if criteria_type == EXACT_MATCH
        validate_include_config if criteria_type == INCLUDE
      end

      def validate_range_config
        valid_operators = ['gt', 'gte', 'lt', 'lte']
        config_operators = criteria_config.keys & valid_operators

        errors.add(:criteria_config, 'Range criteria must specify at least one of: gt, gte, lt, lte') if config_operators.empty?
        errors.add(:criteria_config, 'Cannot specify both gt and gte') if criteria_config.key?('gt') && criteria_config.key?('gte')
        errors.add(:criteria_config, 'Cannot specify both lt and lte') if criteria_config.key?('lt') && criteria_config.key?('lte')

        # Check bounds make sense
        lower = criteria_config['gt'] || criteria_config['gte']
        upper = criteria_config['lt'] || criteria_config['lte']
        errors.add(:criteria_config, 'Lower bound must be less than upper bound') if lower && upper && lower >= upper
      end

      def validate_exact_match_config
        # `match_value` key has to exist, but value can be nil
        errors.add(:criteria_config, 'Exact match criteria must specify a match_value') unless criteria_config.key?('match_value')
      end

      def validate_include_config
        errors.add(:criteria_config, 'Include criteria must specify an include value') unless criteria_config.key?('include')
      end
    end
  end
end
