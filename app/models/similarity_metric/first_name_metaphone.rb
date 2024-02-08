###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  class FirstNameMetaphone < DoubleMetaphone
    include NameDataQuality

    def field
      :FirstName
    end
  end
end
