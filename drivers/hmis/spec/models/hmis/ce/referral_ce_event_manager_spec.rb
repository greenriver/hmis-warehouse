###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::Ce::ReferralCeEventManager, type: :model do
  include_context 'ce spec helper'

  let!(:source_enrollment) { create :hmis_hud_enrollment, data_source: ds1, client: client }

  let!(:referral) do
    create(
      :hmis_ce_referral,
      opportunity: opportunity,
      workflow_instance: workflow_instance,
      client: client,
      referred_by: hmis_user,
      source_enrollment: source_enrollment,
      status: 'initialized',
    )
  end

  # Build on the workflow template set out in ce_spec_helper to incorporate CE event creation and outcomes:
  let!(:ce_creation_task) do # this wouldn't be its own user-facing task in a real workflow
    create(
      :hmis_workflow_definition_user_task,
      template: workflow_template,
      name: 'Create CE event',
      swimlane: case_manager_swimlane,
      trigger_config: [
        {
          event: 'complete_step',
          message: 'create_ce_event',
        },
      ],
    )
  end

  let(:accept_referral) do
    create(
      :hmis_workflow_definition_end_event,
      template: workflow_template,
      name: 'accept referral',
      trigger_config: [
        {
          event: 'end_workflow',
          message: Hmis::Ce::ReferralMessageHandler::ACCEPT_REFERRAL_MESSAGE,
        },
        {
          event: 'end_workflow',
          message: 'set_ce_event_result',
          params: { referral_result: '1' },
        },
      ],
    )
  end

  let(:client_acceptance_gateway) do
    create(
      :hmis_workflow_definition_gateway,
      template: workflow_template,
      gateway_type: 'exclusive',
      name: 'client acceptance gw',
    )
  end

  let(:client_rejects_referral) do
    create(
      :hmis_workflow_definition_end_event,
      template: workflow_template,
      name: 'client reject',
      trigger_config: [
        {
          event: 'end_workflow',
          message: Hmis::Ce::ReferralMessageHandler::REJECT_REFERRAL_MESSAGE,
        },
        {
          event: 'end_workflow',
          message: 'set_ce_event_result',
          params: { referral_result: '2' },
        },
      ],
    )
  end

  let(:provider_acceptance_gateway) do
    create(
      :hmis_workflow_definition_gateway,
      template: workflow_template,
      gateway_type: 'exclusive',
      name: 'provider acceptance gw',
    )
  end

  let(:provider_rejects_referral) do
    create(
      :hmis_workflow_definition_end_event,
      template: workflow_template,
      name: 'provider reject',
      trigger_config: [
        {
          event: 'end_workflow',
          message: Hmis::Ce::ReferralMessageHandler::REJECT_REFERRAL_MESSAGE,
        },
        {
          event: 'end_workflow',
          message: 'set_ce_event_result',
          params: { referral_result: '3' },
        },
      ],
    )
  end

  before do
    Hmis::WorkflowDefinition::Flow.destroy_all

    start_event.connect_to!(ce_creation_task)
    ce_creation_task.connect_to!(client_acceptance_task)

    client_acceptance_task.connect_to!(client_acceptance_gateway)
    client_acceptance_gateway.connect_to!(client_rejects_referral, condition: 'client_accepted = 0')
    client_acceptance_gateway.connect_to!(provider_acceptance_task)

    provider_acceptance_task.connect_to!(provider_acceptance_gateway)
    provider_acceptance_gateway.connect_to!(provider_rejects_referral, condition: 'provider_accepted = 0')
    provider_acceptance_gateway.connect_to!(accept_referral)

    engine.start_workflow!(user: hmis_user)
  end

  def submit_current_step(submitted_values = {})
    current_step = engine.active_steps.sole
    engine.start_step!(current_step, user: hmis_user)
    engine.complete_step!(current_step, user: hmis_user, submitted_values: submitted_values)
  end

  describe 'side effect that creates a event' do
    it 'creates the event' do
      expect do
        submit_current_step
      end.to change(referral.source_enrollment.events, :count).from(0).to(1)

      event = referral.source_enrollment.events.first
      expect(event.event).to eq(10)
      expect(event.location_crisis_or_ph_housing).to eq(referral.target_project.id.to_s)
    end

    context 'if there is no source enrollment' do
      let!(:source_enrollment) { nil }

      it 'raises an error' do
        expect do
          submit_current_step
        end.to raise_error(RuntimeError, /Referral does not have a source enrollment/)
      end
    end
  end

  describe 'side effect that updates the event' do
    before(:each) do
      submit_current_step # Submit the ce creation step
      expect(referral.source_enrollment.events.count).to eq(1)
    end

    context 'when the client rejects the referral' do
      it 'updates the event with the client rejection result' do
        event = referral.source_enrollment.events.first
        expect do
          submit_current_step({ client_accepted: 0 })
          event.reload
        end.to change(event, :result_date).from(nil).
          and change(event, :referral_result).from(nil).to(2)
      end
    end

    context 'when the provider rejects the referral' do
      before do
        submit_current_step({ client_accepted: 1 }) # Client accepts the referral
      end

      it 'updates the event with the provider rejection result' do
        event = referral.source_enrollment.events.first
        expect do
          submit_current_step({ provider_accepted: 0 })
          event.reload
        end.to change(event, :result_date).from(nil).
          and change(event, :referral_result).from(nil).to(3)
      end
    end

    context 'when everybody accepts' do
      before do
        submit_current_step({ client_accepted: 1 }) # Client accepts the referral
      end

      it 'updates the event with the acceptance result' do
        event = referral.source_enrollment.events.first
        expect do
          submit_current_step({ provider_accepted: 1 }) # Provider accepts the referral
          event.reload
        end.to change(event, :result_date).from(nil).
          and change(event, :referral_result).from(nil).to(1)
      end
    end
  end
end
