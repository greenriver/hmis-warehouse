###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  class Transgender < SimilarityMetric::Boolean
    def field
      :Transgender
    end
  end
end
