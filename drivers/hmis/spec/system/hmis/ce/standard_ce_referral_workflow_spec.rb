###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/ce_system_test_helper'

RSpec.feature 'Standard CE Referral Workflow', type: :system do
  include_context 'ce system test helper'

  before(:all) do
    if ENV['RUN_SYSTEM_TESTS'] == 'true'
      ds1 = GrdaWarehouse::DataSource.find_by!(hmis: 'localhost') # created in E2eSystemSuite.seed_hmis_json_forms!

      # Seed the CE Referral Step forms.
      # In the test env, JsonForms defaults to env_key: 'test', which picks up the Standard
      # workflow forms in lib/form_data/test/ce_referral_steps.
      HmisUtil::JsonForms.new(data_source_id: ds1.id, generate_cdeds: true).
        seed_record_form_definitions(roles: [:CE_REFERRAL_STEP])
      CeWorkflows::Shared::CeBuilderUtils.create_state_machine_custom_statuses(ds1)

      builder = CeWorkflows::Standard::WorkflowBuilder.new(ds1)
      builder.ensure_decline_reasons
      template = builder.build_standard_referral_workflow

      # The builder produces a draft template; publish it
      CeWorkflows::Shared::CeBuilderUtils.publish_template(template: template)
    end
  end

  after(:all) do
    if ENV['RUN_SYSTEM_TESTS'] == 'true'
      ds1 = GrdaWarehouse::DataSource.find_by!(hmis: 'localhost')

      # Clean up workflow definition related records, since they were created in before(:all) and not in fixtures.
      CeWorkflows::Shared::CeBuilderUtils.delete_template_and_associated_data('standard_referral', data_source: ds1)
      Hmis::Ce::CustomReferralStatus.where(data_source_id: ds1.id).delete_all
      Hmis::Ce::ReferralDeclineReason.where(data_source_id: ds1.id).delete_all

      # Cleanup seeded referral step forms that were created in before(:all)
      forms = Hmis::Form::Definition.where(role: :CE_REFERRAL_STEP)
      forms.each { |form| form.custom_data_element_definitions.delete_all }
      forms.delete_all
    end
  end

  # consistent time to avoid failures when run across day boundaries
  before(:each) { freeze_time }
  after(:each) { travel_back }

  let!(:ds1) { GrdaWarehouse::DataSource.hmis.find_by(hmis: 'localhost') } # created already
  let!(:client1) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Alice', last_name: 'A') }

  let!(:source_project) { create(:hmis_hud_project, data_source: ds1, ProjectType: 14) } # Coordinated Entry
  let!(:source_enrollment) { create(:hmis_hud_enrollment, data_source: ds1, project: source_project, client: client1, entry_date: 30.days.ago) }

  # Override the shared context's generic template with the published Standard workflow template.
  # The shared context's unit_group references `workflow_template`, so this wires the unit group to the Standard workflow.
  let!(:workflow_template) { Hmis::WorkflowDefinition::Template.published.find_by(identifier: 'standard_referral') }

  let!(:unit) { create(:hmis_unit, project: target_project, unit_group: unit_group, unit_type: sro_type) }
  let!(:opportunity) { create(:hmis_ce_opportunity, unit: unit, name: unit.name) }
  let!(:referral) do
    create(
      :hmis_ce_referral,
      opportunity: opportunity,
      client: client1,
      workflow_template: workflow_template,
      source_enrollment: source_enrollment,
      assignment_rules: [eligibility_rule, priority_rule].map(&:attributes),
    )
  end

  before do
    referral.workflow_engine.start_workflow!(user: admin)
  end

  def referral_path
    "/projects/#{target_project.id}/ce/referrals/#{referral.id}"
  end

  # Step-fill helpers, based on the Standard workflow's CE_REFERRAL_STEP forms.
  def fill_initial_review_continue(notes: 'Referral for Alice A is in progress')
    mui_radio_choose 'Continue', from: 'Decision'
    fill_in 'Notes', with: notes
  end

  def fill_initial_review_decline(notes: 'Declining at initial review', reason: 'Inability to complete intake')
    mui_radio_choose 'Decline', from: 'Decision'
    mui_radio_choose reason, from: 'Decline Reason'
    fill_in 'Notes', with: notes
  end

  def fill_provider_decision_accept(notes: 'Provider accepts')
    mui_radio_choose 'Accept', from: 'Decision'
    expect(page).to have_content('The client will be added to the project as Incomplete.')
    fill_in 'Notes', with: notes
  end

  def fill_provider_decision_decline(notes: 'Provider declines', reason: 'Inability to complete intake')
    mui_radio_choose 'Decline', from: 'Decision'
    mui_radio_choose reason, from: 'Decline Reason'
    fill_in 'Notes', with: notes
  end

  def fill_review_decline(decision:, notes: 'Reviewing the decline')
    fill_in 'Notes', with: notes
    mui_radio_choose decision, from: 'Decision'
  end

  def fill_confirm_placement(notes: 'Placement confirmed')
    fill_in 'Notes', with: notes
  end

  # Assertions that a limited-permission provider cannot perform CE-Team-only actions.
  # `active_ce_team_step` is the CE-Team step (if any) that is active while impersonating.
  def confirm_provider_cannot_do_ce_team_actions(active_ce_team_step: nil)
    # Assigning participants is CE-Team-only
    expect(page).not_to have_button('Contacts')

    if active_ce_team_step
      # The step is visible, but the provider can't work on it
      expect(page).to have_content("#{active_ce_team_step} Available Today")
      expect(page).not_to have_button("Start step: #{active_ce_team_step}")
    end

    # Cannot drill into the source enrollment since the provider lacks access
    # (see permission setup in ce_system_test_helper.rb)
    with_referral_panel_open('Details') do
      find("[role='button']", text: 'Source Enrollment Details').click
      expect(page).not_to have_content('Enrollment Link')
    end
  end

  # Shared method for the CE staff completing the Initial Review step and assigning the provider.
  def ce_staff_complete_initial_review_and_assign
    visit referral_path
    expect(page).to have_content('Referral for Alice A')

    complete_ce_step('Initial Review') do
      fill_initial_review_continue(notes: 'Referral for Alice A is in progress')
    end

    # Provider Decision step is now available but unassigned.
    expect(page).to have_content('Provider Decision Available Today')

    # Impersonate Paul Provider. Since they are not assigned, they can't see the referral yet.
    with_user_impersonated(provider.id) do
      click_link 'Dashboard'
      expect(page).to have_content('PAUL PROVIDER HMIS Dashboard')
      expect(page).to have_content('No referral tasks assigned to you')
      expect(page).not_to have_content('Alice A')
    end

    # As the CE staff, navigate back to the referral and assign Paul Provider to the Provider swimlane.
    visit referral_path
    assign_referral_contacts({ 'Provider': ['Paul Provider'] })

    with_referral_panel_open('Activity') do
      add_referral_note(note_text: 'Hello Paul, this referral is in your court now')
    end
  end

  it 'completes the happy path' do
    ce_staff_complete_initial_review_and_assign

    with_user_impersonated(provider.id) do
      visit referral_path
      expect(page).to have_content('Referral for Alice A')
      confirm_provider_cannot_do_ce_team_actions

      # Provider accepts the referral
      complete_ce_step('Provider Decision') do
        fill_provider_decision_accept(notes: 'Provider approves')
      end

      # Confirm Placement (CE-Team) is available, but the provider can't open it.
      expect(page).to have_content('Confirm Placement Available Today')
      expect(page).not_to have_button('Start step: Confirm Placement')

      # Target enrollment was auto-created
      expect(referral.reload.target_enrollment).to be_present
    end

    # CE staff completes the final Confirm Placement step
    visit referral_path
    complete_ce_step('Confirm Placement') do
      fill_confirm_placement(notes: 'Everything is good')
    end

    expect(referral.reload.status).to eq('accepted')
    expect(referral.target_enrollment).to be_present
    expect(referral.target_enrollment.current_unit).to eq(unit)
  end

  it 'declines at initial review' do
    visit referral_path
    expect(page).to have_content('Referral for Alice A')

    complete_ce_step('Initial Review') do
      fill_initial_review_decline(notes: 'Client is not eligible')
    end

    expect(referral.reload.status).to eq('rejected')
    expect(referral.target_enrollment).to be_nil
  end

  it 'completes the provider decline -> return to provider -> accept path' do
    ce_staff_complete_initial_review_and_assign

    with_user_impersonated(provider.id) do
      visit referral_path
      expect(page).to have_content('Referral for Alice A')
      confirm_provider_cannot_do_ce_team_actions

      # Provider declines the referral
      complete_ce_step('Provider Decision') do
        fill_provider_decision_decline(notes: 'Cannot accept right now')
      end

      # Review Decline (CE-Team) is available, but the provider can't open it.
      confirm_provider_cannot_do_ce_team_actions(active_ce_team_step: 'Review Decline')
    end

    # CE staff returns the referral to the provider
    visit referral_path
    complete_ce_step('Review Decline') do
      fill_review_decline(decision: 'Return to Provider Decision', notes: 'Please reconsider')
    end

    expect(page).to have_content('Provider Decision Available Today')

    # Provider re-completes the Provider Decision step, this time accepting
    with_user_impersonated(provider.id) do
      visit referral_path
      complete_ce_step('Provider Decision') do
        fill_provider_decision_accept(notes: 'Accepting this time')
      end

      expect(page).to have_content('Confirm Placement Available Today')
      expect(page).not_to have_button('Start step: Confirm Placement')
    end

    # CE staff completes the final Confirm Placement step
    visit referral_path
    complete_ce_step('Confirm Placement') do
      fill_confirm_placement(notes: 'Everything is good')
    end

    expect(referral.reload.status).to eq('accepted')
    expect(referral.target_enrollment).to be_present
    expect(referral.target_enrollment.current_unit).to eq(unit)
  end

  it 'completes the provider decline -> approve decline path' do
    ce_staff_complete_initial_review_and_assign

    with_user_impersonated(provider.id) do
      visit referral_path
      expect(page).to have_content('Referral for Alice A')
      confirm_provider_cannot_do_ce_team_actions

      # Provider declines the referral
      complete_ce_step('Provider Decision') do
        fill_provider_decision_decline(notes: 'Cannot accept')
      end

      # Review Decline (CE-Team) is available, but the provider can't open it.
      confirm_provider_cannot_do_ce_team_actions(active_ce_team_step: 'Review Decline')
    end

    # CE staff approves the decline
    visit referral_path
    complete_ce_step('Review Decline') do
      fill_review_decline(decision: 'Approve Decline', notes: 'Decline approved')
    end

    expect(referral.reload.status).to eq('rejected')
    expect(referral.target_enrollment).to be_nil
  end
end
