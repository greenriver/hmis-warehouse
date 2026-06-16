###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module SimilarityMetric
  class VeteranStatus < SimilarityMetric::Boolean
    def field
      :VeteranStatus
    end

    def group(v)
      v if v == 0 || v == 1
    end
  end
end
