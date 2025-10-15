###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

require 'rails_helper'
require_relative '../../../support/ce_system_test_helper'

RSpec.feature 'AC CE Referral Workflows', type: :system do
  include_context 'ce system test helper'

  before(:all) do
    ds1 = GrdaWarehouse::DataSource.find_or_create_by!(hmis: 'localhost', name: 'HMIS')

    HmisUtil::JsonForms.new(env_key: 'allegheny', enable_cded_generation_in_test: true).seed_record_form_definitions(roles: [:CE_REFERRAL_STEP, :ENROLLMENT]) # Seed enrollment form so it collects units
    CeWorkflows::Shared::CeBuilderUtils.create_state_machine_custom_statuses(ds1)
    workflow_builder = CeWorkflows::Ac::WorkflowBuilder.new(ds1)
    workflow_builder.build_housing_workflow
    workflow_builder.build_admin_assign_workflow
  end

  after(:all) do
    # Clean up data source and workflow definition related records, since they were created in before(:all) and not in fixtures.
    # This helps avoid downstream issues in later tests.
    Hmis::WorkflowDefinition::Flow.delete_all
    Hmis::WorkflowDefinition::Node.delete_all
    Hmis::WorkflowDefinition::Swimlane.delete_all
    Hmis::WorkflowDefinition::Template.delete_all
    Hmis::Ce::CustomReferralStatus.delete_all
    GrdaWarehouse::DataSource.hmis.delete_all

    # Return enrollment form to normal. (See comment about form cleanup in rails_helper.rb)
    HmisUtil::JsonForms.new.seed_record_form_definitions(roles: [:ENROLLMENT])

    # Cleanup seeded referral step forms that were created in before(:all)
    Hmis::Form::Definition.where(role: :CE_REFERRAL_STEP).delete_all
    Hmis::Hud::CustomDataElementDefinition.delete_all
    Hmis::Hud::CustomDataElement.delete_all
  end

  let!(:ds1) { GrdaWarehouse::DataSource.hmis.find_by(hmis: 'localhost') } # created already
  let!(:client1) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Alice', last_name: 'A') }

  let!(:source_project) { create(:hmis_hud_project, data_source: ds1, ProjectType: 14) } # Coordinated Entry
  let!(:source_enrollment) { create(:hmis_hud_enrollment, data_source: ds1, project: source_project, client: client1, entry_date: 30.days.ago) }

  # Helpers for filling in steps in the AC workflow, many of which have the fields: date, notes, and "continue?"
  def fill_in_step_with_notes(notes: nil)
    notes ||= 'abcd'
    mui_date_select 'Date', date: Date.current
    fill_in 'Notes', with: notes
  end

  def fill_in_step_with_continue(notes: nil)
    fill_in_step_with_notes(notes: notes)
    mui_radio_choose 'Yes, continue', from: 'Continue with Referral?'
  end

  # Shared method for navigating around the referral as a provider and validating functionality
  def confirm_provider_functionality(client_name:, previous_step_name:, previous_step_content:, previous_note_text:)
    click_link 'Dashboard'
    expect(page).to have_content('PAUL PROVIDER HMIS Dashboard')
    expect(page).to have_content('Provider Outcome Assigned Today')
    expect(page).to have_content(client_name)

    # Provider can view the referral from the project referrals table
    visit "/projects/#{target_project.id}/ce#referrals"
    expect(page).to have_content('Displaying 1 of 1 referral')
    expect(page).to have_content(client_name)
    expect(page).to have_content('Assigned')
    click_link client_name

    # Can view previous steps completed by the admin
    click_link "View step: #{previous_step_name}"
    expect(page).to have_content('Completed Today by Alexandra Admin')
    expect(page).to have_content(previous_step_content)
    click_link 'Back to All Tasks'

    with_referral_panel_open('Activity') do
      # Can see the previously submitted note
      expect(page).to have_content(previous_note_text)
      # Can submit a new note
      add_referral_note(note_text: 'Everything is good')
    end

    expect(page).not_to have_button('Contacts') # Can't view contacts

    # Provider step is available
    expect(page).to have_content('Provider Outcome Available Today Assigned to you')
  end

  # Shared method for the CE staff completing final Confirm Success step to approve the referral
  def complete_ce_staff_confirm_success_step(client_name, unit)
    referral = Hmis::Ce::Referral.sole
    visit("/projects/#{target_project.id}/ce/referrals/#{referral.id}")
    expect(page).to have_content('Enrolled')
    expect(page).to have_content('Confirm Success Available Today')

    complete_ce_step('Confirm Success') do
      fill_in_step_with_notes(notes: 'Everything is good')
    end

    expect(page).to have_content('Referral Complete')
    expect(page).to have_content("#{client_name} has been accepted to #{unit.name}")

    expect(referral.reload.status).to eq('accepted')
    expect(referral.target_enrollment).to be_present
    expect(referral.target_enrollment.current_unit).to eq(unit)

    event = referral.source_enrollment.events.sole
    expect(event.referral_result).to eq(1) # successful referral: client accepted
  end

  describe 'direct referrals with admin assign workflow' do
    let!(:admin_assign_workflow_template) { Hmis::WorkflowDefinition::Template.find_by(identifier: 'admin_assign_workflow') } # created already

    let!(:source_project_ce_config) { create(:hmis_project_sends_direct_ce_referrals_config, project: source_project) }
    let!(:target_project) { create(:hmis_hud_project, data_source: ds1, ProjectType: 1, with_coc: true) } # Emergency Shelter

    let!(:unit_group) { create(:hmis_unit_group, project: target_project, workflow_template: admin_assign_workflow_template) }
    let!(:unit) { create(:hmis_unit, project: target_project, unit_group: unit_group) }
    let!(:opportunity) { create(:hmis_ce_opportunity, project: target_project, workflow_template: admin_assign_workflow_template, unit: unit, name: unit.name) }

    # Create household member for testing household referrals
    let!(:household_member) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Jane', last_name: 'D') }
    let!(:household_enrollment) { create(:hmis_hud_enrollment, data_source: ds1, project: source_project, client: household_member, entry_date: 30.days.ago, household_id: source_enrollment.household_id, relationship_to_ho_h: 2) }

    it 'completes the direct referral happy path' do
      # Navigate to source project and create the direct referral
      visit "/projects/#{source_project.id}/referrals"
      click_link 'Send Referral'
      mui_select('Alice A and 1 other', from: 'HoH Enrollment')
      mui_select(target_project.project_name, from: 'Project')
      mui_select(unit_group.name, from: 'Unit Group')
      fill_in 'Resource Coordinator Notes', with: 'Direct referral for Alice A to Family Shelter'
      click_button 'Refer Household'
      expect(page).to have_content('Displaying 1 of 1 outgoing referral')

      referral = Hmis::Ce::Referral.sole
      expect(referral.status).to eq('in_progress')
      expect(referral.client).to eq(client1)
      expect(referral.referred_by).to eq(admin)
      expect(referral.referral_origin).to eq('direct_send')
      expect(referral.source_enrollment).to eq(source_enrollment)

      visit("/projects/#{target_project.id}/ce/referrals/#{referral.id}")
      expect(page).to have_content('Referral for Alice A')
      assign_referral_contacts({ 'Project Staff': ['Paul Provider'] })

      with_referral_panel_open('Activity') do
        add_referral_note(note_text: 'Hi Paul, this is a directly assigned referral')
      end

      # Provider opens referral and completes the Provider Outcome task
      with_user_impersonated(provider.id) do
        confirm_provider_functionality(
          client_name: 'Alice A',
          previous_step_name: 'Admin Assign',
          previous_step_content: 'Direct referral for Alice A to Family Shelter',
          previous_note_text: 'Hi Paul, this is a directly assigned referral',
        )

        # Provider can see other household members on Details panel
        with_referral_panel_open('Details') do
          find("[role='button']", text: 'Source Enrollment Details').click
          expect(page).to have_content('Household Members')
          expect(page).to have_content('Alice A (HoH)') # Head of household
          expect(page).to have_content('Jane D (Child)') # Household member
        end

        complete_ce_step('Provider Outcome') do
          fill_in_step_with_notes(notes: 'Provider accepts direct referral')
          mui_radio_choose 'Accept - Add to Project', from: 'Decision'
          expect(page).to have_content('The client will be added to the project as Incomplete.')
        end

        # Confirm Success task is available but provider can't access it
        expect(page).to have_content('Confirm Success Available Today')
        expect(page).not_to have_button('Start step: Confirm Success')

        # Target enrollment was created
        target_enrollment = referral.reload.target_enrollment
        expect(target_enrollment).to be_present
        expect(target_enrollment.project).to eq(target_project)
        expect(target_enrollment.current_unit).to eq(unit)

        # Provider can add household members to the target enrollment
        visit "/client/#{client1.id}/enrollments/#{target_enrollment.id}/household"
        find("[role='button']", text: 'Add Household Member').click
        fill_in 'Search for Client', with: 'Jane D'
        click_button 'Search'
        click_button 'Add to Household'
        mui_select 'Child', from: 'Relationship to HoH'
        click_button 'Enroll'
        table = find("table[aria-label='Manage Household']")
        expect(page).not_to have_content('Enroll Jane D') # Confirm the modal has exited before proceeding
        mui_table_expect('Alice A', row_index: 0, column_header: 'Name', from: table)
        mui_table_expect('Jane D', row_index: 1, column_header: 'Name', from: table)

        # Household member was enrolled into the same unit
        expect(target_enrollment.reload.household_members.count).to eq(2)
        expect(target_enrollment.household_members.all.map(&:current_unit)).to eq([unit, unit])
      end

      # CE Staff completes the Confirm Success step
      complete_ce_staff_confirm_success_step('Alice A', unit)
    end
  end

  describe 'waitlist referrals with housing workflow' do
    let!(:workflow_template) { Hmis::WorkflowDefinition::Template.find_by(identifier: 'housing_workflow_v1') } # created already

    let!(:unit) { create(:hmis_unit, project: target_project, unit_group: unit_group) }
    let!(:opportunity) { create(:hmis_ce_opportunity, project: target_project, workflow_template: workflow_template, unit: unit, candidate_pool: score_pool, assignment_rules: [eligibility_rule, priority_rule].map(&:attributes), name: unit.name) }
    let!(:referral) { create(:hmis_ce_referral, opportunity: opportunity, unit: unit, client: client1, workflow_template: workflow_template, source_enrollment: source_enrollment) }

    before do
      referral.workflow_engine.start_workflow!(user: admin)
    end

    # Shared method for progressing the referral through the initial steps and assigning the provider
    def ce_staff_complete_initial_steps
      # Navigate to admin referrals page and click into the referral
      visit '/admin/referrals/'
      expect(page).to have_content('Alice A')
      expect(page).to have_content('Matching In Progress')
      click_link 'Alice A'
      expect(page).to have_content('Referral for Alice A')

      # Progress through Initial Review step
      complete_ce_step('Initial Review') do
        fill_in_step_with_continue(notes: 'Referral for Alice A is in progress')
      end

      # Should return to referral overview
      expect(page).to have_content('Matching In Progress')

      # Progress through Initial Client Engagement step
      complete_ce_step('Initial Client Engagement') do
        mui_date_select 'Date', date: Date.current
      end

      # Progress through Client Engagement step
      complete_ce_step('Client Engagement') do
        fill_in_step_with_continue(notes: 'Client engaged with CE staff')
      end

      # Progress through Client Offer Outcome step
      complete_ce_step('Client Offer Outcome') do
        fill_in_step_with_continue(notes: 'Client is interested')
      end
      expect(page).to have_content('Provider Outcome Available Today') # the next task is available

      event = referral.source_enrollment.events.sole
      expect(event.event).to eq(14) # referral to PSH event type
      expect(event.location_crisis_or_ph_housing).to eq(target_project.id.to_s)
      expect(event.referral_result).to be_nil

      # Provider Outcome step is now available but unassigned.
      # Impersonate Paul Provider. Since they are not assigned, they can't see the referral yet
      with_user_impersonated(provider.id) do
        click_link 'Dashboard'
        expect(page).to have_content('PAUL PROVIDER HMIS Dashboard')
        expect(page).to have_content('No referral tasks assigned to you')
        expect(page).not_to have_content('Alice A')
      end

      # As the CE staff, navigate back to the referral and assign Paul Provider as the provider contact
      visit("/projects/#{target_project.id}/ce/referrals/#{referral.id}")
      assign_referral_contacts({ 'Project Staff': ['Paul Provider'] })

      with_referral_panel_open('Activity') do
        add_referral_note(note_text: 'Hello Paul, this referral is in your court now')
      end
    end

    it 'completes the happy path' do
      ce_staff_complete_initial_steps

      # Impersonate Paul Provider and verify they can see the referral
      with_user_impersonated(provider.id) do
        confirm_provider_functionality(
          client_name: 'Alice A',
          previous_step_name: 'Initial Review',
          previous_step_content: 'Referral for Alice A is in progress',
          previous_note_text: 'Hello Paul, this referral is in your court now',
        )

        with_referral_panel_open('Details') do
          find("[role='button']", text: 'Source Enrollment Details').click # Can view enrollment details
          expect(page).not_to have_content('Enrollment Link') # Can't click into the enrollment
        end

        # Provider accepts the referral
        complete_ce_step('Provider Outcome') do
          fill_in_step_with_notes(notes: 'Provider approves')
          mui_radio_choose 'Accept - Add to Project', from: 'Decision'
          expect(page).to have_content('The client will be added to the project as Incomplete.')
        end

        # Confirm success task is available, but the provider user can't open it
        expect(page).to have_content('Confirm Success Available Today')
        expect(page).not_to have_button('Start step: Confirm Success')
      end

      complete_ce_staff_confirm_success_step('Alice A', unit)
    end

    it 'completes the denial -> send back path' do
      ce_staff_complete_initial_steps

      # Impersonate Paul Provider and verify they can see the referral
      with_user_impersonated(provider.id) do
        confirm_provider_functionality(
          client_name: 'Alice A',
          previous_step_name: 'Initial Review',
          previous_step_content: 'Referral for Alice A is in progress',
          previous_note_text: 'Hello Paul, this referral is in your court now',
        )

        with_referral_panel_open('Details') do
          find("[role='button']", text: 'Source Enrollment Details').click # Can view enrollment details
          expect(page).not_to have_content('Enrollment Link') # Can't click into the enrollment
        end

        # Provider denies the referral
        complete_ce_step('Provider Outcome') do
          fill_in_step_with_notes(notes: 'Provider declines')
          mui_radio_choose 'Decline - Submit Referral for Denial Review', from: 'Decision'
          mui_radio_choose 'Inability to complete intake', from: 'Decline Reason'
        end

        # Denial Review task is available, but the provider user can't open it
        expect(page).to have_content('Denial Review Available Today')
        expect(page).not_to have_button('Start step: Denial Review')
      end

      complete_ce_step('Denial Review') do
        fill_in_step_with_notes(notes: 'No, send back!')
        mui_radio_choose 'Send Back', from: 'Decision'
      end

      expect(page).to have_content('Provider Outcome (Second Attempt)')

      with_user_impersonated(provider.id) do
        expect(page).to have_content('Provider Outcome (Second Attempt) Available Today Assigned to you')

        complete_ce_step('Provider Outcome (Second Attempt)') do
          fill_in_step_with_notes(notes: 'Provider accepts this time')
          mui_radio_choose 'Accept - Add to Project', from: 'Decision'
          expect(page).to have_content('The client will be added to the project as Incomplete.')
        end

        expect(page).to have_content('Confirm Success Available Today')
      end

      complete_ce_staff_confirm_success_step('Alice A', unit)
    end

    it 'completes the change provider outcome => denied path' do
      ce_staff_complete_initial_steps

      # Impersonate Paul Provider and verify they can see the referral
      with_user_impersonated(provider.id) do
        confirm_provider_functionality(
          client_name: 'Alice A',
          previous_step_name: 'Initial Review',
          previous_step_content: 'Referral for Alice A is in progress',
          previous_note_text: 'Hello Paul, this referral is in your court now',
        )

        # Provider denies the referral
        complete_ce_step('Provider Outcome') do
          fill_in_step_with_notes(notes: 'Provider approves')
          mui_radio_choose 'Accept - Add to Project', from: 'Decision'
          expect(page).to have_content('The client will be added to the project as Incomplete.')
        end

        # Submit the Change Provider Outcome step to move the referral to denied pending status
        complete_ce_step('Change Provider Outcome (Optional)') do
          fill_in_step_with_notes(notes: 'Changing the result')
          mui_radio_choose 'Inability to complete intake', from: 'Decline Reason'
          expect(page).to have_content('The client\'s in-progress enrollment in this project will be deleted.')
        end

        expect(page).to have_content('Denial Review Available Today')
        expect(page).to have_content('Denial Pending')
      end

      complete_ce_step('Denial Review') do
        mui_date_select 'Date', date: Date.current
        mui_radio_choose 'Approve Denial', from: 'Decision'
        mui_radio_choose 'Inability to complete intake', from: 'Decline Reason'
        mui_radio_choose 'Unsuccessful referral: provider rejected', from: 'Referral Result'
      end

      expect(page).to have_content('Referral Declined')
      expect(page).to have_content("Alice A has been declined from #{unit.name}")

      referral = Hmis::Ce::Referral.sole
      expect(referral.reload.status).to eq('rejected')
      expect(referral.target_enrollment).to be_nil

      event = referral.source_enrollment.events.sole
      expect(event.referral_result).to eq(3) # unsuccessful referral: provider rejected
    end
  end
end
