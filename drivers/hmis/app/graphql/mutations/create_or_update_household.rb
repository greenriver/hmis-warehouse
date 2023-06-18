###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class CreateOrUpdateHousehold < BaseMutation
    include ::Hmis::Concerns::HmisArelHelper

    argument :household_id, ID, required: false, description: 'If omitted, a new household will be created'
    argument :project_id, ID, required: true
    argument :entry_date, GraphQL::Types::ISO8601Date, required: true
    argument :client_id, ID, required: true
    argument :relationship_to_hoh, Types::HmisSchema::Enums::Hud::RelationshipToHoH, required: true
    argument :confirmed, Boolean, required: false

    field :household, Types::HmisSchema::Household, null: true

    def resolve(project_id:, entry_date:, client_id:, relationship_to_hoh:, household_id: nil, confirmed: false)
      errors = HmisErrors::Errors.new
      is_hoh = relationship_to_hoh == 1

      client = Hmis::Hud::Client.viewable_by(current_user).find(client_id)
      project = Hmis::Hud::Project.viewable_by(current_user).find(project_id)

      if household_id.present?
        existing_enrollments = Hmis::Hud::Enrollment.viewable_by(current_user).where(household_id: household_id)
        raise HmisErrors::ApiError, 'Household ID not found' unless existing_enrollments.exists?
        raise HmisErrors::ApiError, 'Access denied' unless current_user.permissions_for?(existing_enrollments.first, :can_edit_enrollments)
        raise HmisErrors::ApiError, 'Client is already a member of this household' if existing_enrollments.joins(:client).where(c_t[:id].eq(client_id)).exists?
        raise HmisErrors::ApiError, 'Mismatched Project ID' if existing_enrollments.first.project.id != project_id

        has_hoh = existing_enrollments.heads_of_households.exists?
        errors.add :relationship_to_hoh, :invalid, full_message: 'Household already has a Head of Household' if has_hoh && is_hoh
      else
        raise HmisErrors::ApiError, 'Access denied' unless current_user.permissions_for?(project, :can_enroll_clients)

        errors.add :relationship_to_hoh, :invalid, full_message: 'Client must be the Head of Household' unless is_hoh
      end

      return { errors: errors } if errors.any?

      household_id ||= Hmis::Hud::Base.generate_uuid
      enrollment = Hmis::Hud::Enrollment.new(
        data_source_id: hmis_user.data_source_id,
        user_id: hmis_user.user_id,
        personal_id: client.personal_id,
        relationship_to_hoh: relationship_to_hoh,
        entry_date: entry_date,
        project_id: project.project_id,
        household_id: household_id,
      )

      # Validate entry date
      validations = Hmis::Hud::Validators::EnrollmentValidator.validate_entry_date(enrollment)
      validations.reject!(&:warning?) if confirmed
      return { errors: validations } if validations.any?

      # Validate enrollment
      enrollment.valid?
      return { errors: enrollment.errors.errors } if enrollment.errors.any?

      enrollment.save_in_progress
      household = Hmis::Hud::Household.find_by(household_id: household_id, data_source_id: hmis_user.data_source_id)

      {
        household: household,
        errors: [],
      }
    end
  end
end
