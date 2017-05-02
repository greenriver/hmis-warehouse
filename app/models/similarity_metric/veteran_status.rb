module SimilarityMetric
  class VeteranStatus < SimilarityMetric::Boolean
    def field
      :VeteranStatus
    end

    def group(v)
      v if v == 0 || v == 1
    end
  end
end