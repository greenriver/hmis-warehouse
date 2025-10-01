###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'Waitlist Referrals', type: :system do
  include_context 'hmis base setup'
  let!(:ds1) { create(:hmis_data_source, hmis: 'localhost') }
  let!(:p1) { create(:hmis_hud_project, data_source: ds1, ProjectType: 3) } # PSH

  let!(:admin) { create(:hmis_user, data_source: ds1, first_name: 'Alexandra', last_name: 'Admin') }
  let!(:provider) { create(:hmis_user, data_source: ds1, first_name: 'Paul', last_name: 'Provider') }
  let!(:other_user) { create(:hmis_user, data_source: ds1, first_name: 'Oliver', last_name: 'Other') } # user without permissions

  # Simplified permission scenario where admin has all permissions
  let!(:admin_ac) { create_access_control(admin, ds1) }
  let!(:provider_ac) do
    create_access_control(provider, ds1, with_permission: [
                            :can_view_project,
                            :can_view_clients,
                            :can_view_units, # but *not* can_manage_units
                            :can_update_unit_availability,
                            :can_view_own_referrals,
                            :can_perform_own_referral_tasks,
                          ])
  end

  before do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    HmisUtil::JsonForms.new(env_key: 'allegheny', generate_test_cdeds: true).seed_record_form_definitions(roles: [:CE_REFERRAL_STEP])
    CeWorkflows::Shared::CeBuilderUtils.create_state_machine_custom_statuses(ds1)
  end

  let!(:workflow_template) { CeWorkflows::Ac::WorkflowBuilder.new(ds1).build_housing_workflow }
  let!(:coc1) { create :hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'CO-500' }
  let!(:eligibility_rule) { create(:hmis_ce_match_rule, owner: p1, rule_type: 'eligibility_requirement', expression: 'cde.custom_assessment.score != NULL AND cde.custom_assessment.score > 5') }
  let!(:priority_rule) { create(:hmis_ce_match_rule, owner: p1, rule_type: 'priority_scheme', expression: 'cde.custom_assessment.score', priority_rank: 1) }
  let!(:form_definition) { create(:hmis_form_definition, identifier: 'score_assessment', role: :CUSTOM_ASSESSMENT, status: :published, version: 1) }
  let!(:score_cded) { create(:hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment', form_definition: form_definition, key: :score, label: 'Assessment Score', data_source: ds1) }
  let!(:score_pool) { create :hmis_ce_match_candidate_pool, requirement_expression: 'cde.custom_assessment.score != NULL AND cde.custom_assessment.score > 5', priority_expression: '{cde.custom_assessment.score}' }

  let!(:sro_type) { create(:hmis_unit_type, description: 'SRO') }
  let!(:unit_group) { create(:hmis_unit_group, project: p1, name: 'SROs', workflow_template: workflow_template, candidate_pool: score_pool) }
  let!(:project_ce_config) { create(:hmis_project_ce_config, project: p1, supports_waitlist_referrals: true) }

  before(:each) do
    sign_in(admin) # sign in as admin, impersonate provider
  end

  describe 'unit and opportunity management' do
    it 'admin creates units, provider creates opportunities' do
      visit "/projects/#{p1.id}/units"
      click_link 'Manage Unit Group SROs'
      expect(page).to have_content('No units.')

      click_button 'Add Units'
      fill_in 'Number of Units to Add', with: '2'
      mui_select 'SRO', from: 'Unit Type'
      all('button', text: 'Add Units').last.click

      table = find('table')
      rows = table.first('tbody').all('tr')
      expect(rows.count).to eq(2)
      mui_table_expect('Vacant', row_index: 0, column_header: 'Occupancy', from: table)
      mui_table_expect('Vacant', row_index: 1, column_header: 'Occupancy', from: table)

      expect(Hmis::Unit.count).to eq(2)
      units = Hmis::Unit.all.preload(:unit_type, :unit_group)
      expect(units.map(&:unit_type)).to all(eq(sro_type))
      expect(units.map(&:unit_group)).to all(eq(unit_group))

      with_user_impersonated('Paul Provider') do
        visit "/projects/#{p1.id}/units"
        click_link 'Manage Unit Group SROs'
        expect(page).not_to have_button('Add Units') # Can view, but not add units

        # Can mark units available
        select_all_checkbox = find("input[aria-label='select all']", visible: :all)
        select_all_checkbox.click
        click_button 'Start Accepting Referrals (2)'
        click_button 'Yes, start accepting referrals'
        mui_table_expect('Accepting Referrals', row_index: 0, column_header: 'Referral Status', from: table)
        mui_table_expect('Accepting Referrals', row_index: 1, column_header: 'Referral Status', from: table)

        expect(units.reload.map(&:latest_opportunity)).to all(be_present)
        expect(Hmis::Ce::Opportunity.count).to eq(2)
        opportunities = Hmis::Ce::Opportunity.all.preload(:project)
        expect(opportunities.map(&:status)).to all(eq('open'))
        expect(opportunities.map(&:project)).to all(eq(p1))

        click_button "Action menu for SRO - #{units.first.id}"
        mui_click_menu_item('View Unit')

        # Can see eligibility requirements and prioritization
        expect(page).to have_content('Eligibility Requirements')
        expect(page).to have_content('Prioritization')

        # Can't see the waitlist
        expect(page).not_to have_link('Eligible Clients')
      end

      # Admin can see the waitlist
      visit "/projects/#{p1.id}/unit/#{units.first.id}"
      click_link 'Eligible Clients'
      expect(page).to have_content('The eligible client list for this unit has not been generated yet.')
    end
  end

  describe 'waitlist referral workflow' do
    let!(:unit) { create(:hmis_unit, project: p1, unit_type: sro_type, unit_group: unit_group) }
    let!(:opportunity) { create(:hmis_ce_opportunity, project: p1, workflow_template: workflow_template, unit: unit, candidate_pool: score_pool, assignment_rules: [eligibility_rule, priority_rule].map(&:attributes), name: unit.name) }

    # Create clients that fulfill the pool requirements (score > 5)
    let!(:client1) do
      client = create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Alice', last_name: 'A')
      assessment = create(:hmis_custom_assessment, client: client, data_source: ds1, definition: form_definition)
      create(:hmis_custom_data_element,
             owner: assessment,
             data_element_definition: score_cded,
             value_string: '10',
             data_source: ds1)
      client
    end

    let!(:client2) do
      client = create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Bob', last_name: 'B')
      assessment = create(:hmis_custom_assessment, client: client, data_source: ds1, definition: form_definition)
      create(:hmis_custom_data_element,
             owner: assessment,
             data_element_definition: score_cded,
             value_string: '8',
             data_source: ds1)
      client
    end

    let!(:client3) do
      client = create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Carol', last_name: 'C')
      assessment = create(:hmis_custom_assessment, client: client, data_source: ds1, definition: form_definition)
      create(:hmis_custom_data_element,
             owner: assessment,
             data_element_definition: score_cded,
             value_string: '6',
             data_source: ds1)
      client
    end

    # Create a client that doesn't meet requirements (score <= 5)
    let!(:ineligible_client) do
      client = create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Dan', last_name: 'D')
      assessment = create(:hmis_custom_assessment, client: client, data_source: ds1, definition: form_definition)
      create(:hmis_custom_data_element,
             owner: assessment,
             data_element_definition: score_cded,
             value_string: '3',
             data_source: ds1)
      client
    end

    before do
      Hmis::Ce::Match::Engine.call(score_pool)
      score_pool.update!(candidates_generated_at: Time.current)
    end

    # Shared method for progressing the referral through the initial steps and assigning the provider
    def complete_ce_staff_initial_steps
      # Navigate to unit group and verify eligible clients appear
      visit "/projects/#{p1.id}/unit/#{unit.id}"
      click_link 'Eligible Clients'

      # Verify eligible clients are shown (ordered by priority score descending)
      expect(page).to have_content('Alice A') # score 10
      expect(page).to have_content('Bob B')     # score 8
      expect(page).to have_content('Carol C')   # score 6
      expect(page).not_to have_content('Dan D') # score 3 (ineligible)

      # Start referral for the top prioritized client (Alice A)
      within('tbody tr:first-child') do
        click_button 'Start Referral'
      end
      expect(page).to have_content('Start Referral')
      all('input[type=radio]', visible: :all).first.click # Select the first source enrollment
      click_button 'Create Referral' # Confirm in dialog

      referral = Hmis::Ce::Referral.sole
      expect(referral.status).to eq('in_progress')
      expect(referral.client).to eq(client1)
      expect(referral.referred_by).to eq(admin)
      expect(referral.referral_origin).to eq('waitlist')

      # Progress through Initial Review step
      click_button 'Start step: Initial Review'
      expect(page).to have_content('Back to All Tasks')
      mui_date_select 'Date', date: Date.current
      fill_in 'Notes', with: 'Referral for Alice A is in progress'
      mui_radio_choose 'Yes, continue', from: 'Continue with Referral?'
      click_button 'Submit'

      # Should return to referral overview
      expect(page).to have_content('Matching In Progress')

      # Progress through Initial Client Engagement step
      click_button 'Start step: Initial Client Engagement'
      mui_date_select 'Date', date: Date.current
      click_button 'Submit'

      # Progress through Client Engagement step
      click_button 'Start step: Client Engagement'
      mui_date_select 'Date', date: Date.current
      fill_in 'Notes', with: 'Client engaged with CE staff'
      mui_radio_choose 'Yes, continue', from: 'Continue with Referral?'
      click_button 'Submit'

      # Progress through Client Offer Outcome step
      click_button 'Start step: Client Offer Outcome'
      mui_date_select 'Date', date: Date.current
      fill_in 'Notes', with: 'Client is interested'
      mui_radio_choose 'Yes, continue', from: 'Continue with Referral?'
      click_button 'Submit'
      expect(page).to have_content('Provider Outcome Available Today') # the next task is available

      event = referral.source_enrollment.events.sole
      expect(event.event).to eq(14) # referral to PSH event type
      expect(event.location_crisis_or_ph_housing).to eq(p1.id.to_s)
      expect(event.referral_result).to be_nil

      # Provider Outcome step is now available but unassigned.
      # Impersonate Paul Provider. Since they are not assigned, they can't see the referral yet
      with_user_impersonated('Paul Provider') do
        click_link 'Dashboard'
        expect(page).to have_content('PAUL PROVIDER HMIS Dashboard')
        expect(page).to have_content('No referral tasks assigned to you')
        expect(page).not_to have_content('Alice A')
      end

      visit("/projects/#{p1.id}/ce/referrals/#{referral.id}") # Navigate back to the referral
      # Assign the Paul Provider user to the Provider Outcome step
      expect(page).to have_content('Provider Outcome Available Today Project Staff No assigned users')
      click_button 'Contacts'
      project_staff_choices = get_mui_choices(select_label: 'Project Staff')
      expect(project_staff_choices).to include('Paul Provider')
      expect(project_staff_choices).not_to include('Oliver Other')
      mui_select('Paul Provider', from: 'Project Staff')

      click_button 'Submit'
      expect(page).not_to have_content('No assigned users')
      expect(page).to have_content('Assigned to Paul Provider')

      # Add referral note
      click_button 'Activity'
      click_button 'Add Note'
      fill_in 'Note', with: 'Hello Paul, this referral is in your court now'
      click_button 'Submit Note'
      expect(page).to have_content('Note Hello Paul')
    end

    # Shared method for the CE staff completing final steps to approve the referral
    def complete_ce_staff_final_steps
      referral = Hmis::Ce::Referral.sole
      visit("/projects/#{p1.id}/ce/referrals/#{referral.id}")
      click_button 'Start step: Confirm Success'
      mui_date_select 'Date', date: Date.current
      fill_in 'Notes', with: 'Everything is good'
      click_button 'Submit'
      expect(page).to have_content('Referral Complete')
      expect(page).to have_content("Alice A has been accepted to #{unit.name}")

      expect(referral.reload.status).to eq('accepted')
      expect(referral.target_enrollment).to be_present
      expect(referral.target_enrollment.current_unit).to eq(unit)

      event = referral.source_enrollment.events.sole
      expect(event.referral_result).to eq(1) # successful referral: client accepted
    end

    # Shared method for navigating around the referral as a provider and validating functionality
    def confirm_provider_view
      click_link 'Dashboard'
      expect(page).to have_content('PAUL PROVIDER HMIS Dashboard')
      expect(page).to have_content('Provider Outcome Assigned Today')
      expect(page).to have_content('Alice A')

      # Click into the referral, view previous steps
      click_link 'Provider Outcome'
      click_link 'View step: Initial Review' # Can view previous steps completed by the admin
      expect(page).to have_content('Referral for Alice A is in progress') # Can see the previously submitted values
      click_link 'Back to All Tasks'

      # View and submit notes
      click_button 'Activity'
      expect(page).to have_content('Hello Paul, this referral is in your court now') # can see previous notes
      click_button 'Add Note'
      fill_in 'Note', with: 'Everything is good'
      click_button 'Submit Note'
      expect(page).to have_content('Note Everything is good')
      click_button 'close'

      expect(page).not_to have_button('Contacts') # Can't view contacts
      click_button 'Details'
      expect(page).to have_content('Assessment Score 10') # Can see prioritization/matching details like the assessment score
      find("[role='button']", text: 'Source Enrollment Details').click # Can view enrollment details
      expect(page).not_to have_content('Enrollment Link') # Can't click into the enrollment
      find('body').send_keys(:escape)
    end

    it 'completes the happy path' do
      complete_ce_staff_initial_steps

      # Impersonate Paul Provider and verify they can see the referral
      with_user_impersonated('Paul Provider') do
        confirm_provider_view

        # Provider approves the referral
        expect(page).to have_content('Provider Outcome Available Today Assigned to you')
        click_button 'Start step: Provider Outcome'
        mui_date_select 'Date', date: Date.current
        fill_in 'Notes', with: 'Provider approves'
        mui_radio_choose 'Accept - Add to Project', from: 'Decision'
        expect(page).to have_content('The client will be added to the project as Incomplete.')
        click_button 'Submit'

        # Confirm success task is available, but the provider user can't open it
        expect(page).to have_content('Confirm Success Available Today')
        expect(page).not_to have_button('Start step: Confirm Success')
      end

      complete_ce_staff_final_steps
    end

    it 'completes the denial -> send back path' do
      complete_ce_staff_initial_steps

      # Impersonate Paul Provider and verify they can see the referral
      with_user_impersonated('Paul Provider') do
        confirm_provider_view

        # Provider denies the referral
        expect(page).to have_content('Provider Outcome Available Today Assigned to you')
        click_button 'Start step: Provider Outcome'
        mui_date_select 'Date', date: Date.current
        fill_in 'Notes', with: 'Provider declines'
        mui_radio_choose 'Decline - Submit Referral for Denial Review', from: 'Decision'
        mui_radio_choose 'Inability to complete intake', from: 'Decline Reason'
        click_button 'Submit'

        # Denial Review task is available, but the provider user can't open it
        expect(page).to have_content('Denial Review Available Today')
        expect(page).not_to have_button('Start step: Denial Review')
      end

      referral = Hmis::Ce::Referral.sole
      visit("/projects/#{p1.id}/ce/referrals/#{referral.id}")
      click_button 'Start step: Denial Review'
      mui_date_select 'Date', date: Date.current
      fill_in 'Notes', with: 'No, send back!'
      mui_radio_choose 'Send Back', from: 'Decision'
      click_button 'Submit'
      expect(page).to have_content('Provider Outcome (Second Attempt)')

      with_user_impersonated('Paul Provider') do
        # This time, provider approves
        visit("/projects/#{p1.id}/ce/referrals/#{referral.id}")
        expect(page).to have_content('Provider Outcome (Second Attempt) Available Today Assigned to you')
        click_button 'Start step: Provider Outcome (Second Attempt)'
        mui_date_select 'Date', date: Date.current
        fill_in 'Notes', with: 'Provider accepts this time'
        mui_radio_choose 'Accept - Add to Project', from: 'Decision'
        expect(page).to have_content('The client will be added to the project as Incomplete.')
        click_button 'Submit'
        expect(page).to have_content('Confirm Success Available Today')
      end

      complete_ce_staff_final_steps
    end

    it 'completes the change provider outcome => denied path' do
      complete_ce_staff_initial_steps

      # Impersonate Paul Provider and verify they can see the referral
      with_user_impersonated('Paul Provider') do
        confirm_provider_view

        # Provider denies the referral
        expect(page).to have_content('Provider Outcome Available Today Assigned to you')
        click_button 'Start step: Provider Outcome'
        mui_date_select 'Date', date: Date.current
        fill_in 'Notes', with: 'Provider approves'
        mui_radio_choose 'Accept - Add to Project', from: 'Decision'
        expect(page).to have_content('The client will be added to the project as Incomplete.')
        click_button 'Submit'

        # Submit the Change Provider Outcome step to move the referral to denied pending status
        click_button 'Start step: Change Provider Outcome (Optional)'
        mui_date_select 'Date', date: Date.current
        fill_in 'Notes', with: 'Changing the result'
        mui_radio_choose 'Inability to complete intake', from: 'Decline Reason'
        expect(page).to have_content('The client\'s in-progress enrollment in this project will be deleted.')
        click_button 'Submit'
        expect(page).to have_content('Denial Review Available Today')
        expect(page).to have_content('Denial Pending')
      end

      referral = Hmis::Ce::Referral.sole
      visit("/projects/#{p1.id}/ce/referrals/#{referral.id}")
      click_button 'Start step: Denial Review'
      mui_date_select 'Date', date: Date.current
      mui_radio_choose 'Approve Denial', from: 'Decision'
      mui_radio_choose 'Inability to complete intake', from: 'Decline Reason'
      mui_radio_choose 'Unsuccessful referral: provider rejected', from: 'Referral Result'
      click_button 'Submit'
      expect(page).to have_content('Referral Declined')
      expect(page).to have_content("Alice A has been declined from #{unit.name}")

      expect(referral.reload.status).to eq('rejected')
      expect(referral.target_enrollment).to be_nil

      event = referral.source_enrollment.events.sole
      expect(event.referral_result).to eq(3) # unsuccessful referral: provider rejected
    end
  end

  describe 'direct referral' do
    # TODO @martha test for direct referral
  end
end
