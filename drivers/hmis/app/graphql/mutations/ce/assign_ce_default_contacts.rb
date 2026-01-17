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
        # Upfront, load all swimlanes and users from the input to confirm they are valid inputs (which depends on the owner)
        swimlane_ids = input.contacts.map(&:swimlane_id).uniq
        swimlanes = Hmis::WorkflowDefinition::Swimlane.where(id: swimlane_ids)
        user_ids = input.contacts.map(&:user_ids).flatten.uniq
        users = Hmis::User.where(id: user_ids)

        if input.project_id.present?
          owner = Hmis::Hud::Project.viewable_by(current_user).find(input.project_id)
          access_denied! unless policy_for(owner, policy_type: :hmis_project).can_manage_ce_default_contacts?

          swimlanes = swimlanes.joins(:template).
            merge(Hmis::WorkflowDefinition::Template.ce.published.viewable_by(current_user).used_in_projects([owner.id]))
          users = users.can_perform_referral_tasks_in_project(owner) # todo @martha - consider adding policy-based checks here?
        else
          # If no project_id, it's a global assignment. Owner is the current user's HMIS data source
          owner = GrdaWarehouse::DataSource.find(current_user.hmis_data_source_id)
          access_denied! unless policy_for(owner, policy_type: :ce_admin).can_manage_ce_default_contacts?

          # todo @martha - needs spec check
          users = users.can_be_global_ce_default_contact(owner.id)
        end

        raise "Swimlane(s) not found: #{swimlane_ids.join(', ')}" unless swimlanes.size == swimlane_ids.size
        raise "User(s) not found: #{user_ids.join(', ')}" unless users.size == user_ids.size

        # Load all existing assignments for this owner and swimlanes
        existing_assignments = Hmis::Ce::DefaultSwimlaneAssignment.
          where(owner: owner, swimlane_id: swimlane_ids).
          index_by { |a| [a.user_id, a.swimlane_id] }

        # Determine which assignments should exist, based on the input
        desired_keys = Set.new # keys are [user_id, swimlane_id]
        to_create = []

        input.contacts.each do |contact_input|
          swimlane_id = contact_input.swimlane_id.to_i

          contact_input.user_ids.each do |user_id|
            user_id = user_id.to_i
            key = [user_id, swimlane_id]
            desired_keys << key

            # If this assignment doesn't exist yet, add it to to_create
            next if existing_assignments[key]

            to_create << Hmis::Ce::DefaultSwimlaneAssignment.new(
              swimlane_id: swimlane_id,
              user_id: user_id,
              owner: owner,
            )
          end
        end

        # Bulk create new assignments
        Hmis::Ce::DefaultSwimlaneAssignment.import!(to_create) unless to_create.empty?

        # Determine which existing assignments to remove
        assignments_to_remove = existing_assignments.reject { |key, _| desired_keys.include?(key) }.values

        # Bulk delete removed assignments
        if assignments_to_remove.any?
          Hmis::Ce::DefaultSwimlaneAssignment.
            where(id: assignments_to_remove.map(&:id)).
            destroy_all
        end

        # Return all current assignments for this owner and the provided swimlanes
        assignments = Hmis::Ce::DefaultSwimlaneAssignment.where(owner: owner, swimlane_id: swimlane_ids)

        { default_contacts: assignments }
      end
    end
  end
end
