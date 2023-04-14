###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class AddHouseholdMembersToEnrollment < BaseMutation
    argument :household_id, ID, required: true
    argument :entry_date, GraphQL::Types::ISO8601Date, required: true
    argument :household_members, [Types::HmisSchema::EnrollmentHouseholdMemberInput], required: true
    argument :confirmed, Boolean, required: false

    field :enrollments, [Types::HmisSchema::Enrollment], null: true

    def resolve(household_id:, entry_date:, household_members:, confirmed:)
      errors = HmisErrors::Errors.new
      existing_enrollments = Hmis::Hud::Enrollment.viewable_by(current_user).where(household_id: household_id)

      errors.add :household_id, :not_found unless existing_enrollments.exists?
      return { errors: errors } if errors.any?

      errors.add :household_id, :not_allowed unless current_user.permissions_for?(existing_enrollments.first, :can_edit_enrollments)
      return { errors: errors } if errors.any?

      has_hoh = existing_enrollments.heads_of_households.exists?
      errors.add :household_members, :invalid, full_message: 'Enrollment already has a Head of Household designated' if has_hoh && household_members.find { |hm| hm.relationship_to_ho_h == 1 }

      client_ids = household_members.map(&:id)
      errors.add :household_members, :invalid, full_message: 'Client is already a member of this household' if existing_enrollments.joins(:client).where(client: { id: client_ids }).exists?

      lookup = Hmis::Hud::Client.viewable_by(current_user).where(id: client_ids).pluck(:id, :personal_id).to_h
      errors.add :household_members, :not_found if lookup.keys.size != household_members.size
      return { errors: errors } if errors.any?

      project_id = existing_enrollments.first.project.project_id
      enrollments = household_members.map do |household_member|
        Hmis::Hud::Enrollment.new(
          data_source_id: hmis_user.data_source_id,
          user_id: hmis_user.user_id,
          personal_id: lookup[household_member.id.to_i],
          relationship_to_ho_h: household_member.relationship_to_ho_h,
          entry_date: entry_date,
          project_id: project_id,
          household_id: household_id,
        )
      end

      # Validate entry date
      validations = Hmis::Hud::Validators::EnrollmentValidator.validate_entry_date(enrollments.first)
      validations.reject!(&:warning?) if confirmed
      return { errors: validations } if validations.any?

      errors = []
      enrollments.each(&:valid?).each do |enrollment|
        errors += enrollment.errors.errors unless enrollment.errors.empty?
      end
      return { errors: errors } if errors.any?

      Hmis::Hud::Enrollment.transaction do
        enrollments.each(&:save_in_progress)
      end

      {
        enrollments: enrollments,
        errors: [],
      }
    end
  end
end
