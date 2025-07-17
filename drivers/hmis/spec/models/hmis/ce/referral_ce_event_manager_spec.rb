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

  describe 'side effect that creates an event' do
    # These shared examples test the logic described in the Data Dictionary section 4.20.2

    # Shared example that submits the current referral step, and expects that an appropriate CE event got created
    shared_examples 'creates a CE event' do |expected_event|
      it "creates a CE event of type #{expected_event}" do
        submit_current_step
        event = referral.source_enrollment.events.first
        expect(event.event).to eq(expected_event)
      end
    end

    # Shared example that asserts that the appropriate event type was created based on the project type
    shared_examples 'creates a CE event for project type' do |project_type, expected_event|
      let!(:project) { create :hmis_hud_project, data_source: ds1, user: u1, project_type: project_type }

      it_behaves_like 'creates a CE event', expected_event
    end

    # Shared example that asserts that the appropriate event type was created based on the project type AND funders
    shared_examples 'creates a CE event for joint TH/RRH funder' do |funder_id, expected_event|
      let!(:funder) { create(:hmis_hud_funder, data_source: ds1, project: project, funder: funder_id) }

      it_behaves_like 'creates a CE event', expected_event
    end

    context 'project is ES' do
      include_examples 'creates a CE event for project type', 0, 10
      include_examples 'creates a CE event for project type', 1, 10
      include_examples 'creates a CE event for project type', 8, 10
    end

    context 'project is TH' do
      let!(:project) { create :hmis_hud_project, data_source: ds1, user: u1, project_type: 2 }
      it_behaves_like 'creates a CE event', 11

      context 'and project has joint TH/RRH funder' do
        include_examples 'creates a CE event for joint TH/RRH funder', 45, 12
        include_examples 'creates a CE event for joint TH/RRH funder', 54, 12
        include_examples 'creates a CE event for joint TH/RRH funder', 55, 12

        context 'but funding source is ended' do
          let!(:funder) { create(:hmis_hud_funder, data_source: ds1, project: project, funder: 45, end_date: 2.years.ago) }
          it_behaves_like 'creates a CE event', 11
        end
      end
    end

    context 'project is RRH' do
      let!(:project) { create :hmis_hud_project, data_source: ds1, user: u1, project_type: 13 }
      it_behaves_like 'creates a CE event', 13

      context 'and project has joint TH/RRH funder' do
        include_examples 'creates a CE event for joint TH/RRH funder', 45, 12
        include_examples 'creates a CE event for joint TH/RRH funder', 54, 12
        include_examples 'creates a CE event for joint TH/RRH funder', 55, 12

        context 'but funding source is ended' do
          let!(:funder) { create(:hmis_hud_funder, data_source: ds1, project: project, funder: 45, end_date: 2.years.ago) }
          it_behaves_like 'creates a CE event', 13
        end
      end
    end

    context 'project is PSH' do
      include_examples 'creates a CE event for project type', 3, 14
    end

    context 'project is OPH' do
      include_examples 'creates a CE event for project type', 9, 15
      include_examples 'creates a CE event for project type', 10, 15
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
    shared_examples 'updates the event with referral result' do |submitted_values, expected_result|
      it "updates the event with referral result #{expected_result}" do
        event = referral.source_enrollment.events.first
        expect do
          submit_current_step(submitted_values)
          event.reload
        end.to change(event, :result_date).from(nil).
          and change(event, :referral_result).from(nil).to(expected_result)
      end
    end

    before(:each) do
      submit_current_step # Submit the ce creation step
      expect(referral.source_enrollment.events.count).to eq(1)
    end

    context 'when the client rejects the referral' do
      include_examples 'updates the event with referral result', { client_accepted: 0 }, 2
    end

    context 'when the provider rejects the referral' do
      before do
        submit_current_step({ client_accepted: 1 }) # Client accepts the referral
      end

      include_examples 'updates the event with referral result', { provider_accepted: 0 }, 3
    end

    context 'when everybody accepts' do
      before do
        submit_current_step({ client_accepted: 1 }) # Client accepts the referral
      end

      include_examples 'updates the event with referral result', { provider_accepted: 1 }, 1
    end
  end
end
