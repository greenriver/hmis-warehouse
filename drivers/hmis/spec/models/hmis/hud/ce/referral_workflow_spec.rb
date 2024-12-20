require 'rails_helper'

RSpec.describe Hmis::Ce::Referral, type: :model do
  let!(:template) { create(:hmis_workflow_definition_template) }
  let(:user) { create(:hmis_user) }
  let(:client) { create(:hmis_hud_client) }
  let(:opportunity) { create(:hmis_ce_opportunity, workflow_template: template) }
  let(:instance) { opportunity.workflow_template.instances.create! }
  let(:referral) { create(:hmis_ce_referral, opportunity: opportunity, workflow_instance: instance, referred_by: user) }

  # common nodes
  let(:start_event) do
    create(
      :hmis_workflow_definition_start_event,
      template: template,
      trigger_config: [
        {
          event: 'start_workflow',
          message: 'start_referral',
        },
      ],
    )
  end

  let(:accept_referral) do
    create(
      :hmis_workflow_definition_end_event,
      template: template,
      trigger_config: [
        {
          event: 'end_workflow',
          message: 'accept_referral',
        },
      ],
    )
  end

  let(:reject_referral) do
    create(
      :hmis_workflow_definition_end_event,
      template: template,
      trigger_config: [
        {
          event: 'end_workflow',
          message: 'reject_referral',
        },
      ],
    )
  end

  describe 'Branching workflow' do
    let(:client_acceptance_task) do
      create(:hmis_workflow_definition_task, template: template)
    end

    let(:client_acceptance_gateway) do
      create(:hmis_workflow_definition_gateway, template: template, gateway_type: 'exclusive')
    end

    before do
      # setup the flow
      start_event.connect_to!(client_acceptance_task)
      client_acceptance_task.connect_to!(client_acceptance_gateway)
      client_acceptance_gateway.connect_to!(reject_referral, condition: 'client_accepted = 0')
      client_acceptance_gateway.connect_to!(accept_referral, condition: 'client_accepted = 1')
    end

    [
      [{ 'client_accepted': 1 }, 'accepted'],
      [{ 'client_accepted': 0 }, 'rejected'],
    ].each do |task_data, expected_end_status|
      it "completes with \"#{expected_end_status}\" status when #{task_data.inspect}" do
        engine = referral.workflow_engine

        expect do
          engine.start_workflow!(user: user)
        end.to change(engine.active_steps, :count).from(0).to(1)
        expect(referral).to be_in_progress

        current_step = engine.active_steps.sole
        expect(current_step.node).to eq(client_acceptance_task)

        engine.start_step!(current_step, user: user)
        expect(current_step).to be_in_progress

        engine.complete_step!(current_step, user: user, submitted_values: task_data)
        expect(current_step).to be_completed

        expect(engine.active_steps.count).to be_zero
        expect(referral.status).to eq(expected_end_status)
      end
    end
  end

  describe 'Parallel tasks' do
    let(:background_check_task) do
      create(:hmis_workflow_definition_task, template: template)
    end

    let(:income_check_task) do
      create(:hmis_workflow_definition_task, template: template)
    end

    let(:start_verification_gateway) do
      create(:hmis_workflow_definition_gateway, template: template, gateway_type: 'inclusive')
    end

    let(:complete_verification_gateway) do
      create(:hmis_workflow_definition_gateway, template: template, gateway_type: 'join')
    end

    before do
      start_event.connect_to!(start_verification_gateway)
      [
        [background_check_task, 'background_check_passed = 1'],
        [income_check_task, 'income_check_passed = 1'],
      ].each do |task, pass_condition|
        start_verification_gateway.connect_to!(task)
        task_gateway = create(:hmis_workflow_definition_gateway, template: template, gateway_type: 'exclusive')
        task.connect_to!(task_gateway)
        task_gateway.connect_to!(complete_verification_gateway, condition: pass_condition)
        task_gateway.connect_to!(reject_referral) # default fail condition
      end
      complete_verification_gateway.connect_to!(accept_referral)
    end

    it 'completes' do
      engine = referral.workflow_engine

      expect do
        engine.start_workflow!(user: user)
      end.to change(engine.active_steps, :count).from(0).to(2)
      expect(referral).to be_in_progress

      [
        [background_check_task, { background_check_passed: 1 }],
        [income_check_task, { income_check_passed: 1 }],
      ].each do |task, task_data|
        current_step = engine.active_steps.where(node: task).sole
        engine.start_step!(current_step, user: user)
        expect(current_step).to be_in_progress
        engine.complete_step!(current_step, user: user, submitted_values: task_data)
        expect(current_step).to be_completed
      end

      expect(engine.active_steps.count).to be_zero
      expected_end_status = 'accepted'
      expect(referral.status).to eq(expected_end_status)
    end
  end
end
