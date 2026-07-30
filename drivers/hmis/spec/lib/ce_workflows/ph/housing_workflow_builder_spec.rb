###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CeWorkflows::Ph::HousingWorkflowBuilder do
  let!(:data_source) { create(:hmis_data_source) }
  let!(:user) { create(:hmis_user, data_source: data_source) }
  let!(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: data_source) }
  let!(:project) { create(:hmis_hud_project, data_source: data_source) }

  before do
    CeWorkflows::Shared::CeBuilderUtils.create_state_machine_custom_statuses(data_source)
    HmisUtil::JsonForms.new(
      data_source_id: data_source.id,
      env_key: 'tarrant_county',
      generate_cdeds: true,
    ).seed_record_form_definitions(roles: [:CE_REFERRAL_STEP])
  end

  let(:builder) { described_class.new(data_source) }
  let(:template) do
    builder.ensure_decline_reasons
    builder.build_housing_workflow
  end

  def node_index(walked_nodes, name)
    walked_nodes.index { |node| node.name == name }
  end

  def complete_user_step!(engine, step_name, submitted_values:)
    step = engine.active_steps.find { |s| s.node.name == step_name }
    raise "No active step named #{step_name}" unless step

    step.form_definition = step.node.form_definition
    engine.start_step!(step, user: user)
    engine.complete_step!(step, user: user, submitted_values: submitted_values)
  end

  def advance_housing_workflow_to_post_enrollment!(engine)
    complete_user_step!(
      engine,
      'CoC Initial Review',
      submitted_values: { 'coc_initial_review_decision' => 'continue' },
    )
    complete_user_step!(
      engine,
      'Shelter Agency Initial Review',
      submitted_values: {
        'shelter_agency_decision' => 'continue',
        'client_has_spoken_to_shelter_case_manager' => '1',
      },
    )
    complete_user_step!(
      engine,
      'Housing Case Manager Initial Review',
      submitted_values: {
        'case_manager_initial_review_decision' => 'continue',
        'intake_date' => Date.current.iso8601,
        'intake_time' => '10:00',
        'intake_location' => 'Office',
      },
    )
    complete_user_step!(
      engine,
      'Housing Case Manager Decision',
      submitted_values: {
        'case_manager_decision' => 'accept',
        'cori_hearing_needed' => 'no',
      },
    )
    complete_user_step!(
      engine,
      'Move-In Date',
      submitted_values: { 'move_in_date' => Date.current.iso8601 },
    )
  end

  shared_context 'housing workflow walkthrough' do
    let!(:in_progress_status) { Hmis::Ce::CustomReferralStatus.find_by!(key: 'in_progress', data_source: data_source) }
    let!(:source_project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 14) }
    let!(:source_enrollment) do
      create(:hmis_hud_enrollment, data_source: data_source, project: source_project, client: client, entry_date: 30.days.ago)
    end
    let!(:unit_group) { create(:hmis_unit_group, project: project, workflow_template: template, ce_event_type: 18) }
    let!(:unit) { create(:hmis_unit, project: project, unit_group: unit_group) }
    let!(:opportunity) { create(:hmis_ce_opportunity, unit: unit) }
    let!(:referral) do
      create(
        :hmis_ce_referral,
        client: client,
        opportunity: opportunity,
        source_enrollment: source_enrollment,
        workflow_instance: template.instances.create!,
        referred_by: user,
        status: 'initialized',
      )
    end
    let(:engine) { referral.workflow_engine }
    let!(:access_control) do
      create_access_control(
        user,
        data_source,
        with_permission: [
          :can_view_clients,
          :can_view_project,
          :can_view_enrollment_details,
          :can_edit_enrollments,
          :can_enroll_clients,
        ],
      )
    end
    let!(:project_coc) { create(:hmis_hud_project_coc, data_source: data_source, project: project, coc_code: 'CO-500') }

    before do
      template.swimlanes.each do |swimlane|
        referral.participants.create!(swimlane: swimlane, user: user)
      end

      engine.start_workflow!(user: user)
    end
  end

  describe '#build_housing_workflow' do
    it 'passes template validation' do
      expect { template.validate! }.not_to raise_error
    end

    it 'projects the happy-path user tasks for a new referral' do
      # Mirrors CeReferral#steps before any steps are materialized.
      projected = template.graph(preloads: :inflows).
        walk(stop_when: lambda(&:conditional_inflows?)).
        filter(&:user_task?).
        reject(&:conditional_inflows?).
        map(&:name)

      expect(projected).to eq(
        [
          'CoC Initial Review',
          'Shelter Agency Initial Review',
          'Housing Case Manager Initial Review',
          'Housing Case Manager Decision',
          'Move-In Date',
          'Confirm Success',
          'Decline Referral',
        ],
      )
    end
  end

  describe 'send-forward walkthrough' do
    include_context 'housing workflow walkthrough'

    it 'advances to schedule intake after CoC sends forward on first decline review' do
      complete_user_step!(
        engine,
        'CoC Initial Review',
        submitted_values: { 'coc_initial_review_decision' => 'continue' },
      )

      complete_user_step!(
        engine,
        'Shelter Agency Initial Review',
        submitted_values: { 'shelter_agency_decision' => 'decline_client_declined_match', 'decline_client_declined_match_reason' => 'other' },
      )

      complete_user_step!(
        engine,
        'Review Decline (Shelter Agency)',
        submitted_values: { 'review_decline_decision' => 'send_forward' },
      )

      active_step = engine.active_steps.find { |s| s.node.name == 'Housing Case Manager Initial Review' }
      expect(active_step).to be_present
      expect(referral.reload.custom_status).to eq(in_progress_status)
    end

    it 'advances to schedule intake after CoC sends forward on final decline review' do
      complete_user_step!(
        engine,
        'CoC Initial Review',
        submitted_values: { 'coc_initial_review_decision' => 'continue' },
      )

      complete_user_step!(
        engine,
        'Shelter Agency Initial Review',
        submitted_values: { 'shelter_agency_decision' => 'decline_client_declined_match', 'decline_client_declined_match_reason' => 'other' },
      )

      complete_user_step!(
        engine,
        'Review Decline (Shelter Agency)',
        submitted_values: { 'review_decline_decision' => 'go_back' },
      )

      complete_user_step!(
        engine,
        'Shelter Agency Initial Review (Second Attempt)',
        submitted_values: { 'shelter_agency_decision' => 'decline_client_declined_match', 'decline_client_declined_match_reason' => 'other' },
      )

      complete_user_step!(
        engine,
        'Final Review Decline (Shelter Agency)',
        submitted_values: { 'review_decline_final_decision' => 'send_forward' },
      )

      active_step = engine.active_steps.find { |s| s.node.name == 'Housing Case Manager Initial Review' }
      expect(active_step).to be_present
      expect(referral.reload.custom_status).to eq(in_progress_status)
    end
  end

  describe 'closure walkthrough' do
    include_context 'housing workflow walkthrough'

    let!(:decline_reason) do
      Hmis::Ce::ReferralDeclineReason.find_by!(key: 'client_has_declined_match', data_source: data_source)
    end
    let(:decline_referral_node) { template.nodes.find { |node| node.name == 'Decline Referral' } }

    it 'accepts the referral when Confirm Success is completed' do
      advance_housing_workflow_to_post_enrollment!(engine)

      expect(engine.active_steps.map { |s| s.node.name }).to contain_exactly('Confirm Success', 'Decline Referral')

      referral.reload
      complete_user_step!(engine, 'Confirm Success', submitted_values: {})

      expect(referral.reload.status).to eq('accepted')
      expect(engine.active_steps).to be_empty

      decline_step = referral.workflow_instance.steps.find_by!(node: decline_referral_node)
      expect(decline_step.open?).to be(false)
    end

    it 'rejects the referral when Decline Referral is completed after enrollment' do
      advance_housing_workflow_to_post_enrollment!(engine)

      enrollment = referral.reload.target_enrollment
      expect(enrollment).to be_present

      expect do
        complete_user_step!(
          engine,
          'Decline Referral',
          submitted_values: {
            'decline_reason' => 'client_has_declined_match',
            'referral_result' => '2',
          },
        )
        referral.reload
      end.to change(referral, :status).to('rejected').
        and change(referral, :decline_reason).to(decline_reason).
        and change(referral, :target_enrollment).from(enrollment).to(nil)

      expect(engine.active_steps).to be_empty
    end
  end
end
