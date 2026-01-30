###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class Ce::CreateCeReferral < CleanBaseMutation
    argument :opportunity_id, ID, required: true
    argument :client_id, ID, required: false
    argument :source_enrollment_id, ID, required: false
    field :referral, Types::HmisSchema::CeReferral, null: true # nullable in case of errors

    def resolve(opportunity_id:, client_id: nil, source_enrollment_id: nil)
      raise unless Hmis::Ce.configuration.enabled?

      opportunity = Hmis::Ce::Opportunity.viewable_by(current_user).find(opportunity_id)

      # client/enrollment don't need to be viewable by the current user
      if source_enrollment_id
        source_enrollment = Hmis::Hud::Enrollment.find(source_enrollment_id)
        client = source_enrollment.client
      elsif client_id
        client = Hmis::Hud::Client.find(client_id)
      else
        raise 'Either a client_id or a source_enrollment_id is required'
      end

      access_denied! unless policy_for(opportunity, policy_type: :ce_opportunity).can_create_referral?(client: client)

      referral = nil
      opportunity.with_lock do
        errors = HmisErrors::Errors.new

        # check for in-progress inside of lock to avoid race condition
        unless opportunity.open?
          errors.add :base, :invalid, full_message: 'This unit is not available. Refresh the page to view the latest availability.'
          return { errors: errors }
        end

        workflow_template = opportunity.unit_group.workflow_template
        raise "No workflow template configured for this unit group. Opportunity: #{opportunity.id}" unless workflow_template

        instance = workflow_template.instances.create!
        referral = opportunity.referrals.originated_from_waitlist.create!(
          workflow_instance: instance,
          referred_by: current_user,
          client: client,
          source_enrollment: source_enrollment,
        )

        referral.create_default_participants!
        referral.workflow_engine.start_workflow!(user: current_user)
      end
      { referral: referral }
    end
  end
end
