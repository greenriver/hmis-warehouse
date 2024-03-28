###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
    argument :active_status, Types::HmisSchema::Enums::ActiveStatus, required: false
    argument :service_type_id, ID, required: false
    argument :service_category_id, ID, required: false

    def to_attributes
      attrs = {
        project_type: project_type,
        funder: funder,
        other_funder: other_funder,
        data_collected_about: data_collected_about,
        active: active_status == 'ACTIVE',
        custom_service_type_id: service_type_id,
        custom_service_category_id: service_category_id,
      }
      attrs[:entity] = if project_id
        Hmis::Hud::Project.viewable_by(current_user).find(project_id)
      elsif organization_id
        Hmis::Hud::Organization.viewable_by(current_user).find(organization_id)
      end
      attrs
    end
  end
end
