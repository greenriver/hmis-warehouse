###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module SimilarityMetric
  class FirstNameMetaphone < DoubleMetaphone
    include NameDataQuality
    
    def field
      :FirstName
    end
  end
end