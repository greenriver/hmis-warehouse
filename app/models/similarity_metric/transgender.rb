###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module SimilarityMetric
  class Transgender < SimilarityMetric::Boolean
    def field
      :Transgender
    end
  end
end
