module SimilarityMetric
  class LastNameMetaphone < DoubleMetaphone
    include NameDataQuality
    
    def field
      :LastName
    end
  end
end