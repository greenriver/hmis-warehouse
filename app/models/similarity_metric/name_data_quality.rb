###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

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