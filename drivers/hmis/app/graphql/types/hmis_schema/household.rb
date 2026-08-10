###
# Copyright Green River Data Group, Inc.
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

    field :current_staff_assignments, [HmisSchema::StaffAssignment], null: false
    # historical paginated staff assignments. no longer used to fetch "current" staff assignments because of performance reasons, the currentStaffAssignments field is used instead.
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

    # Household members whose client is restricted and not visible to the user are omitted.
    # Members are all enrolled at the same project, so restriction is the only thing that can
    # differentiate them; the limited-details case is included so that users who can only see that
    # the enrollments exist still get the full membership.
    def household_clients
      # Needed when a single household is resolved directly; a no-op when the households field
      # already preloaded the page.
      current_user.policy_context.preload_enrollment_restrictions(enrollments.map(&:id))
      current_user.policy_context.preload_project_dependencies(enrollments.map(&:project_pk))

      enrollments.filter_map do |enrollment|
        policy = current_user.policy_for(enrollment, policy_type: :hmis_enrollment)
        next unless policy.can_view_details? || policy.can_view_limited?

        {
          relationship_to_ho_h: enrollment.relationship_to_ho_h,
          enrollment: enrollment,
        }
      end
    end

    # Full household size, including restricted clients the user may not see in household_clients.
    def household_size
      enrollments.map(&:personal_id).uniq.size
    end

    def assessments(**args)
      resolve_assessments(**args)
    end

    def current_staff_assignments
      assignments = load_ar_association(object, :staff_assignments)
      # Sort in-memory to avoid n+1. Equivalent of: order(created_at: :desc, id: :desc)
      assignments.to_a.sort_by { |sa| [-sa.created_at.to_i, -sa.id] }
    end

    # This field results in N+1 because it is paginated.
    # It is only used for displaying the staff assignment history for a particular household,
    # so 'is_currently_assigned: false' is always passed from the frontend.
    # When loading staff assignments on a *batch* of households, use the 'current_staff_assignments' field instead.
    def staff_assignments(is_currently_assigned: true)
      scope = object.staff_assignments.order(created_at: :desc, id: :desc)
      return scope if is_currently_assigned

      scope.only_deleted.order(created_at: :desc, deleted_at: :desc, id: :desc)
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

    private

    def enrollments
      load_ar_association(object, :enrollments)
    end
  end
end
