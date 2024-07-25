###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::AssignStaffInput < Types::BaseInputObject
    description 'Input for AssignStaff mutation'
    argument :household_id, ID, required: true, description: 'Household ID'
    argument :assignment_type_id, ID, required: true, description: 'Assignment type ID'
    argument :user_id, ID, required: true, description: 'User ID'
  end
end
