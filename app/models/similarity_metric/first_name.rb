module SimilarityMetric
  class FirstName < SimilarityMetric::Levenshtein
    include NameDataQuality
    
    def field
      :FirstName
    end
  end
end