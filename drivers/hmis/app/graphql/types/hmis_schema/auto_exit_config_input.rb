###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# todo @martha - is this needed?
module Types
  class HmisSchema::AutoExitConfigInput < BaseInputObject
    description 'Auto Exit Config Input'

    argument :length_of_absence_days, Int, required: false
    argument :project_type, Types::HmisSchema::Enums::ProjectType, required: false
    argument :project_id, ID, required: false
    argument :organization_id, ID, required: false

    def to_params
      to_h
    end
  end
end
