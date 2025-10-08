###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

require 'rails_helper'
require_relative 'ce_system_test_helper'

RSpec.feature 'CE Unit Management', type: :system do
  include_context 'ce system test helper'

  it 'admin creates units, provider creates opportunities' do
    visit "/projects/#{target_project.id}/units"
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
  end
end
