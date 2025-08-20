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
      end.to change(referral, :custom_status).to(custom_status)
    end
  end

  describe 'workflow with side effect that disables another step' do
    # Add an optional task that becomes available in parallel with provider_acceptance_task.
    # When completed, it loops the workflow back to client_acceptance_task, and disables provider_acceptance_task.
    #           client_acceptance_task  <--
    #          /                     \    |
    # provider_acceptance_task     optional_task

    let!(:optional_task) do
      create(
        :hmis_workflow_definition_user_task,
        template: workflow_template,
        name: 'Optional Task',
        swimlane: case_manager_swimlane,
        trigger_config: [
          {
            event: 'complete_step',
            message: 'disable_step',
            params: { 'node_id': provider_acceptance_task.id },
          },
        ],
      )
    end

    before do
      client_acceptance_task.connect_to!(optional_task)
      optional_task.connect_to!(client_acceptance_task)

      engine.start_workflow!(user: hmis_user)

      # Complete the first step, which should make optional_task available
      client_acceptance = engine.active_steps.sole
      engine.start_step!(client_acceptance, user: hmis_user)
      engine.complete_step!(client_acceptance, user: hmis_user, submitted_values: {})
    end

    it 'disables the specified step when it is available' do
      expect(engine.active_steps.count).to eq(2)
      expect(engine.active_steps.pluck(:node_id)).to include(optional_task.id, provider_acceptance_task.id)

      optional_step = engine.active_steps.find_by(node_id: optional_task.id)
      engine.start_step!(optional_step, user: hmis_user)
      engine.complete_step!(optional_step, user: hmis_user, submitted_values: {})

      provider_acceptance = referral.steps.find_by(node_id: provider_acceptance_task.id)
      expect(provider_acceptance.status).to eq('unavailable')
    end

    it 'disables the specified step when it has already been started' do
      provider_acceptance = engine.active_steps.find_by(node_id: provider_acceptance_task.id)
      engine.start_step!(provider_acceptance, user: hmis_user)

      optional_step = engine.active_steps.find_by(node_id: optional_task.id)
      engine.start_step!(optional_step, user: hmis_user)
      engine.complete_step!(optional_step, user: hmis_user, submitted_values: {})

      provider_acceptance.reload
      expect(provider_acceptance.status).to eq('unavailable')
    end
  end
end
