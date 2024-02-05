###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  class Black < SimilarityMetric::Boolean
    def field
      :BlackAfAmerican
    end
  end
end
