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
      raise 'Not found' unless swimlanes.size == swimlane_ids.size

      user_ids = participants.map(&:user_id).uniq
      users = Hmis::User.where(id: user_ids)
      raise 'Not found' unless users.size == user_ids.size

      referral.with_lock do
        seen_participants = participants.map do |input|
          referral.participants.find_or_create_by!(input.to_h)
        end
        referral.participants.where.not(id: seen_participants.map(&:id)).each(&:destroy!)
      end

      { referral: referral.reload }
    end
  end
end
