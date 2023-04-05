###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::FunderInput < BaseInputObject
    def self.source_type
      Types::HmisSchema::Funder
    end

    hud_argument :project_id, ID, required: false
    hud_argument :funder, HmisSchema::Enums::Hud::FundingSource
    hud_argument :other_funder
    hud_argument :grant_id
    hud_argument :start_date
    hud_argument :end_date

    def to_params
      result = to_h
      result[:project_id] = Hmis::Hud::Project.viewable_by(current_user).find_by(id: project_id)&.project_id if project_id.present?

      result
    end
  end
end
