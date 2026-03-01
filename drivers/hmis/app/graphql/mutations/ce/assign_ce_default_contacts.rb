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
        # Validate the input. Validation depends on whether this is a project or global assignment
        if input.project_id.present?
          owner = validate_project(input)
          swimlane_ids = validate_swimlanes(input, project: owner)
          validate_users(input, project: owner)
        else
          # If no project_id is passed, owner is the current user's HMIS data source
          owner = validate_data_source
          swimlane_ids = validate_swimlanes(input)
          validate_users(input, data_source: owner)
        end

        # Expect the input to contain *all* default contacts for the owner and the given swimlanes.
        # If input is partial, the mutation deletes existing assignments that are not in the input.

        # Load all existing assignments for this owner and swimlanes
        existing_assignments = Hmis::Ce::DefaultSwimlaneAssignment.
          where(owner: owner, swimlane_id: swimlane_ids).
          index_by { |a| [a.user_id, a.swimlane_id] }

        # Determine which assignments should exist, based on the input.
        # keys are [user_id, swimlane_id]
        desired_keys = input.contacts.flat_map do |contact_input|
          contact_input.user_ids.map do |user_id|
            [user_id.to_i, contact_input.swimlane_id.to_i]
          end
        end.to_set

        # Build new assignments for keys that don't exist yet
        to_create = desired_keys.reject { |key| existing_assignments[key] }.map do |(user_id, swimlane_id)|
          Hmis::Ce::DefaultSwimlaneAssignment.new(
            swimlane_id: swimlane_id,
            user_id: user_id,
            owner: owner,
          )
        end
        # Build list of assignments for removal: those that exist but aren't in the input
        to_remove = existing_assignments.reject { |key, _| desired_keys.include?(key) }.values

        # In a transaction, create and destroy assignments
        Hmis::Ce::DefaultSwimlaneAssignment.transaction do
          Hmis::Ce::DefaultSwimlaneAssignment.import!(to_create)

          Hmis::Ce::DefaultSwimlaneAssignment.where(id: to_remove.map(&:id)).each(&:destroy!)
        end

        # Return all current assignments for this owner and the provided swimlanes
        { default_contacts: Hmis::Ce::DefaultSwimlaneAssignment.where(owner: owner, swimlane_id: swimlane_ids) }
      end

      private

      def validate_project(input)
        project = Hmis::Hud::Project.viewable_by(current_user).find(input.project_id)
        access_denied! unless policy_for(project, policy_type: :hmis_project).can_manage_ce_default_contacts?

        project
      end

      def validate_data_source
        data_source = GrdaWarehouse::DataSource.find(current_user.hmis_data_source_id)
        access_denied! unless policy_for(Hmis::Ce::Referral, policy_type: :ce_referral).can_manage_ce_default_contacts?

        data_source
      end

      def validate_swimlanes(input, project: nil)
        swimlane_ids = input.contacts.map(&:swimlane_id).uniq
        template_scope = Hmis::WorkflowDefinition::Template.ce.published.viewable_by(current_user)

        # If project ID is provided, only include swimlanes that are referenced by templates used in that project
        template_scope = template_scope.used_in_projects([project.id]) if project.present?

        swimlanes = Hmis::WorkflowDefinition::Swimlane.
          where(id: swimlane_ids).
          joins(:template).
          merge(template_scope)

        raise "Swimlane(s) not found: #{swimlane_ids.join(', ')}" unless swimlanes.size == swimlane_ids.size

        swimlane_ids
      end

      def validate_users(input, project: nil, data_source: nil)
        user_ids = input.contacts.map(&:user_ids).flatten.uniq
        users = Hmis::User.where(id: user_ids)
        raise "User(s) not found: #{user_ids.join(', ')}" unless users.size == user_ids.size

        if project.present?
          users.each do |user|
            user.hmis_data_source_id = project.data_source_id
            raise "User #{user.id} not authorized" unless user.policy_for(project, policy_type: :hmis_project).can_perform_referral_tasks?
          end
        else
          users.each do |user|
            user.hmis_data_source_id = data_source.id
            raise "User #{user.id} not authorized" unless user.policy_for(Hmis::Ce::Referral, policy_type: :ce_referral).can_perform_referral_tasks?
          end
        end
      end
    end
  end
end
