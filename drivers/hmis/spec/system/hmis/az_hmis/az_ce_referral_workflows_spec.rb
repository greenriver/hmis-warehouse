###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

require 'rails_helper'
require_relative '../../../support/ce_system_test_helper'

# Browser coverage for the AZ Direct Referral workflow.
#
# The unit spec (workflow_builder_spec) already walks every gateway branch by posting
# submitted_values directly. This file exists because that bypasses the frontend: the
# hidden `decline_reason` field is autofilled in the browser from whichever of
# `declined_reason` / `canceled_reason` the user answered, and only then submitted.
# If the autofill breaks, ReferralMessageHandler never records a ReferralDeclineReason
# even though the unit spec would still pass.
#
# Five paths, chosen so each autofill rule and each cancel-gateway branch is hit once:
#   1. full accept (no decline reason; Post Referral Review Successful = Yes)
#   2. decline at Provider Acknowledgement  -> declined_reason autofill on the ack form
#   3. cancel at Provider Acknowledgement with a Client Refused reason
#        -> canceled_reason autofill on the ack form, HUD result 2
#   4. decline at Provider Decision         -> declined_reason autofill on the decision form
#   5. cancel at Provider Decision with a non-client-refused reason
#        -> canceled_reason autofill on the decision form, HUD result 3
RSpec.feature 'AZ CE Referral Workflows', type: :system do
  include_context 'ce system test helper'

  before(:all) do
    # A somewhat surprising system test gotcha: since rspec runs before(:all) before before(:each),
    # and we skip system tests using a before(:each) in e2e_setup.rb,
    # this code in the before(:all) will still execute during a regular, non-system test run on CI.
    # To prevent errors because ds1 doesn't exist yet, re-check for RUN_SYSTEM_TESTS and don't do anything if not set.
    if ENV['RUN_SYSTEM_TESTS'] == 'true'
      ds1 = GrdaWarehouse::DataSource.find_by!(hmis: 'localhost')

      # Seed AZ Referral Step forms (Send, Acknowledgement, Decision, Post Referral Review).
      HmisUtil::JsonForms.new(data_source_id: ds1.id, env_key: 'az', generate_cdeds: true).
        seed_record_form_definitions(roles: [:CE_REFERRAL_STEP])
      CeWorkflows::Shared::CeBuilderUtils.create_state_machine_custom_statuses(ds1)
      workflow_builder = CeWorkflows::Az::WorkflowBuilder.new(ds1)
      # Decline reasons must exist before the template validator runs: it checks that every
      # pick-list code on the step forms has a matching ReferralDeclineReason row.
      workflow_builder.ensure_decline_reasons
      workflow_builder.build_mc_direct_referral_workflow
    end
  end

  after(:all) do
    if ENV['RUN_SYSTEM_TESTS'] == 'true'
      ds1 = GrdaWarehouse::DataSource.find_by!(hmis: 'localhost')

      # Clean up workflow definition related records, since they were created in before(:all) and not in fixtures.
      # This helps avoid downstream issues in later tests.
      CeWorkflows::Shared::CeBuilderUtils.delete_template_and_associated_data('mc_direct_referral', data_source: ds1)
      Hmis::Ce::CustomReferralStatus.delete_all
      Hmis::Ce::ReferralDeclineReason.delete_all

      # Cleanup seeded referral step forms that were created in before(:all)
      forms = Hmis::Form::Definition.where(role: :CE_REFERRAL_STEP)
      forms.each { |form| form.custom_data_element_definitions.delete_all }
      forms.delete_all
    end
  end

  # consistent time for avoid failures when run across day boundaries
  before(:each) { freeze_time }
  after(:each) { travel_back }

  let!(:ds1) { GrdaWarehouse::DataSource.hmis.find_by(hmis: 'localhost') } # created already
  let!(:client1) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Alice', last_name: 'A') }

  # Override the helper's dummy template so the unit group created below uses the AZ workflow.
  let!(:workflow_template) { Hmis::WorkflowDefinition::Template.find_by(identifier: 'mc_direct_referral') }

  let!(:source_project) { create(:hmis_hud_project, data_source: ds1, ProjectType: 14) } # Coordinated Entry
  let!(:source_project_ce_config) { create(:hmis_project_sends_direct_ce_referrals_config, project: source_project) }
  let!(:source_enrollment) { create(:hmis_hud_enrollment, data_source: ds1, project: source_project, client: client1, entry_date: 30.days.ago) }

  # Each example needs its own open opportunity: sending a referral reserves/closes it.
  let!(:unit) { create(:hmis_unit, project: target_project, unit_group: unit_group, unit_type: sro_type) }
  let!(:opportunity) { create(:hmis_ce_opportunity, unit: unit, name: unit.name) }

  # BOOLEAN items render as exclusive Yes/No checkboxes (YesNoRadio), not radios, so Capybara's
  # `choose` does not work. Click the label inside the fieldset identified by the question text.
  def choose_yes_no(choice, from:)
    scroll_to("[aria-label='#{from}']")
    within("[aria-label='#{from}']") do
      find('label', text: choice).click
    end
  end

  # Fills and submits the Send Referral shell (HoH / Project / Unit Group) plus the AZ
  # "Referral Sent" step form, then opens the resulting referral as CE staff.
  def send_direct_referral!
    visit "/projects/#{source_project.id}/referrals"
    click_link 'Send Referral'
    mui_select('Alice A', from: 'HoH Enrollment')
    mui_select(target_project.project_name, from: 'Project')
    mui_select(unit_group.name, from: 'Unit Group')

    # Referral Date defaults to today via $today.
    mui_radio_choose 'PSH', from: 'Referral Type'
    fill_in 'Case Manager', with: 'Casey Manager'
    click_button 'Refer Household'
    expect(page).to have_content('Displaying 1 of 1 outgoing referral')

    referral = Hmis::Ce::Referral.sole
    visit("/projects/#{target_project.id}/ce/referrals/#{referral.id}")
    expect(page).to have_content('Referral for Alice A')
    expect(page).to have_content('Pending')
    expect(page).to have_content('Provider Acknowledgement Available Today')
    referral
  end

  # Completes Provider Acknowledgement as Under Review, which is the only non-terminal
  # acknowledgement choice. Leaves Provider Decision open and the CE Event without a result.
  def acknowledge_under_review!
    complete_ce_step('Provider Acknowledgement') do
      # Referral Review Start defaults to today.
      mui_radio_choose 'Under Review', from: 'Initial Decision'
      # Neither reason list should appear: both are enable_when'd on declined/canceled.
      expect(page).not_to have_content('Declined Reason')
      expect(page).not_to have_content('Canceled Reason')
    end
    expect(page).to have_content('Provider Decision Available Today')
  end

  # Shared assertions for a closed decline/cancel. `referral.decline_reason` is the thing the
  # hidden autofill has to populate: set_referral_decline_reason reads only link_id
  # `decline_reason`, which the user never types into.
  def expect_closed_with_reason(referral, custom_status_key:, decline_reason_key:, result:)
    expect(page).to have_content('Referral Complete')
    expect(page).to have_content("Alice A has been declined from #{unit.name}")

    referral.reload
    expect(referral.status).to eq('rejected')
    expect(referral.custom_status.key).to eq(custom_status_key)
    expect(referral.decline_reason.key).to eq(decline_reason_key)
    expect(referral.ce_event.referral_result).to eq(result)
  end

  it 'completes the happy path through Post Referral Review' do
    send_direct_referral!
    acknowledge_under_review!

    complete_ce_step('Provider Decision') do
      mui_radio_choose 'Accepted', from: 'Referral Outcome'
      expect(page).to have_content('The client will be added to the project as Incomplete.')
      # Accepting does not ask for a reason.
      expect(page).not_to have_content('Declined Reason')
      expect(page).not_to have_content('Canceled Reason')
    end

    expect(page).to have_content('Post Referral Review Available Today')

    referral = Hmis::Ce::Referral.sole
    expect(referral.reload.status).to eq('in_progress')
    expect(referral.target_enrollment).to be_present
    expect(referral.ce_event.referral_result).to eq(1)
    expect(referral.decline_reason).to be_nil

    # Successful = Yes is what actually accepts the referral. The CE Event result was
    # already written as 1 at Provider Decision; this step does not rewrite it.
    complete_ce_step('Post Referral Review') do
      choose_yes_no 'Yes', from: 'PSH Documents'
      choose_yes_no 'Yes', from: 'PSH Inspection'
      choose_yes_no 'Yes', from: 'Successful'
    end

    expect(page).to have_content('Referral Complete')
    expect(page).to have_content("Alice A has been accepted to #{unit.name}")
    expect(referral.reload.status).to eq('accepted')
    expect(referral.custom_status.key).to eq('accepted')
    expect(referral.ce_event.referral_result).to eq(1)
    expect(referral.decline_reason).to be_nil
  end

  it 'declines at Provider Acknowledgement and records the hidden decline reason' do
    # Covers the acknowledgement form's autofill_when on initial_decision = declined.
    # The provider only sees the 2-option Declined Reason list; Client Refused options
    # must not appear. The hidden field copies program_declines_to_accept into decline_reason.
    send_direct_referral!

    complete_ce_step('Provider Acknowledgement') do
      mui_radio_choose 'Declined', from: 'Initial Decision'
      expect(page).to have_content('Declined Reason')
      expect(page).not_to have_content('Canceled Reason')
      expect(page).not_to have_content('Client Refused')
      mui_radio_choose 'Declined: Program declines to accept', from: 'Declined Reason'
    end

    expect_closed_with_reason(
      Hmis::Ce::Referral.sole,
      custom_status_key: 'rejected', # labeled "Declined"
      decline_reason_key: 'program_declines_to_accept',
      result: 3, # Unsuccessful referral: provider rejected
    )
  end

  it 'cancels at Provider Acknowledgement with a Client Refused reason' do
    # Covers the acknowledgement form's autofill_when on initial_decision = canceled,
    # plus the client-rejected (2) gateway branch that reads canceled_reason directly.
    send_direct_referral!

    complete_ce_step('Provider Acknowledgement') do
      mui_radio_choose 'Canceled', from: 'Initial Decision'
      expect(page).to have_content('Canceled Reason')
      expect(page).not_to have_content('Declined Reason')
      expect(page).not_to have_content('Program declines to accept')
      mui_select "Client Refused: Didn't want unit / program", from: 'Canceled Reason'
    end

    expect_closed_with_reason(
      Hmis::Ce::Referral.sole,
      custom_status_key: 'canceled',
      decline_reason_key: 'client_refused_didnt_want_unit_program',
      result: 2, # Unsuccessful referral: client rejected
    )
  end

  it 'declines at Provider Decision and records the hidden decline reason' do
    # Same autofill mechanism as the acknowledgement decline, but the condition is
    # referral_outcome = declined on a different form. A typo in that autofill_when
    # would pass the acknowledgement examples and fail only here.
    send_direct_referral!
    acknowledge_under_review!

    complete_ce_step('Provider Decision') do
      mui_radio_choose 'Declined', from: 'Referral Outcome'
      expect(page).to have_content('Declined Reason')
      expect(page).not_to have_content('Canceled Reason')
      expect(page).not_to have_content('Client Refused')
      mui_radio_choose 'Declined: Referral not acted on', from: 'Declined Reason'
    end

    expect_closed_with_reason(
      Hmis::Ce::Referral.sole,
      custom_status_key: 'rejected',
      decline_reason_key: 'referral_not_acted_on',
      result: 3,
    )
  end

  it 'cancels at Provider Decision with a non-client-refused reason' do
    # Covers the decision form's canceled_reason autofill and the default cancel
    # gateway (provider rejected, 3). Together with the Client Refused acknowledgement
    # path, this is the pair of cancel branches without walking every reason code.
    send_direct_referral!
    acknowledge_under_review!

    complete_ce_step('Provider Decision') do
      mui_radio_choose 'Canceled', from: 'Referral Outcome'
      expect(page).to have_content('Canceled Reason')
      expect(page).not_to have_content('Declined Reason')
      mui_select 'Client Ineligible: Income criteria', from: 'Canceled Reason'
    end

    expect_closed_with_reason(
      Hmis::Ce::Referral.sole,
      custom_status_key: 'canceled',
      decline_reason_key: 'ineligible_income_criteria',
      result: 3,
    )
  end
end
