###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Household < Types::BaseObject
    include Types::HmisSchema::HasAssessments

    field :id, ID, null: false, method: :household_id
    field :short_id, ID, null: false
    field :household_clients, [HmisSchema::HouseholdClient], null: false
    field :household_size, Int, null: false
    field :staff_assignments, HmisSchema::StaffAssignment.page_type, null: true do
      argument :is_currently_assigned, Boolean, required: false
    end
    field :any_in_progress, Boolean, null: false
    field :earliest_entry_date, GraphQL::Types::ISO8601Date, null: false
    field :latest_exit_date, GraphQL::Types::ISO8601Date, null: true

    assessments_field filter_args: { omit: [:project, :project_type], type_name: 'AssessmentsForHousehold' }

    # object is a Hmis::Hud::Household

    available_filter_options do
      arg :status, [HmisSchema::Enums::EnrollmentFilterOptionStatus]
      arg :open_on_date, GraphQL::Types::ISO8601Date
      arg :hoh_age_range, HmisSchema::Enums::AgeRange
      arg :search_term, String
      arg :assigned_staff, ID
    end

    def household_clients
      enrollments.map do |enrollment|
        {
          relationship_to_ho_h: enrollment.relationship_to_ho_h,
          enrollment: enrollment,
        }
      end
    end

    def household_size
      enrollments.map(&:personal_id).uniq.size
    end

    def enrollments
      load_ar_association(object, :enrollments)
    end

    def assessments(**args)
      resolve_assessments(**args)
    end

    def staff_assignments(is_currently_assigned: true)
      # There's no current use case for returning all (both currently assigned and formerly assigned)
      # in the same query, but we could update this to support that use case if it arises.
      scope = load_ar_association(object, :staff_assignments).order(created_at: :desc, id: :desc)
      if is_currently_assigned
        scope
      else
        scope.with_deleted.where.not(deleted_at: nil).order(created_at: :desc, deleted_at: :desc, id: :desc)
      end
    end

    def any_in_progress
      object.any_wip?
    end

    def earliest_entry_date
      object.earliest_entry
    end

    def latest_exit_date
      object.latest_exit
    end
  end
end
