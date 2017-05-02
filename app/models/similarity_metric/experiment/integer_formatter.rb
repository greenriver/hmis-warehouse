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
