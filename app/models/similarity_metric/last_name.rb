module SimilarityMetric
  class LastName < SimilarityMetric::Levenshtein
    include NameDataQuality
    
    def field
      :LastName
    end
  end
end