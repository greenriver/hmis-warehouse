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
      access_denied! unless policy_for(referral, policy_type: :ce_referral).can_assign_referral_tasks?

      swimlane_ids = participants.map(&:swimlane_id).uniq
      swimlanes = referral.workflow_instance.template.swimlanes.where(id: swimlane_ids)
      raise "Failed to assign to swimlanes #{swimlane_ids.join(', ')}, not all swimlanes found on template" unless swimlanes.size == swimlane_ids.size

      participants = filter_to_authorized_participants(participants, project)

      referral.with_lock do
        # Create a participant for each user in the input, if one doesn't already exist
        seen_participants = participants.map do |input|
          referral.participants.find_or_create_by!(input.to_h)
        end
        # Remove existing participants that are not included in the input
        referral.participants.where.not(id: seen_participants.map(&:id)).each(&:destroy!)

        # Reassign each active User Task based on updated referral participants
        referral.workflow_engine.active_steps.joins(:user_task).each do |step|
          referral.workflow_engine.assign_task!(step)
        end
      end

      { referral: referral.reload }
    end

    private

    # Users not in scope (inactive or lost access) are dropped and reported to Sentry.
    # This can happen if a user was previously assigned but is no longer active/authorized,
    # or lost access between loading the assignee pick list (ELIGIBLE_REFERRAL_STEP_ASSIGNMENT_USERS)
    # and submitting the mutation.
    def filter_to_authorized_participants(participants, project)
      user_ids = participants.map(&:user_id).map(&:to_i).to_set
      authorized_user_ids = Hmis::User.active.can_perform_any_referral_tasks_for(project).
        or(Hmis::User.can_perform_own_referral_tasks_for(project)).
        where(id: user_ids).pluck(:id).to_set

      missing_user_ids = user_ids - authorized_user_ids
      return participants if missing_user_ids.empty?

      msg = 'Referral assignment: some users were not in scope (inactive or lost access), removed from assignee list'
      Sentry.capture_message(msg, extra: { missing_user_ids: missing_user_ids.to_a, project_id: project.id })
      Rails.logger.warn(msg)

      participants.filter { |p| authorized_user_ids.include?(p.user_id.to_i) }
    end
  end
end
