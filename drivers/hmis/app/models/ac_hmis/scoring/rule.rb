###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module AcHmis
  module Scoring
    class Rule < ::GrdaWarehouseBase
      self.table_name = 'hmis_scoring_rules'

      validates :link_id, :weight, presence: true
      validates :link_id, uniqueness: { scope: [:algorithm, :min_value, :max_value, :exact_value] }
      validate :valid_matching_criteria

      scope :for_algorithm, ->(algorithm) { where(algorithm: algorithm) }

      # Check if a given response value matches this rule's criteria
      def matches_value?(value)
        return false unless value
        return value.to_s == exact_value if exact_value.present?

        min_val = convert_value(min_value, value)
        max_val = convert_value(max_value, value)

        # Range check: (exclusive, inclusive]
        (min_val.nil? || value > min_val) && (max_val.nil? || value <= max_val)
      end

      # Get all rules for a specific algorithm, grouped by link_id for efficient lookup
      def self.rules_by_link_id(algorithm)
        for_algorithm(algorithm).group_by(&:link_id)
      end

      private

      # Convert string value to same type as reference value
      def convert_value(string_val, reference_val)
        return nil if string_val.nil?

        case reference_val
        when Numeric
          begin
            Float(string_val)
          rescue ArgumentError
            string_val
          end
        when Date, Time
          begin
            Time.parse(string_val)
          rescue ArgumentError
            string_val
          end
        else
          string_val
        end
      end

      def valid_matching_criteria
        errors.add(:base, 'Must specify either exact_value or at least one of min_value/max_value') if exact_value.blank? && min_value.blank? && max_value.blank?
      end
    end
  end
end
