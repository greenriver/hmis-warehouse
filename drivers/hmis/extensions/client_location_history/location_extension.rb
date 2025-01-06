###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::ClientLocationHistory
  module LocationExtension
    extend ActiveSupport::Concern

    included do
      has_one :form_processor, class_name: 'Hmis::Form::FormProcessor', foreign_key: :clh_location_id

      # HMIS FormProcessor relies on these hooks to ensure that location `source`
      # gets saved with a reference to GrdaWarehouse:: record rather than Hmis:: record.
      before_create :ensure_grda_warehouse_source
      before_update :ensure_grda_warehouse_source

      private def ensure_grda_warehouse_source
        # This somewhat hacky solution gets around the fact that during HMIS Form Processing, we haven't yet saved the
        # Enrollment being generated, so we don't yet have an ID with which to get the Warehouse enrollment.
        return unless source_type&.starts_with? 'Hmis::Hud::'

        self.source_type = source_type.sub('Hmis::Hud::', 'GrdaWarehouse::Hud::')
      end
    end
  end
end
