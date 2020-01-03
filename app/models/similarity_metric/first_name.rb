###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module SimilarityMetric
  class FirstName < SimilarityMetric::Levenshtein
    include NameDataQuality

    def field
      :FirstName
    end
  end
end