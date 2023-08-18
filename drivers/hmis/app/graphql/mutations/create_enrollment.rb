###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  # NOT CURRENTLY IN USE. Enrollments are added via SubmitForm.utations
  class CreateEnrollment < BaseMutation
    argument :project_id, ID, required: true
    argument :entry_date, GraphQL::Types::ISO8601Date, required: true
    argument :household_members, [Types::HmisSchema::EnrollmentHouseholdMemberInput], required: true
    argument :confirmed, Boolean, required: false

    field :enrollments, [Types::HmisSchema::Enrollment], null: true

    def to_enrollments_params(project:, entry_date:, household_members:)
      result = []
      household_id = Hmis::Hud::Enrollment.generate_household_id
      lookup = Hmis::Hud::Client.where(id: household_members.map(&:id)).pluck(:id, :personal_id).to_h

      coc_codes = project.project_cocs.pluck(:coc_code).compact.uniq
      # This mutation is not currently in use, so just error if there are multiple cocs.
      # If we start using this again, we need to add enrollment_coc as an input to the mutation.
      raise 'multiple possible CoC codes' if coc_codes.length > 1
      raise 'no CoC codes' if coc_codes.empty?

      household_members.each do |household_member|
        result << {
          personal_id: lookup[household_member.id.to_i],
          relationship_to_ho_h: household_member.relationship_to_ho_h,
          entry_date: entry_date,
          project_id: project&.project_id,
          household_id: household_id,
          enrollment_coc: coc_codes.first,
        }
      end

      result
    end

    def resolve(project_id:, entry_date:, household_members:, confirmed: false)
      user = hmis_user
      errors = HmisErrors::Errors.new
      errors.add :relationship_to_ho_h, full_message: 'Exactly one client must be head of household' if household_members.select { |hm| hm.relationship_to_ho_h == 1 }.size != 1

      project = Hmis::Hud::Project.viewable_by(context[:current_user]).find_by(id: project_id)
      errors.add :project_id, :not_found unless project.present?
      return { errors: errors } if errors.any?

      errors.add :project_id, :not_allowed unless current_user.permissions_for?(project, :can_enroll_clients)
      return { errors: errors } if errors.any?

      enrollments = to_enrollments_params(project: project, entry_date: entry_date, household_members: household_members).map do |attrs|
        Hmis::Hud::Enrollment.new(
          user_id: user.user_id,
          data_source_id: user.data_source_id,
          **attrs,
        )
      end

      # Validate entry date
      validations = Hmis::Hud::Validators::EnrollmentValidator.validate_entry_date(enrollments.first)
      validations.reject!(&:warning?) if confirmed
      return { errors: validations } if validations.any?

      # FIXME: enrollment creation should happen in a transaction
      valid_enrollments = []
      enrollments.each do |enrollment|
        if enrollment.valid?
          enrollment.save_in_progress
          valid_enrollments << enrollment
        else
          errors.push(*enrollment.errors.errors)
        end
      end

      {
        enrollments: valid_enrollments,
        errors: errors,
      }
    end
  end
end
