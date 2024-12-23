#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class CeReferralCreate < CleanBaseMutation
    argument :opportunity_id, ID, required: true
    argument :client_id, ID, required: true
    field :referral, Types::HmisSchema::CeReferral, null: false
    argument :input, Types::HmisSchema::CeReferralInput, required: true

    def resolve(opportunity_id:, client_id:, input:)
      opportunity = Hmis::Ce::Opportunity.viewable_by(current_user).find(opportunity_id)
      client = Hmis::Hud::Client.viewable_by(current_user).find(client_id)
      swimlanes = opportunity.template.swimlanes.index_by(&:id)
      opportunity.with_lock do
        # check for in-progress inside of lock for race cond
        # needs better error handling
        raise 'not available' unless opportunity.open?

        instance = opportunity.workflow_template.instances.create!
        referral = opportunity.referrals.create!(
          workflow_instance: instance,
          client: client,
        )
        input.participants.each do |participant|
          user = Hmis::User.viewable_by(current_user).find(participant.user_id)
          swimlane = swimlanes[participant.swimlane_id]
          referral.participants.create!(user: user, swimlane: swimlane)
        end
        referral.workflow_engine.start_workflow!
      end
      { referral: referral }
    end
  end
end
