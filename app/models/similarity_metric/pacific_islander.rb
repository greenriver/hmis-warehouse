###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module SimilarityMetric
  class PacificIslander < SimilarityMetric::Boolean
    def field
      :NativeHIOtherPacific
    end
  end
end