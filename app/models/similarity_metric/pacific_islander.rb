###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  class PacificIslander < SimilarityMetric::Boolean
    def field
      :NativeHIPacific
    end
  end
end
