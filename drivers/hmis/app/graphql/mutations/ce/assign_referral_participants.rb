###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class Ce::AssignReferralParticipants < CleanBaseMutation
    argument :referral_id, ID, required: true
    argument :participants, [Types::HmisSchema::CeReferralParticipantInput], required: true

    field :referral, Types::HmisSchema::CeReferral, null: false

    def resolve(referral_id:, participants:)
      raise unless Hmis::Ce.configuration.enabled?

      referral = Hmis::Ce::Referral.viewable_by(current_user).find(referral_id)
      project = referral.target_project
      access_denied! unless policy_for(referral, policy_class: Hmis::AuthPolicies::CeReferralPolicy).can_assign_referral_tasks?

      swimlane_ids = participants.map(&:swimlane_id).uniq
      swimlanes = referral.workflow_instance.template.swimlanes.where(id: swimlane_ids)
      raise 'Not found' unless swimlanes.size == swimlane_ids.size

      # Verify that the given users have permission to perform referral tasks in this project
      user_ids = participants.map(&:user_id).uniq
      users = Hmis::User.can_perform_any_referral_tasks_for(project).
        or(Hmis::User.can_perform_own_referral_tasks_for(project)).
        where(id: user_ids)
      raise 'Not found' unless users.size == user_ids.size

      referral.with_lock do
        # Create a participant for each user in the input, if one doesn't already exist
        seen_participants = participants.map do |input|
          referral.participants.find_or_create_by!(input.to_h)
        end
        # Remove existing participants that are not included in the input
        referral.participants.where.not(id: seen_participants.map(&:id)).each(&:destroy!)

        # If the referral has any active steps, the engine should assign them out to their correct participants.
        # (Existing assignments won't be deleted)
        referral.workflow_engine.active_steps.each do |step|
          referral.workflow_engine.assign_task!(step)
        end
      end

      { referral: referral.reload }
    end
  end
end
