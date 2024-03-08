###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::ProjectConfigInput < BaseInputObject
    description 'Project Config Input'

    argument :config_type, HmisSchema::Enums::ProjectConfigType, required: false
    argument :length_of_absence_days, Int, required: false
    argument :project_type, Types::HmisSchema::Enums::ProjectType, required: false
    argument :project_id, ID, required: false
    argument :organization_id, ID, required: false

    def to_params
      to_h.except!(:config_type)
    end
  end
end
