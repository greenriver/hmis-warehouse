#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  class CeReferralCreate < CleanBaseMutation
    argument :opportunity_id, ID, required: true
    field :referral, Types::HmisSchema::CeReferral, null: false

    def resolve(opportunity_id:)
      opportunity = Hmis::Ce::Opportunity.viewable_by(current_user).find(opportunity_id)
      opportunity.transaction do
        instance = opportunity.workflow_template.instances.create!
        referral = opportunity.referrals.create!(workflow_instance: instance)
        referral.workflow_engine.start_workflow!
      end
      { referral: referral }
    end
  end
end
