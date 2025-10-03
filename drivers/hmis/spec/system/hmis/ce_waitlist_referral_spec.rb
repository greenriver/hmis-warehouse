###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'CE Waitlist Referrals', type: :system do
  include_context 'ce system test helper'

  let!(:unit) { create(:hmis_unit, project: target_project, unit_type: sro_type, unit_group: unit_group) }
  let!(:opportunity) { create(:hmis_ce_opportunity, project: target_project, workflow_template: workflow_template, unit: unit, candidate_pool: score_pool, assignment_rules: [eligibility_rule, priority_rule].map(&:attributes), name: unit.name) }

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
    visit "/projects/#{target_project.id}/unit/#{unit.id}"
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
    expect(event.location_crisis_or_ph_housing).to eq(target_project.id.to_s)
    expect(event.referral_result).to be_nil

    # Provider Outcome step is now available but unassigned.
    # Impersonate Paul Provider. Since they are not assigned, they can't see the referral yet
    with_user_impersonated('Paul Provider') do
      click_link 'Dashboard'
      expect(page).to have_content('PAUL PROVIDER HMIS Dashboard')
      expect(page).to have_content('No referral tasks assigned to you')
      expect(page).not_to have_content('Alice A')
    end

    visit("/projects/#{target_project.id}/ce/referrals/#{referral.id}") # Navigate back to the referral
    # Assign the Paul Provider user to the Provider Outcome step
    expect(page).to have_content('Provider Outcome Available Today Project Staff No assigned users')
    click_button 'Contacts'
    project_staff_choices = get_mui_select_choices(select_label: 'Project Staff')
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
    visit("/projects/#{target_project.id}/ce/referrals/#{referral.id}")
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
  def confirm_provider_functionality
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
      confirm_provider_functionality

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
      confirm_provider_functionality

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
    visit("/projects/#{target_project.id}/ce/referrals/#{referral.id}")
    click_button 'Start step: Denial Review'
    mui_date_select 'Date', date: Date.current
    fill_in 'Notes', with: 'No, send back!'
    mui_radio_choose 'Send Back', from: 'Decision'
    click_button 'Submit'
    expect(page).to have_content('Provider Outcome (Second Attempt)')

    with_user_impersonated('Paul Provider') do
      # This time, provider approves
      visit("/projects/#{target_project.id}/ce/referrals/#{referral.id}")
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
      confirm_provider_functionality

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
    visit("/projects/#{target_project.id}/ce/referrals/#{referral.id}")
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
