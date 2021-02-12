###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  module NameDataQuality
    def quality_data?(_client)
      return true # ditching this logic for now
      # if (q = client.NameDataQuality)
      #   ![9, 99].include?(q)
      # else
      #   true
      # end
    end
  end
end
