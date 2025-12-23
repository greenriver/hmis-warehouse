###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module SimilarityMetric
  class NoSingleGender < SimilarityMetric::Boolean
    def field
      :NoSingleGender
    end
  end
end
