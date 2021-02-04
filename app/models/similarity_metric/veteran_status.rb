###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  class VeteranStatus < SimilarityMetric::Boolean
    def field
      :VeteranStatus
    end

    def group(v)
      v if [0, 1].include?(v)
    end
  end
end
