module SimilarityMetric
  class FirstNameMetaphone < DoubleMetaphone
    include NameDataQuality
    
    def field
      :FirstName
    end
  end
end