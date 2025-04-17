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
    argument :input, Types::HmisSchema::CeReferralInput, required: false, deprecation_reason: 'Use AssignReferralParticipants mutation instead'

    def resolve(opportunity_id:, client_id:)
      raise unless Hmis::Ce.configuration.enabled?

      opportunity = Hmis::Ce::Opportunity.viewable_by(current_user).find(opportunity_id)
      client = Hmis::Hud::Client.find(client_id) # Doesn't need to be viewable by the current user
      access_denied! unless client.data_source_id == current_user.hmis_data_source_id # Needs to be in the same data source, though

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

        referral.workflow_engine.start_workflow!(user: current_user)
      end
      { referral: referral }
    end
  end
end
