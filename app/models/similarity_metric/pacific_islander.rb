###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  class PacificIslander < SimilarityMetric::Boolean
    def field
      TodoOrDie('When we update reporting for 2022 spec', by: '2021-10-01')
      :NativeHIOtherPacific
    end
  end
end
