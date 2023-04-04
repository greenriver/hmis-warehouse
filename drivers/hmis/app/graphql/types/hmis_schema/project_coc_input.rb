###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::ProjectCocInput < BaseInputObject
    def self.source_type
      Types::HmisSchema::ProjectCoc
    end

    hud_argument :project_id, ID
    hud_argument :coc_code
    hud_argument :geocode
    hud_argument :address1
    hud_argument :address2
    hud_argument :city
    hud_argument :state
    hud_argument :zip
    hud_argument :geography_type, HmisSchema::Enums::Hud::GeographyType

    def to_params
      result = to_h
      result[:project_id] = Hmis::Hud::Project.viewable_by(current_user).find_by(id: project_id)&.project_id if project_id.present?

      result
    end
  end
end
