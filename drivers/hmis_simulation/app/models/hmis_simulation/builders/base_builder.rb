###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  module Builders
    # Shared foundation for all HmisSimulation builder classes.
    #
    # Provides:
    #   EXPORT_ID         — shared constant sourced from Bootstrapper
    #   audit_attrs(date) — returns the 5 common HUD record fields so callers
    #                        can write **audit_attrs(date) instead of repeating
    #                        them in every create!/new call.
    class BaseBuilder
      EXPORT_ID = Bootstrapper::EXPORT_ID
      # HUD 4.11 code 116 — "Place not meant for habitation"
      PLACE_NOT_MEANT_FOR_HABITATION = 116

      def initialize(data_source:, user_id:)
        @ds  = data_source
        @uid = user_id
      end

      private

      def audit_attrs(date)
        {
          data_source_id: @ds.id,
          UserID: @uid,
          ExportID: EXPORT_ID,
          DateCreated: date.to_datetime,
          DateUpdated: date.to_datetime,
        }
      end
    end
  end
end
