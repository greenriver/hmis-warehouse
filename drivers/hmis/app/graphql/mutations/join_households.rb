###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class JoinHouseholds < BaseMutation
    argument :receiving_household_id, ID, required: true
    argument :joining_enrollment_inputs, [Types::HmisSchema::JoiningEnrollmentInput], required: true

    field :receiving_household, Types::HmisSchema::Household, null: false
    field :donor_household, Types::HmisSchema::Household, null: true # For frontend expediency, also return the donor household, if there are any remaining members

    def resolve(receiving_household_id:, joining_enrollment_inputs:)
      receiving_enrollments = Hmis::Hud::Enrollment.
        viewable_by(current_user).
        includes(:project).
        where(household_id: receiving_household_id)
      access_denied! if receiving_enrollments.empty?

      receiving = receiving_enrollments.find { |e| e.relationship_to_hoh == 1 } || receiving_enrollments.first

      receiving_project = receiving_enrollments.map(&:project).uniq.sole
      access_denied! unless current_permission?(permission: :can_split_households, entity: receiving_project)

      map_enrollment_id_to_relationship = joining_enrollment_inputs.map { |e| [e.enrollment_id, e.relationship_to_hoh] }.to_h

      joining_enrollment_ids = map_enrollment_id_to_relationship.keys
      joining_enrollments = Hmis::Hud::Enrollment.
        joins(:project).
        viewable_by(current_user).
        where(id: joining_enrollment_ids)
      access_denied! unless joining_enrollments.count == joining_enrollment_inputs.count

      raise 'Cannot merge enrollments from another project' unless joining_enrollments.pluck(:project_pk).uniq.sole == receiving_project.id

      donor_household_id = joining_enrollments.map(&:household_id).uniq.sole
      remaining_enrollments = Hmis::Hud::Enrollment.
        where(household_id: donor_household_id).
        where.not(id: joining_enrollment_ids)
      remaining_hoh = remaining_enrollments.any? { |enrollment| enrollment.relationship_to_hoh == 1 }
      raise 'This operation would leave behind a household with no HoH, which is not allowed' unless remaining_enrollments.empty? || remaining_hoh

      Hmis::Hud::Enrollment.transaction do
        joining_enrollments.each do |enrollment|
          enrollment.update!(
            household_id: receiving_household_id,
            relationship_to_hoh: map_enrollment_id_to_relationship[enrollment.id.to_s],
          )
        end

        # todo @martha - update the unit, if necessary
      end

      receiving.reload
      donor_household = remaining_enrollments.first&.household
      {
        receiving_household: receiving.household,
        donor_household: donor_household,
      }
    end
  end
end
