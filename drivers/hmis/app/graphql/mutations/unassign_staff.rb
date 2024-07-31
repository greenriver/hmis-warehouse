#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class UnassignStaff < CleanBaseMutation
    argument :id, ID, required: true

    field :staff_assignment, Types::HmisSchema::StaffAssignment, null: true

    def resolve(id:)
      record = Hmis::StaffAssignment.find(id)

      access_denied! unless current_permission?(permission: :can_edit_enrollments, entity: record.household.project)

      record.destroy!

      {
        staff_assignment: record,
        errors: [],
      }
    end
  end
end
