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

      belongs_to :algorithm, class_name: 'AcHmis::Scoring::Algorithm', foreign_key: :hmis_scoring_algorithm_id

      validates :link_id, :weight, presence: true
      validates :link_id, uniqueness: { scope: [:hmis_scoring_algorithm_id, :min_value, :max_value, :exact_value] }
      validate :must_have_matching_criteria

      scope :for_algorithm, ->(algorithm) { joins(:algorithm).where(algorithm: algorithm) }

      # Check if a given response value matches this rule's criteria
      def matches_value?(value)
        return value.to_s == exact_value if exact_value.present?

        # For numeric ranges: min_value is inclusive, max_value is exclusive [min, max)
        # This prevents overlapping ranges at boundaries
        (min_value.nil? || value >= min_value) && (max_value.nil? || value < max_value)
      end

      # Get all rules for a specific algorithm, grouped by link_id for efficient lookup
      def self.rules_by_link_id(algorithm)
        for_algorithm(algorithm).group_by(&:link_id)
      end

      private

      def must_have_matching_criteria
        errors.add(:base, 'Must specify either exact_value or at least one of min_value/max_value') if exact_value.blank? && min_value.blank? && max_value.blank?
      end
    end
  end
end
