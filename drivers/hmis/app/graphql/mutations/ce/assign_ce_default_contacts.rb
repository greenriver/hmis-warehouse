###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  module Ce
    class AssignCeDefaultContacts < Mutations::CleanBaseMutation
      argument :input, Types::HmisSchema::CeDefaultSwimlaneAssignmentInput, required: true

      field :default_swimlane_assignments, [Types::HmisSchema::CeDefaultSwimlaneAssignment], null: false

      def resolve(input:)
        if input.project_id.present?
          owner = Hmis::Hud::Project.viewable_by(current_user).find(input.project_id)
          access_denied! unless policy_for(owner, policy_type: :hmis_project).can_manage_ce_default_contacts?
        else
          # If no project_id, it's a global assignment. Owner is the current user's HMIS data source
          owner = current_user.hmis_data_source
          access_denied! unless current_user.can_administrate_coordinated_entry? # todo @martha - consider making a global policy
        end

        # todo @martha - validation errors
        # errors = HmisErrors::Errors.new
        seen_assignment_ids = []
        swimlane_ids = input.assignments.map(&:swimlane_id).uniq
        swimlanes = Hmis::WorkflowDefinition::Swimlane.where(id: swimlane_ids).index_by(&:id)

        user_ids = input.assignments.flat_map(&:user_ids).uniq
        users = Hmis::User.where(id: user_ids).index_by(&:id)

        # Process each swimlane-to-users mapping
        input.assignments.each do |assignment_input|
          swimlane = swimlanes[assignment_input.swimlane_id.to_i]

          assignment_input.user_ids.each do |user_id|
            user = users[user_id.to_i]

            # Find or create the assignment
            assignment = Hmis::Ce::DefaultSwimlaneAssignment.find_or_create_by!(
              user: user,
              swimlane: swimlane,
              owner: owner,
            )

            seen_assignment_ids << assignment.id
          end
        end

        # Remove existing assignments for these swimlanes that are not included in the input
        Hmis::Ce::DefaultSwimlaneAssignment.
          where(owner: owner, swimlane_id: swimlane_ids).
          where.not(id: seen_assignment_ids).
          each(&:destroy!)

        # Return all current assignments for these swimlanes
        assignments = Hmis::Ce::DefaultSwimlaneAssignment.where(owner: owner, swimlane_id: swimlane_ids)

        { default_swimlane_assignments: assignments }
      end
    end
  end
end
