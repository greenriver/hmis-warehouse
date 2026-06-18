###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module SimilarityMetric
  class LastNameMetaphone < DoubleMetaphone
    include NameDataQuality

    def field
      :LastName
    end
  end
end
