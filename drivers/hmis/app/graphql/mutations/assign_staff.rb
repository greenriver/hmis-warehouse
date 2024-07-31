#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class AssignStaff < CleanBaseMutation
    argument :input, Types::HmisSchema::AssignStaffInput, required: true

    field :staff_assignment, Types::HmisSchema::StaffAssignment, null: true

    def resolve(input:)
      household = Hmis::Hud::Household.viewable_by(current_user).find_by(household_id: input.household_id, data_source_id: current_user.hmis_data_source_id)
      raise 'Not found' unless household

      access_denied! unless current_user.permissions_for?(household.project, :can_edit_enrollments)

      raise 'Staff Assignment not enabled' unless household.project.staff_assignments_enabled?

      assignment_relationship = Hmis::StaffAssignmentRelationship.find(input.assignment_relationship_id)
      user = Hmis::User.can_edit_enrollments_for(household.project).find(input.user_id)

      existing = Hmis::StaffAssignment.where(
        staff_assignment_relationship: assignment_relationship,
        user: user,
        household_id: household.household_id,
        data_source_id: household.data_source_id,
      )
      errors = HmisErrors::Errors.new
      # Locking on assignment_relationship looks odd but we can't use user (different db) and household is a view
      assignment_relationship.with_lock do
        errors.add(:user_id, :invalid, message: "#{user.name} is already assigned as #{assignment_relationship.name} for this household") if existing.exists?
        return { errors: errors } if errors.any?

        assignment = Hmis::StaffAssignment.create!(
          household: household,
          user: user,
          staff_assignment_relationship: assignment_relationship,
        )

        { staff_assignment: assignment }
      end
    end
  end
end
