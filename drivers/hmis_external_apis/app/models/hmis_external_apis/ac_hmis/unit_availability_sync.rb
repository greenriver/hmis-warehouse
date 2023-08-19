###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  # Track local and synced changes
  class UnitAvailabilitySync < ::HmisExternalApis::HmisExternalApisBase
    self.table_name = 'hmis_external_unit_availability_syncs'
    belongs_to :project, class_name: 'Hmis::Hud::Project'
    belongs_to :unit_type, class_name: 'Hmis::UnitType'
    belongs_to :user, class_name: 'Hmis::Hud::User'
  end
end
