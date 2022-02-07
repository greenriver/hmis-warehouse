###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  class NoSingleGender < SimilarityMetric::Boolean
    def field
      :NoSingleGender
    end
  end
end
