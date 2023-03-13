###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::FormInput < Types::BaseInputObject
    # Form definition used
    argument :form_definition_id, ID, required: true
    # Record being updated (if update)
    argument :record_id, ID, required: false
    # Needed for Service creation
    argument :enrollment_id, ID, required: false
    # Needed for Project creation
    argument :organization_id, ID, required: false
    # Needed for Funder/ProjectCoC/etc creation
    argument :project_id, ID, required: false
    # Raw form state as JSON
    argument :values, Types::JsonObject, required: false
    # Transformed HUD values as JSON
    argument :hud_values, Types::JsonObject, required: false
    # Whether warnings have been confirmed
    argument :confirmed, Boolean, required: false

    def apply_related_ids(record)
      case record
      when Hmis::Hud::Project
        record.organization_id = Hmis::Hud::Organization.viewable_by(current_user).find_by(id: organization_id)&.OrganizationID
      when Hmis::Hud::Funder, Hmis::Hud::ProjectCoc, Hmis::Hud::Inventory
        record.project_id = Hmis::Hud::Project.viewable_by(current_user).find_by(id: project_id)&.ProjectID
      when Hmis::Hud::HmisService
        record.enrollment_id = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: enrollment_id)&.EnrollmentID
        record.personal_id = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: enrollment_id)&.PersonalID
      end
      record
    end
  end
end
