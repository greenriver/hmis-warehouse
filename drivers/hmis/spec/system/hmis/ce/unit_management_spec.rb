###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

require 'rails_helper'
require_relative '../../../support/ce_system_test_helper'

RSpec.feature 'CE Unit Management', type: :system do
  include_context 'ce system test helper'

  # Create clients that fulfill the pool requirements (score > 5)
  let!(:client1) do
    client = create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Alice', last_name: 'A')
    assessment = create(:hmis_custom_assessment, client: client, data_source: ds1, definition: form_definition)
    create(
      :hmis_custom_data_element,
      owner: assessment,
      data_element_definition: score_cded,
      value_string: '10',
      data_source: ds1,
    )
    client
  end

  let!(:client2) do
    client = create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Bob', last_name: 'B')
    assessment = create(:hmis_custom_assessment, client: client, data_source: ds1, definition: form_definition)
    create(
      :hmis_custom_data_element,
      owner: assessment,
      data_element_definition: score_cded,
      value_string: '8',
      data_source: ds1,
    )
    client
  end

  let!(:client3) do
    client = create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Carol', last_name: 'C')
    assessment = create(:hmis_custom_assessment, client: client, data_source: ds1, definition: form_definition)
    create(
      :hmis_custom_data_element,
      owner: assessment,
      data_element_definition: score_cded,
      value_string: '6',
      data_source: ds1,
    )
    client
  end

  # Create a client that doesn't meet requirements (score <= 5)
  let!(:ineligible_client) do
    client = create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Dan', last_name: 'D')
    assessment = create(:hmis_custom_assessment, client: client, data_source: ds1, definition: form_definition)
    create(
      :hmis_custom_data_element,
      owner: assessment,
      data_element_definition: score_cded,
      value_string: '3',
      data_source: ds1,
    )
    client
  end

  it 'admin creates units, provider creates opportunities, admin starts referral' do
    visit "/projects/#{target_project.id}/units"
    click_link 'Manage Unit Group SROs'
    expect(page).to have_content('No units.')

    click_button 'Add Units'
    fill_in 'Number of Units to Add', with: '2'
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

    with_user_impersonated(provider.id) do
      visit "/projects/#{target_project.id}/units"
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
      expect(opportunities.map(&:project)).to all(eq(target_project))

      click_button "Action menu for SRO - #{units.first.id}"
      mui_click_menu_item('View Unit')

      # Can see eligibility requirements and prioritization
      expect(page).to have_content('Eligibility Requirements')
      expect(page).to have_content('Prioritization')

      # Can't see the waitlist
      expect(page).not_to have_link('Eligible Clients')
    end

    # Admin can see the waitlist
    click_link 'Eligible Clients'
    expect(page).to have_content('The eligible client list for this unit has not been generated yet.')

    # Call the prioritization engine, then reload
    Hmis::Ce::Match::Engine.call(score_pool)
    score_pool.update!(candidates_generated_at: Time.current)
    visit current_path
    click_link 'Eligible Clients'

    # Verify eligible clients are shown (ordered by priority score descending)
    expect(page).to have_content('Alice A') # score 10
    expect(page).to have_content('Bob B')     # score 8
    expect(page).to have_content('Carol C')   # score 6
    expect(page).not_to have_content('Dan D') # score 3 (ineligible)

    # Start referral for the top prioritized client (Alice A)
    click_button 'Start Referral for Alice A'
    all('input[type=radio]', visible: :all).first.click # Select the first source enrollment
    click_button 'Create Referral' # Confirm in dialog
    expect(page).to have_content('Referral for Alice A')

    referral = Hmis::Ce::Referral.sole
    expect(referral.status).to eq('initialized') # Status is initialized because the basic factory workflow template doesn't have a "start" event
    expect(referral.client).to eq(client1)
    expect(referral.referred_by).to eq(admin)
    expect(referral.referral_origin).to eq('waitlist')
  end
end
