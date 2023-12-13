###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class Admin::FormRuleInput < Types::BaseInputObject
    argument :project_type, Types::HmisSchema::Enums::ProjectType, required: false
    argument :funder, Types::HmisSchema::Enums::Hud::FundingSource, required: false
    argument :other_funder, String, required: false
    argument :organization_id, ID, required: false
    argument :project_id, ID, required: false
    argument :data_collected_about, Types::Forms::Enums::DataCollectedAbout, required: false

    def to_attributes
      attrs = {
        project_type: project_type,
        funder: funder,
        other_funder: other_funder,
        data_collected_about: data_collected_about,
      }
      if project_id
        attrs[:entity] = Hmis::Hud::Project.viewable_by(current_user).find(project_id)
      elsif organization_id
        attrs[:entity] = Hmis::Hud::Organization.viewable_by(current_user).find(organization_id)
      end
      attrs
    end
  end
end
