###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  class Questioning < SimilarityMetric::Boolean
    def field
      :Questioning
    end
  end
end
