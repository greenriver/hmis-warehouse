###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Referral, type: :model do
  let!(:data_source) { create(:hmis_data_source) }
  let!(:template) { create(:hmis_workflow_definition_template, data_source: data_source) }
  let!(:project) { create(:hmis_hud_project, data_source: data_source) }
  let!(:client) { create(:hmis_hud_client, data_source: data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }
  let(:opportunity) { create(:hmis_ce_opportunity, workflow_template: template, project: project) }
  let(:instance) { opportunity.workflow_template.instances.create! }
  let(:referral) { create(:hmis_ce_referral, client: client, opportunity: opportunity, workflow_instance: instance, referred_by: user) }
  let(:engine) { referral.workflow_engine }

  # common nodes
  let(:start_event) do
    create(
      :hmis_workflow_definition_start_event,
      template: template,
      name: 'start referral',
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
      name: 'accept referral',
      trigger_config: [
        {
          event: 'end_workflow',
          message: Hmis::Ce::ReferralMessageHandler::ACCEPT_REFERRAL_MESSAGE,
        },
      ],
    )
  end

  let(:reject_referral) do
    create(
      :hmis_workflow_definition_end_event,
      template: template,
      name: 'reject referral',
      trigger_config: [
        {
          event: 'end_workflow',
          message: Hmis::Ce::ReferralMessageHandler::REJECT_REFERRAL_MESSAGE,
        },
      ],
    )
  end

  describe 'Workflow with no steps' do
    before do
      start_event.connect_to!(accept_referral)
    end
    it 'Completes immediately' do
      engine.start_workflow!(user: user)
      expect(referral).to be_accepted
    end
  end

  describe 'Branching workflow' do
    let(:case_manager) { create(:hmis_user) }
    let(:case_manager_swimlane) { template.swimlanes.create(name: 'Case Managers') }

    let(:client_acceptance_task) do
      create(:hmis_workflow_definition_user_task, template: template, name: 'client acceptance task', swimlane: case_manager_swimlane)
    end

    let(:client_acceptance_gateway) do
      create(:hmis_workflow_definition_gateway, template: template, gateway_type: 'exclusive', name: 'client acceptance gw')
    end

    before do
      referral.participants.create!(user: case_manager, swimlane: case_manager_swimlane)

      # setup the flow
      start_event.connect_to!(client_acceptance_task)
      client_acceptance_task.connect_to!(client_acceptance_gateway)
      client_acceptance_gateway.connect_to!(reject_referral, condition: 'client_accepted = 0')
      client_acceptance_gateway.connect_to!(accept_referral, condition: 'client_accepted = 1')
    end

    [
      [{ 'client_accepted': 1 }, 'accepted', 'closed'],
      [{ 'client_accepted': 0 }, 'rejected', 'open'],
    ].each do |task_data, expected_referral_end_status, expected_opportunity_end_status|
      it "completes with \"#{expected_referral_end_status}\" status when #{task_data.inspect}" do
        expect(opportunity.status).to eq('open')
        expect do
          engine.start_workflow!(user: user)
        end.to change(engine.active_steps, :count).from(0).to(1).
          and change(opportunity, :status).from('open').to('locked')
        expect(referral).to be_in_progress

        current_step = engine.active_steps.sole
        expect(current_step.node).to eq(client_acceptance_task)
        expect(current_step.assignments.sole&.user).to eq(case_manager)
        expect(current_step.available_at).not_to be_nil

        engine.start_step!(current_step, user: user)
        expect(current_step).to be_in_progress
        expect(referral.completed_at).to be_nil

        engine.complete_step!(current_step, user: user, submitted_values: task_data)
        expect(current_step).to be_completed
        expect(current_step.updated_by).to eq(user)

        expect(engine.active_steps.count).to be_zero
        expect(referral.status).to eq(expected_referral_end_status)
        expect(referral.completed_at).not_to be_nil
        expect(opportunity.reload.status).to eq(expected_opportunity_end_status)
      end
    end
  end

  describe 'Parallel tasks' do
    let(:background_check_task) do
      create(:hmis_workflow_definition_user_task, template: template, name: 'background check task')
    end

    let(:income_check_task) do
      create(:hmis_workflow_definition_user_task, template: template, name: 'income check task')
    end

    let(:start_verification_gateway) do
      create(:hmis_workflow_definition_gateway, template: template, gateway_type: 'inclusive', name: 'start verification gw')
    end

    let(:complete_verification_gateway) do
      create(:hmis_workflow_definition_gateway, template: template, gateway_type: 'join', name: 'complete verification gw')
    end

    before do
      start_event.connect_to!(start_verification_gateway)
      [
        [background_check_task, 'background_check_passed = 1'],
        [income_check_task, 'income_check_passed = 1'],
      ].each do |task, pass_condition|
        start_verification_gateway.connect_to!(task)
        task_gateway = create(:hmis_workflow_definition_gateway, template: template, gateway_type: 'exclusive', name: "#{task.name} gw")
        task.connect_to!(task_gateway)
        task_gateway.connect_to!(complete_verification_gateway, condition: pass_condition)
        task_gateway.connect_to!(reject_referral) # default fail condition
      end
      complete_verification_gateway.connect_to!(accept_referral)
    end

    it 'completes' do
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

  describe 'A Multi-task workflow' do
    let(:client_acceptance_task) do
      create(:hmis_workflow_definition_user_task, template: template, name: 'client acceptance task')
    end

    let(:provider_acceptance_task) do
      create(:hmis_workflow_definition_user_task, template: template, name: 'provider acceptance task')
    end

    let(:income_check_task) do
      create(:hmis_workflow_definition_user_task, template: template, name: 'income check task')
    end

    let(:enrollment_task) do
      create(:hmis_workflow_definition_user_task, template: template, name: 'income check task')
    end

    before do
      # setup the flow
      start_event.connect_to!(client_acceptance_task)
      gw1 = create(:hmis_workflow_definition_gateway, template: template, gateway_type: 'inclusive', name: 'gw1')
      gw2 = create(:hmis_workflow_definition_gateway, template: template, gateway_type: 'join', name: 'gw2')

      client_acceptance_task.connect_to!(gw1)
      gw1.connect_to!(provider_acceptance_task)
      gw1.connect_to!(income_check_task)

      provider_acceptance_task.connect_to!(gw2)
      income_check_task.connect_to!(gw2)

      gw2.connect_to!(enrollment_task)
      enrollment_task.connect_to!(accept_referral)
    end

    before do
      # partially complete the workflow
      engine.start_workflow!(user: user)
      current_step = engine.active_steps.sole
      engine.start_step!(current_step, user: user)
      engine.complete_step!(current_step, user: user, submitted_values: {})
    end

    # FIXME - should probably be extracted own graph_spec.rb
    it 'walks workflow nodes down parallel paths' do
      nodes = template.graph.walk(entrypoint_ids: [client_acceptance_task.id], stop_when: lambda(&:user_task?)).filter(&:user_task?).to_a
      expect(nodes).to eq([provider_acceptance_task, income_check_task])
    end

    describe 'when only the first step is completed' do
      it 'the first step can be rolled back' do
        first_task_step = instance.steps.where(node: client_acceptance_task).sole
        expect(first_task_step).to be_completed
        expect(engine.may_undo_complete_step?(first_task_step)).to eq(true)
        expect do
          engine.undo_complete_step!(first_task_step, user: user)
        end.to change(first_task_step, :status).from('completed').to('in_progress')
      end
    end

    describe 'when the following step is completed' do
      before do
        current_step = engine.active_steps.where(node: provider_acceptance_task).sole
        engine.start_step!(current_step, user: user)
        engine.complete_step!(current_step, user: user, submitted_values: {})
      end

      it 'the first step can not be rolled back' do
        first_task_step = instance.steps.where(node: client_acceptance_task).sole
        second_task_step = instance.steps.where(node: provider_acceptance_task).sole
        expect(first_task_step).to be_completed
        expect(second_task_step).to be_completed
        expect(engine.may_undo_complete_step?(first_task_step)).to eq(false)
      end
    end
  end

  describe 'a workflow that loops back to a previous node' do
    let(:client_acceptance_task) do
      create(
        :hmis_workflow_definition_user_task,
        template: template,
        name: 'client acceptance task',
        trigger_config: [
          {
            event: 'complete_step',
            message: 'send_notification', # it has a side effect, but not one that makes the step irreversible
          },
        ],
      )
    end

    let(:admin_approve_denial_task) do
      create(:hmis_workflow_definition_user_task, template: template, name: 'admin approve denial')
    end

    let!(:gw1) { create(:hmis_workflow_definition_gateway, template: template, gateway_type: 'exclusive', name: 'gw1') }

    before do
      start_event.connect_to!(client_acceptance_task)
      client_acceptance_task.connect_to!(admin_approve_denial_task)
      admin_approve_denial_task.connect_to!(gw1)
      gw1.connect_to!(client_acceptance_task, condition: 'review_denial_decision = 0')
      gw1.connect_to!(reject_referral, condition: 'review_denial_decision = 1')

      engine.start_workflow!(user: user)
    end

    let(:client_step) { instance.steps.where(node: client_acceptance_task).sole }
    let(:admin_step) { instance.steps.where(node: admin_approve_denial_task).sole }

    it 'allows the previous step to be reopened and closed again' do
      engine.start_step!(client_step, user: user)
      engine.complete_step!(client_step, user: user, submitted_values: {})

      expect do
        engine.start_step!(admin_step, user: user)
        engine.complete_step!(admin_step, user: user, submitted_values: { 'review_denial_decision': 0 })
        client_step.reload
        admin_step.reload
      end.to change(client_step, :status).from('completed').to('available').
        and change(client_step, :available_at).
        and not_change(instance.steps, :count)

      expect do
        engine.start_step!(client_step, user: user)
        engine.complete_step!(client_step, user: user, submitted_values: {})
        client_step.reload
        admin_step.reload
      end.to change(client_step, :status).from('available').to('completed').
        and change(admin_step, :status).from('completed').to('available')
    end

    context 'when the step getting restarted had irreversible side effects' do
      let!(:access_control) { create_access_control(user, project, with_permission: [:can_edit_enrollments, :can_enroll_clients]) }
      let!(:coc1) { create(:hmis_hud_project_coc, data_source: project.data_source, project: project, coc_code: 'CO-500') }

      let(:client_acceptance_task) do
        create(
          :hmis_workflow_definition_user_task,
          template: template,
          name: 'client acceptance task',
          trigger_config: [
            {
              event: 'complete_step',
              message: 'create_enrollment',
            },
          ],
        )
      end

      it 'throws an error, indicating misconfigured workflow' do
        expect do
          engine.start_step!(client_step, user: user)
          engine.complete_step!(client_step, user: user, submitted_values: {})
        end.to change(Hmis::Hud::Enrollment, :count).by(1).
          and change(referral, :target_enrollment).from(nil)

        expect do
          engine.start_step!(admin_step, user: user)
          engine.complete_step!(admin_step, user: user, submitted_values: { 'review_denial_decision': 0 })
        end.to raise_error(RuntimeError, /Failed to reopen step/)
      end
    end
  end

  describe 'Workflow with script task' do
    let!(:coc1) { create(:hmis_hud_project_coc, data_source: project.data_source, project: project, coc_code: 'CO-500') }

    let(:acceptance_task) do
      create(:hmis_workflow_definition_user_task, template: template, name: 'client acceptance task')
    end

    let!(:gw1) { create(:hmis_workflow_definition_gateway, template: template, gateway_type: 'exclusive', name: 'gw1') }

    let(:script_task) do
      create(
        :hmis_workflow_definition_script_task,
        template: template,
        name: 'Enrollment Creator',
        trigger_config: [
          {
            event: 'complete_step',
            message: 'create_enrollment',
          },
        ],
      )
    end

    before do
      start_event.connect_to!(acceptance_task)
      acceptance_task.connect_to!(gw1)
      gw1.connect_to!(script_task, condition: 'accept = 1')
      gw1.connect_to!(reject_referral)
      script_task.connect_to!(accept_referral)

      engine.start_workflow!(user: user)

      current_step = engine.active_steps.sole
      expect(current_step.node).to eq(acceptance_task)
      expect(current_step.status).to eq('available')

      engine.start_step!(current_step, user: user)
      expect(current_step.status).to eq('in_progress')
    end

    it 'executes script task' do
      acceptance_step = engine.active_steps.sole

      expect do
        engine.complete_step!(acceptance_step, user: user, submitted_values: { accept: 1 })
      end.to change(Hmis::Hud::Enrollment, :count).by(1)

      script_step = instance.steps.where(node: script_task).sole
      expect(script_step.status).to eq('completed')
    end
  end
end
