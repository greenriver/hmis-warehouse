###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::Ce::ReferralMessageHandler, type: :model do
  include_context 'ce spec helper'

  describe 'workflow with side effect that adds a custom status' do
    let!(:custom_status) { create(:hmis_ce_custom_referral_status, data_source: ds1) }

    let!(:client_acceptance_task) do
      # Modify task set up in 'ce spec helper' to have a side effect that sets custom status
      create(
        :hmis_workflow_definition_user_task,
        template: workflow_template,
        name: 'Client Acceptance',
        swimlane: case_manager_swimlane,
        trigger_config: [
          {
            event: 'complete_step',
            message: 'set_custom_referral_status',
            params: { 'custom_status_key': custom_status.key },
          },
        ],
      )
    end

    before do
      engine.start_workflow!(user: hmis_user)
    end

    it 'updates the referral custom status' do
      expect do
        client_acceptance = engine.active_steps.sole
        engine.start_step!(client_acceptance, user: hmis_user)
        engine.complete_step!(client_acceptance, user: hmis_user, submitted_values: {})
        referral.reload
      end.to change(referral, :custom_status).from(nil).to(custom_status)
    end
  end
end
