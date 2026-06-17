###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module SimilarityMetric
  class FirstNameMetaphone < DoubleMetaphone
    include NameDataQuality

    def field
      :FirstName
    end
  end
end
