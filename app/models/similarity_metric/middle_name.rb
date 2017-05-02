module SimilarityMetric
  class MiddleName < SimilarityMetric::Levenshtein
    include NameDataQuality
    
    def field
      :MiddleName
    end
  end
end