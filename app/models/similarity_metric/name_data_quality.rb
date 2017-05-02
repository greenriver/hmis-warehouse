module SimilarityMetric
  module NameDataQuality
    def quality_data?(client)
      return true # ditching this logic for now
      if q = client.NameDataQuality
        !( q == 9 || q == 99 )
      else
        true
      end
    end
  end
end