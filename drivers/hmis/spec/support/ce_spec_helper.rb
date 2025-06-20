# frozen_string_literal: true

require 'rails_helper'
require_relative '../requests/hmis/login_and_permissions'

RSpec.shared_context 'ce spec helper' do
  # This shared context creates a basic CE template, opportunity, and referral.
  # The template has 2 tasks that are executed sequentially, then a conditional gateway, with 2 possible end events (accept/reject).

  include_context 'hmis base setup'

  let!(:ds_access_control) do
    create_access_control(
      hmis_user,
      ds1,
      with_permission: [
        :can_view_clients,
        :can_view_client_name,
        :can_view_project,
        :can_view_enrollment_details,
        :can_view_referrals,
        :can_view_units,
      ],
    )
  end

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
  end

  let!(:client) { create :hmis_hud_client_complete, data_source: ds1, user: u1 }
  let!(:project) { create :hmis_hud_project, data_source: ds1, user: u1 }
  let!(:workflow_template) { create(:hmis_workflow_definition_template, data_source: ds1) }
  let!(:opportunity) { create :hmis_ce_opportunity, project: project, workflow_template: workflow_template }
  let!(:workflow_instance) { workflow_template.instances.create! }

  let!(:start_event) do
    create(
      :hmis_workflow_definition_start_event,
      template: workflow_template,
      name: 'Start Referral',
      trigger_config: [
        {
          event: 'start_workflow',
          message: 'start_referral',
        },
      ],
    )
  end

  let!(:case_manager_swimlane) { workflow_template.swimlanes.create!(name: 'Case Managers') }
  let!(:provider_swimlane) { workflow_template.swimlanes.create!(name: 'Providers') }

  let!(:ce_step_definition) { create(:ce_referral_step_form_definition) }

  let!(:client_acceptance_task) do
    create(
      :hmis_workflow_definition_task,
      template: workflow_template,
      name: 'Client Acceptance',
      swimlane: case_manager_swimlane,
      form_definition: ce_step_definition,
    )
  end

  let!(:provider_acceptance_task) do
    create(
      :hmis_workflow_definition_task,
      template: workflow_template,
      name: 'Provider Acceptance',
      swimlane: provider_swimlane,
      form_definition: ce_step_definition,
    )
  end

  let(:acceptance_gateway) do
    create(
      :hmis_workflow_definition_gateway,
      template: workflow_template,
      gateway_type: 'exclusive',
      name: 'acceptance gw',
    )
  end

  let(:reject_referral) do
    create(
      :hmis_workflow_definition_end_event,
      template: workflow_template,
      name: 'reject referral',
      trigger_config: [
        {
          event: 'end_workflow',
          message: Hmis::Ce::ReferralMessageHandler::REJECT_REFERRAL_MESSAGE,
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
      ],
    )
  end

  # Connect workflow nodes
  before do
    start_event.connect_to!(client_acceptance_task)
    client_acceptance_task.connect_to!(provider_acceptance_task)
    provider_acceptance_task.connect_to!(acceptance_gateway)
    acceptance_gateway.connect_to!(reject_referral)
    acceptance_gateway.connect_to!(accept_referral, condition: 'client_accepted = 1')
  end

  let!(:referral) do
    create(
      :hmis_ce_referral,
      opportunity: opportunity,
      workflow_instance: workflow_instance,
      client: client,
      referred_by: hmis_user,
      status: 'initialized',
    )
  end

  let(:engine) { referral.workflow_engine }
end

RSpec.configure do |rspec|
  rspec.include_context 'ce spec helper', include_shared: true
end
