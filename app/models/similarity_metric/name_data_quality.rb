###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
