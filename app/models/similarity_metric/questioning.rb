###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module SimilarityMetric
  class Questioning < SimilarityMetric::Boolean
    def field
      :Questioning
    end
  end
end
