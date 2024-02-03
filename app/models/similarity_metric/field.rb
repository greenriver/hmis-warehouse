###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimilarityMetric
  # a similarity metric identified by a single field/attribute of a HUD client
  class Field < Base

    def field
      nil
    end

    def bogus?
      field.nil?
    end

  end
end
