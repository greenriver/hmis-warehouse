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

      swimlane_ids = participants.map(&:swimlane_id).uniq
      swimlanes = referral.workflow_instance.template.swimlanes.where(id: swimlane_ids)
      raise 'Not found' unless swimlanes.length == swimlane_ids.length

      user_ids = participants.map(&:user_id).uniq
      users = Hmis::User.where(id: user_ids)
      raise 'Not found' unless users.length == user_ids.length

      existing_participants = referral.participants

      input_participants = participants.map do |participant|
        Hmis::Ce::ReferralParticipant.new(referral: referral, user_id: participant.user_id.to_s, swimlane_id: participant.swimlane_id.to_s)
      end

      # Array subtraction uses ActiveRecord equality, which doesn't check ID unless it is explicitly told to.
      # So this works even though existing_participants are persisted (non-nil IDs) and input_participants aren't.
      to_add = input_participants - existing_participants
      to_remove = existing_participants - input_participants

      Hmis::Ce::ReferralParticipant.transaction do
        Hmis::Ce::ReferralParticipant.import!(to_add) if to_add.any?
        to_remove.each(&:destroy!)
      end

      { referral: referral.reload }
    end
  end
end
