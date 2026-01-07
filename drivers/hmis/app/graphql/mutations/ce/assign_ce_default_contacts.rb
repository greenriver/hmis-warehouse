###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  module Ce
    class AssignCeDefaultContacts < Mutations::CleanBaseMutation
      argument :input, Types::HmisSchema::CeDefaultContactsInput, required: true

      field :default_contacts, [Types::HmisSchema::CeDefaultContact], null: false

      def resolve(input:)
        if input.project_id.present?
          owner = Hmis::Hud::Project.viewable_by(current_user).find(input.project_id)
          access_denied! unless policy_for(owner, policy_type: :hmis_project).can_manage_ce_default_contacts?
        else
          # If no project_id, it's a global assignment. Owner is the current user's HMIS data source
          owner = current_user.hmis_data_source
          access_denied! unless policy_for(GrdaWarehouse::DataSource, policy_type: :ce_admin).can_manage_contacts?
        end

        seen_assignment_ids = []
        swimlane_ids = input.contacts.map(&:swimlane_id).uniq
        swimlanes = Hmis::WorkflowDefinition::Swimlane.where(id: swimlane_ids).index_by(&:id)

        user_ids = input.contacts.flat_map(&:user_ids).uniq
        users = Hmis::User.where(id: user_ids).index_by(&:id)

        # Process each swimlane-to-users mapping
        input.contacts.each do |contact_input|
          swimlane = swimlanes[contact_input.swimlane_id.to_i]

          contact_input.user_ids.each do |user_id|
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

        # Return all current assignments for this owner and the provided swimlanes
        assignments = Hmis::Ce::DefaultSwimlaneAssignment.where(owner: owner, swimlane_id: swimlane_ids)

        { default_contacts: assignments }
      end
    end
  end
end
