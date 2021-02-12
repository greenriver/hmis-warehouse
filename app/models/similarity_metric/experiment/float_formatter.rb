###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  module Experiment
    # for pretty-printing float columns in histograms
    class FloatFormatter
      def initialize(keys)
        return unless keys.any?

        any_negative = keys.any?(&:negative?)
        i = keys.map(&:abs).map(&:to_i).map(&:to_s).map(&:length).max
        @f = any_negative ? "% #{i + 3}.2f" : "%#{i + 3}.2f"
      end

      def format(float)
        format @f, float
      end
    end
  end
end
