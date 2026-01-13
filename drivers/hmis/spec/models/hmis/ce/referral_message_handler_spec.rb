###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::Ce::ReferralMessageHandler, type: :model do
  include_context 'ce spec helper'

  describe 'workflow with effects that update client eligibility' do
    it 'marks client dirty' do
      expect do
        engine.start_workflow!(user: hmis_user)
      end.to change { Hmis::Ce::ChangeMarker.where(trackable: destination_client).dirty.count }.from(0).to(1)

      Hmis::Ce::ChangeMarker.mark_processed(Hmis::Ce::ChangeMarker.all)

      expect do
        2.times do # complete the Client Acceptance and then Provider Acceptance steps
          current_step = engine.active_steps.sole
          engine.start_step!(current_step, user: hmis_user)
          engine.complete_step!(current_step, user: hmis_user, submitted_values: {}) # referral will be rejected
        end
      end.to change { Hmis::Ce::ChangeMarker.where(trackable: destination_client).dirty.count }.from(0).to(1)
    end
  end

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

  describe 'workflow with side effect that sets a decline reason' do
    let!(:decline_reason) { create(:ce_referral_decline_reason, data_source: ds1, key: 'user_error') }

    let!(:set_decline_reason_script_task) do
      create(
        :hmis_workflow_definition_script_task,
        template: workflow_template,
        name: 'Set Decline Reason',
        trigger_config: [
          {
            event: 'complete_step',
            message: 'set_referral_decline_reason',
            params: { 'decline_reason_field': 'decline_reason' },
          },
        ],
      )
    end

    before do
      # Modify the workflow from ce_spec_helper to set the decline reason before rejection
      acceptance_gateway.outflows.find_by(target_node: reject_referral).destroy!
      acceptance_gateway.connect_to!(set_decline_reason_script_task)
      set_decline_reason_script_task.connect_to!(reject_referral)

      engine.start_workflow!(user: hmis_user)

      # Complete the initial step to reach the Provider Acceptance step
      client_acceptance = engine.active_steps.sole
      engine.start_step!(client_acceptance, user: hmis_user)
      engine.complete_step!(client_acceptance, user: hmis_user, submitted_values: { 'client_accepted' => '1' })
    end

    it 'updates the referral decline reason from submitted values' do
      expect do
        provider_acceptance = engine.active_steps.sole
        engine.start_step!(provider_acceptance, user: hmis_user)
        engine.complete_step!(provider_acceptance, user: hmis_user, submitted_values: { 'client_accepted' => '0', 'decline_reason' => 'user_error' })
        referral.reload
      end.to change(referral, :decline_reason).to(decline_reason)
    end

    it 'does nothing if no decline reason is submitted' do
      expect do
        provider_acceptance = engine.active_steps.sole
        engine.start_step!(provider_acceptance, user: hmis_user)
        engine.complete_step!(provider_acceptance, user: hmis_user, submitted_values: { 'client_accepted' => '1' })
        referral.reload
      end.not_to change(referral, :decline_reason)
    end

    it 'clears the decline reason' do
      referral.update!(decline_reason: decline_reason)
      handler = described_class.new(referral)
      message = double('Message', type: 'clear_referral_decline_reason')

      expect do
        handler.call(message)
        referral.reload
      end.to change(referral, :decline_reason).to(nil)
    end
  end
end
