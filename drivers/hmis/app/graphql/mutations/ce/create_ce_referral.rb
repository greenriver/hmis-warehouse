###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class Ce::CreateCeReferral < CleanBaseMutation
    argument :opportunity_id, ID, required: true
    argument :client_id, ID, required: true
    field :referral, Types::HmisSchema::CeReferral, null: false
    argument :input, Types::HmisSchema::CeReferralInput, required: true

    def resolve(opportunity_id:, client_id:, input:)
      raise unless Hmis::Ce.configuration.enabled?

      opportunity = Hmis::Ce::Opportunity.viewable_by(current_user).find(opportunity_id)
      client = Hmis::Hud::Client.find(client_id) # Doesn't need to be viewable by the current user
      swimlanes = opportunity.workflow_template.swimlanes.index_by(&:id).stringify_keys
      referral = nil
      opportunity.with_lock do
        # check for in-progress inside of lock for race cond
        # needs better error handling
        raise 'not available' unless opportunity.open?

        instance = opportunity.workflow_template.instances.create!
        referral = opportunity.referrals.create!(
          workflow_instance: instance,
          referred_by: current_user,
          client: client,
        )
        input.participants.each do |participant|
          # TBD: should there be a restriction on what users are visible/can be assigned?
          user = Hmis::User.find(participant.user_id)
          swimlane = swimlanes[participant.swimlane_id]
          referral.participants.create!(user: user, swimlane: swimlane)
        end
        referral.workflow_engine.start_workflow!(user: current_user)
      end
      { referral: referral }
    end
  end
end
