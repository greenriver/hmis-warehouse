###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  module Experiment
    # for pretty-printing ranges in histograms
    class RangeFormatter
      def initialize(ranges)
        @f1 = "% #{ranges.map(&:first).map { |n| format '%.2f', n }.map(&:length).max}.2f"
        @f2 = "% #{ranges.map(&:last).map { |n| format '%.2f', n }.map(&:length).max}.2f"
      end

      def format(range)
        "#{format @f1, range.first}...#{format @f2, range.last}"
      end
    end
  end
end
