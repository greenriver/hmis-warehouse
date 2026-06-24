###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
