###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module AcHmis
  module Scoring
    class Threshold < ::GrdaWarehouseBase
      self.table_name = 'hmis_scoring_algorithm_thresholds'

      belongs_to :algorithm, class_name: 'AcHmis::Scoring::Algorithm', foreign_key: :hmis_scoring_algorithm_id

      validates :threshold, :points, presence: true
      validates :points, uniqueness: { scope: :hmis_scoring_algorithm_id }

      scope :for_algorithm, ->(algorithm) { joins(:algorithm).where(algorithm: algorithm) }
      scope :ordered_by_points_desc, -> { order(points: :desc) }

      # Get thresholds for a specific algorithm ordered by points (descending)
      def self.thresholds_for_algorithm(algorithm)
        for_algorithm(algorithm).ordered_by_points_desc.pluck(:threshold, :points)
      end
    end
  end
end
