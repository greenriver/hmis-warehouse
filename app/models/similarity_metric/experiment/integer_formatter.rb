###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  module Experiment

    # for pretty-printing ranges in histograms
    class IntegerFormatter
      def initialize(keys)
        @f = "%#{ keys.map(&:to_s).map(&:length).max }d" if keys.any?
      end

      def format(i)
        sprintf @f, i
      end
    end
  end
end
