###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module SimilarityMetric
  class Black < SimilarityMetric::Boolean
    def field
      :BlackAfAmerican
    end
  end
end
