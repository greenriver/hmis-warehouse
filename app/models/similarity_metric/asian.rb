###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module SimilarityMetric
  class Asian < SimilarityMetric::Boolean
    def field
      :Asian
    end
  end
end
