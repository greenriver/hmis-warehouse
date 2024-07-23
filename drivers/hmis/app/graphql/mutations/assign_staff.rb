#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class AssignStaff < CleanBaseMutation
    argument :household_id, ID, required: true
    argument :assignment_type_id, ID, required: true
    argument :user_id, ID, required: true

    field :staff_assignment, Types::HmisSchema::StaffAssignment, null: true

    def resolve(household_id:, assignment_type_id:, user_id:)
      household = Hmis::Hud::Household.preload(:project).find_by(household_id: household_id, data_source_id: current_user.hmis_data_source_id)
      raise 'Not found' unless household

      access_denied! unless current_user.permissions_for?(household.project, :can_edit_enrollments)

      raise 'Staff Assignment not enabled' unless household.project.staff_assignments_enabled?

      assignment_type = Hmis::StaffAssignmentType.find(assignment_type_id)
      user = Hmis::User.find(user_id)

      existing = Hmis::StaffAssignment.where(
        staff_assignment_type: assignment_type,
        user: user,
        # todo @martha - ideally can just pass where(household: hh) but it's not working
        household_id: household.household_id,
        data_source_id: household.data_source_id,
      )
      errors = HmisErrors::Errors.new
      errors.add(:base, :invalid, message: "User #{user.name} is already assigned as #{assignment_type.name} for this household") if existing.exists?
      return { errors: errors } if errors.any?

      assignment = Hmis::StaffAssignment.new(
        household: household,
        user: user,
        staff_assignment_type: assignment_type,
      )

      assignment.save!
      { staff_assignment: assignment }
    end
  end
end
