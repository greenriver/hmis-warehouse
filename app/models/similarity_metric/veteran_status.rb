###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module SimilarityMetric
  class VeteranStatus < SimilarityMetric::Boolean
    def field
      :VeteranStatus
    end

    def group(v)
      v if v == 0 || v == 1
    end
  end
end