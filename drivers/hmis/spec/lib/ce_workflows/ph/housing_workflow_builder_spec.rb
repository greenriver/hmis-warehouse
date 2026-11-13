###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CeWorkflows::Ph::HousingWorkflowBuilder do
  # We intentionally build the template (and the data source, seeded CE_REFERRAL_STEP forms, and custom
  # referral statuses it depends on) once in before(:all), rather than with the usual per-example
  # transactional fixtures. The class under test is a destroy-and-recreate builder: rebuilding the
  # template per example would rerun its delete-and-recreate on every example, which is slow.
  before(:all) do
    @data_source = create(:hmis_data_source)
    CeWorkflows::Shared::CeBuilderUtils.create_state_machine_custom_statuses(@data_source)
    HmisUtil::JsonForms.new(
      data_source_id: @data_source.id,
      env_key: 'tarrant_county',
      generate_cdeds: true,
    ).seed_record_form_definitions(roles: [:CE_REFERRAL_STEP])
    @template = CeWorkflows::Ph::HousingWorkflowBuilder.new(@data_source).build_housing_workflow
  end

  after(:all) do
    # Reverse of the before(:all) setup.
    CeWorkflows::Shared::CeBuilderUtils.delete_template_and_associated_data('housing_workflow', data_source: @data_source)
    Hmis::Form::Instance.in_data_source(@data_source.id).delete_all
    Hmis::Form::Definition.in_data_source(@data_source.id).delete_all
    Hmis::Hud::CustomDataElementDefinition.where(data_source: @data_source).delete_all
    Hmis::Hud::CustomDataElement.where(data_source: @data_source).delete_all
    Hmis::Ce::CustomReferralStatus.where(data_source: @data_source).delete_all
    @data_source.destroy!
  end

  # Reload the before(:all) records each example so they're bound to the example's transaction and don't
  # carry cached associations (e.g. `template.instances`) across examples.
  let(:data_source) { GrdaWarehouse::DataSource.find(@data_source.id) }
  let(:template) { Hmis::WorkflowDefinition::Template.find(@template.id) }

  let!(:user) { create(:hmis_user, data_source: data_source) }
  let!(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: data_source) }
  let!(:project) { create(:hmis_hud_project, data_source: data_source) }

  # Reusable submitted-value fragments for the housing steps, so tests read as short declarative scripts.
  let(:coc_continue) { { 'coc_initial_review_decision' => 'continue' } }
  let(:coc_decline) { { 'coc_initial_review_decision' => 'decline', 'coc_initial_review_decline_reason' => 'other' } }
  let(:shelter_continue) { { 'shelter_agency_decision' => 'continue', 'client_has_spoken_to_shelter_case_manager' => '1' } }
  let(:shelter_decline) { { 'shelter_agency_decision' => 'decline_client_declined_match', 'decline_client_declined_match_reason' => 'other' } }
  let(:intake_continue) do
    {
      'case_manager_initial_review_decision' => 'continue',
      'intake_date' => Date.current.iso8601,
      'intake_time' => '10:00',
      'intake_location' => 'Office',
    }
  end
  let(:intake_decline) { { 'case_manager_initial_review_decision' => 'decline', 'case_manager_initial_review_decline_reason' => 'other' } }
  let(:decision_accept) { { 'case_manager_decision' => 'accept', 'cori_hearing_needed' => 'no' } }
  let(:decision_accept_with_cori) do
    {
      'case_manager_decision' => 'accept',
      'cori_hearing_needed' => 'yes',
      'cori_hearing_date' => Date.current.iso8601,
      'cori_hearing_time' => '10:00',
    }
  end
  let(:decision_decline) { { 'case_manager_decision' => 'decline', 'case_manager_decision_decline_reason' => 'other' } }
  let(:cori_continue) { { 'cori_hearing_notes' => 'ok', 'cori_hearing_decision' => 'continue' } }
  let(:cori_decline) { { 'cori_hearing_notes' => 'ok', 'cori_hearing_decision' => 'decline', 'cori_hearing_decline_reason' => 'cori' } }

  # Approve/override decisions on the (first and final) Review Decline steps.
  let(:review_approve_decline) { { 'review_decline_decision' => 'approve_decline', 'referral_result' => '2' } }
  let(:review_go_back) { { 'review_decline_decision' => 'go_back' } }
  let(:review_send_forward) { { 'review_decline_decision' => 'send_forward' } }
  let(:final_review_approve_decline) { { 'review_decline_final_decision' => 'approve_decline', 'referral_result' => '2' } }
  let(:final_review_send_forward) { { 'review_decline_final_decision' => 'send_forward' } }

  def advance_housing_workflow_to_post_enrollment!(engine, case_manager_decision: 'accept', cori_hearing_needed: 'no')
    drive!(
      engine,
      [
        ['CoC Initial Review', coc_continue],
        ['Shelter Agency Initial Review', shelter_continue],
        ['Housing Case Manager Initial Review', intake_continue],
        [
          'Housing Case Manager Decision',
          {
            'case_manager_decision' => case_manager_decision,
            'cori_hearing_needed' => cori_hearing_needed,
            'cori_hearing_date' => Date.current.iso8601,
            'cori_hearing_time' => '10:00',
          },
        ],
      ],
      user: user,
    )
    complete_user_step!(engine, 'CORI Hearing', submitted_values: cori_continue, user: user) if cori_hearing_needed == 'yes'
    complete_user_step!(engine, 'Move-In Date', submitted_values: { 'move_in_date' => Date.current.iso8601 }, user: user)
  end

  shared_context 'housing workflow walkthrough' do
    let!(:in_progress_status) { Hmis::Ce::CustomReferralStatus.find_by!(key: 'in_progress', data_source: data_source) }
    # 'enrolled' is created by the builder, so look it up on demand rather than in a before hook.
    let(:enrolled_status) { Hmis::Ce::CustomReferralStatus.find_by!(key: 'enrolled', data_source: data_source) }
    # The status after a send_forward override depends on where continue_next_steps lands: sub-trees that
    # resume an in-review user task stay 'in_progress', while those that route into Create Enrollment (i.e.
    # continue on to Move-In Date) become 'enrolled'. Including describe blocks override this when needed.
    let(:continue_status) { in_progress_status }
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

  describe 'housing workflow projected steps' do
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
          'Admin Cancel',
        ],
      )
    end
  end

  # A CoC decline before "continue" happens before any CE event is created, so it records no result.
  describe 'CoC initial review decline' do
    include_context 'housing workflow walkthrough'

    it 'rejects the referral with no CE event and no result' do
      complete_user_step!(engine, 'CoC Initial Review', submitted_values: coc_decline, user: user)

      expect_rejected(referral, result: nil)
      expect(referral.ce_event).to be_nil
      expect(engine.active_steps).to be_empty
    end
  end

  # decline_gateway routes on referral_result: 2 => client rejected, 3 => provider rejected, otherwise
  # the no-result default. We reach it here via the first Review Decline step (CE event already exists).
  describe 'decline_gateway result routing' do
    include_context 'housing workflow walkthrough'

    before do
      drive!(
        engine,
        [
          ['CoC Initial Review', coc_continue],
          ['Shelter Agency Initial Review', shelter_decline],
        ],
        user: user,
      )
    end

    it 'records CE event result 2 (client rejected)' do
      complete_user_step!(
        engine,
        'Review Decline (Shelter Agency)',
        submitted_values: { 'review_decline_decision' => 'approve_decline', 'referral_result' => '2' },
        user: user,
      )

      expect_rejected(referral, result: 2)
    end

    it 'records CE event result 3 (provider rejected)' do
      complete_user_step!(
        engine,
        'Review Decline (Shelter Agency)',
        submitted_values: { 'review_decline_decision' => 'approve_decline', 'referral_result' => '3' },
        user: user,
      )

      expect_rejected(referral, result: 3)
    end

    it 'takes the no-result default branch when no referral_result is submitted' do
      complete_user_step!(
        engine,
        'Review Decline (Shelter Agency)',
        submitted_values: { 'review_decline_decision' => 'approve_decline' },
        user: user,
      )

      referral.reload
      expect(referral.status).to eq('rejected')
      # The CE event exists (created after CoC continue) but no result was recorded on the default branch.
      expect(referral.ce_event).to be_present
      expect(referral.ce_event.referral_result).to be_nil
    end
  end

  # The four Review Decline sub-trees are structurally identical (approve/go_back/send_forward, then a
  # second-attempt decline into a Final Review Decline with approve/send_forward). This shared example
  # exercises each one's real wiring. Each including context supplies its configuration via `let`s
  # (review_decline_step, final_review_decline_step, reopened_step, reopened_decline_values,
  # continue_next_steps) and a `reach_review_decline!` that drives the engine so the first Review
  # Decline step is open.
  shared_examples 'a review-decline sub-tree' do
    before { reach_review_decline! }

    def drive_to_final_review!
      complete_user_step!(engine, review_decline_step, submitted_values: review_go_back, user: user)
      complete_user_step!(engine, reopened_step, submitted_values: reopened_decline_values, user: user)
    end

    it 'rejects when the CoC approves the decline' do
      complete_user_step!(engine, review_decline_step, submitted_values: review_approve_decline, user: user)

      expect_rejected(referral, result: 2)
      expect(engine.active_steps).to be_empty
    end

    it 'overrides the decline and continues on send_forward' do
      complete_user_step!(engine, review_decline_step, submitted_values: review_send_forward, user: user)

      expect_active_steps(engine, *continue_next_steps)
      expect(referral.reload.custom_status).to eq(continue_status)
    end

    it 'sends back for a second attempt on go_back' do
      complete_user_step!(engine, review_decline_step, submitted_values: review_go_back, user: user)

      expect_active_steps(engine, reopened_step, 'Admin Cancel')
    end

    it 'routes a second decline to the final review step' do
      drive_to_final_review!

      expect_active_steps(engine, final_review_decline_step, 'Admin Cancel')
    end

    it 'rejects when the CoC approves the decline at final review' do
      drive_to_final_review!
      complete_user_step!(engine, final_review_decline_step, submitted_values: final_review_approve_decline, user: user)

      expect_rejected(referral, result: 2)
      expect(engine.active_steps).to be_empty
    end

    it 'overrides the decline and continues at final review' do
      drive_to_final_review!
      complete_user_step!(engine, final_review_decline_step, submitted_values: final_review_send_forward, user: user)

      expect_active_steps(engine, *continue_next_steps)
      expect(referral.reload.custom_status).to eq(continue_status)
    end
  end

  describe 'Shelter Agency sub-tree' do
    include_context 'housing workflow walkthrough'

    let(:review_decline_step) { 'Review Decline (Shelter Agency)' }
    let(:final_review_decline_step) { 'Final Review Decline (Shelter Agency)' }
    let(:reopened_step) { 'Shelter Agency Initial Review (Second Attempt)' }
    let(:reopened_decline_values) { shelter_decline }
    let(:continue_next_steps) { ['Housing Case Manager Initial Review', 'Admin Cancel'] }

    def reach_review_decline!
      drive!(
        engine,
        [
          ['CoC Initial Review', coc_continue],
          ['Shelter Agency Initial Review', shelter_decline],
        ],
        user: user,
      )
    end

    it_behaves_like 'a review-decline sub-tree'
  end

  describe 'Case Manager Intake sub-tree' do
    include_context 'housing workflow walkthrough'

    let(:review_decline_step) { 'Review Decline (Case Manager Intake)' }
    let(:final_review_decline_step) { 'Final Review Decline (Case Manager Intake)' }
    let(:reopened_step) { 'Housing Case Manager Initial Review (Second Attempt)' }
    let(:reopened_decline_values) { intake_decline }
    let(:continue_next_steps) { ['Housing Case Manager Decision', 'Admin Cancel'] }

    def reach_review_decline!
      drive!(
        engine,
        [
          ['CoC Initial Review', coc_continue],
          ['Shelter Agency Initial Review', shelter_continue],
          ['Housing Case Manager Initial Review', intake_decline],
        ],
        user: user,
      )
    end

    it_behaves_like 'a review-decline sub-tree'
  end

  describe 'Case Manager Decision sub-tree' do
    include_context 'housing workflow walkthrough'

    let(:review_decline_step) { 'Review Decline (Case Manager Decision)' }
    let(:final_review_decline_step) { 'Final Review Decline (Case Manager Decision)' }
    let(:reopened_step) { 'Housing Case Manager Decision (Second Attempt)' }
    let(:reopened_decline_values) { decision_decline }
    let(:continue_next_steps) { ['CORI Hearing', 'Admin Cancel'] }
    let(:continue_status) { in_progress_status }

    def reach_review_decline!
      drive!(
        engine,
        [
          ['CoC Initial Review', coc_continue],
          ['Shelter Agency Initial Review', shelter_continue],
          ['Housing Case Manager Initial Review', intake_continue],
          ['Housing Case Manager Decision', decision_decline],
        ],
        user: user,
      )
    end

    it_behaves_like 'a review-decline sub-tree'

    it 'routes to CORI Hearing when a hearing is needed' do
      drive!(
        engine,
        [
          ['CoC Initial Review', coc_continue],
          ['Shelter Agency Initial Review', shelter_continue],
          ['Housing Case Manager Initial Review', intake_continue],
          ['Housing Case Manager Decision', decision_accept_with_cori],
        ],
        user: user,
      )

      expect_active_steps(engine, 'CORI Hearing', 'Admin Cancel')
    end
  end

  describe 'CORI Hearing sub-tree' do
    include_context 'housing workflow walkthrough'

    let(:review_decline_step) { 'Review Decline (CORI Hearing)' }
    let(:final_review_decline_step) { 'Final Review Decline (CORI Hearing)' }
    let(:reopened_step) { 'CORI Hearing (Second Attempt)' }
    let(:reopened_decline_values) { cori_decline }
    let(:continue_next_steps) { ['Move-In Date', 'Admin Cancel'] }
    let(:continue_status) { enrolled_status }

    def reach_review_decline!
      drive!(
        engine,
        [
          ['CoC Initial Review', coc_continue],
          ['Shelter Agency Initial Review', shelter_continue],
          ['Housing Case Manager Initial Review', intake_continue],
          ['Housing Case Manager Decision', decision_accept_with_cori],
          ['CORI Hearing', cori_decline],
        ],
        user: user,
      )
    end

    it_behaves_like 'a review-decline sub-tree'

    it 'advances to Create Enrollment when the CORI hearing continues' do
      drive!(
        engine,
        [
          ['CoC Initial Review', coc_continue],
          ['Shelter Agency Initial Review', shelter_continue],
          ['Housing Case Manager Initial Review', intake_continue],
          ['Housing Case Manager Decision', decision_accept_with_cori],
          ['CORI Hearing', cori_continue],
        ],
        user: user,
      )

      expect_active_steps(engine, 'Move-In Date', 'Admin Cancel')
      expect(referral.reload.target_enrollment).to be_present
    end
  end

  describe 'acceptance' do
    include_context 'housing workflow walkthrough'

    let(:decline_referral_node) { template.nodes.find { |node| node.name == 'Admin Cancel' } }

    it 'accepts the referral and records CE event result 1 when Confirm Success is completed' do
      advance_housing_workflow_to_post_enrollment!(engine)

      expect_active_steps(engine, 'Confirm Success', 'Admin Cancel')

      complete_user_step!(engine, 'Confirm Success', submitted_values: {}, user: user)

      expect_accepted(referral)
      expect(engine.active_steps).to be_empty

      decline_step = referral.workflow_instance.steps.find_by!(node: decline_referral_node)
      expect(decline_step.open?).to be(false)
    end

    it 'accepts the referral when routed through a CORI hearing' do
      advance_housing_workflow_to_post_enrollment!(engine, cori_hearing_needed: 'yes')

      complete_user_step!(engine, 'Confirm Success', submitted_values: {}, user: user)

      expect_accepted(referral)
    end
  end

  describe 'closure walkthrough' do
    include_context 'housing workflow walkthrough'

    it 'rejects the referral when Admin Cancel is completed after enrollment' do
      advance_housing_workflow_to_post_enrollment!(engine)

      enrollment = referral.reload.target_enrollment
      expect(enrollment).to be_present

      expect do
        complete_user_step!(
          engine,
          'Admin Cancel',
          submitted_values: {
            'coc_decline_reason' => 'client_has_declined_match',
            'referral_result' => '2',
          },
          user: user,
        )
        referral.reload
      end.to change(referral, :status).to('rejected').
        and change(referral, :target_enrollment).from(enrollment).to(nil)

      expect(engine.active_steps).to be_empty
    end
  end
end
