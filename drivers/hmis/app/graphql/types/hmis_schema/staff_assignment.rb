###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::StaffAssignment < Types::BaseObject
    description 'Staff Assignment'
    field :id, ID, null: false
    field :user, Application::User, null: false
    field :household, HmisSchema::Household, null: false
    field :staff_assignment_type, String, null: false
    field :assigned_at, GraphQL::Types::ISO8601Date, null: false
    field :unassigned_at, GraphQL::Types::ISO8601Date, null: true

    def user
      load_ar_association(object, :user)
    end

    def household
      load_ar_association(object, :household)
    end

    def staff_assignment_type
      load_ar_association(object, :staff_assignment_type)&.name
    end

    def assigned_at
      object.created_at
    end

    def unassigned_at
      object.deleted_at
    end
  end
end
