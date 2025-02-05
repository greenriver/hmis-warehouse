###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

#  Copyright 2016 - 2025 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'Split Households', type: :system do
  include_context 'hmis base setup'
  let!(:ds1) { create(:hmis_data_source, hmis: 'localhost') }
  let!(:access_control) { create_access_control(hmis_user, p1) }

  let!(:donor_household_id) { Hmis::Hud::Base.generate_uuid }
  let!(:prior_hoh) { create :hmis_hud_client, data_source: ds1, first_name: 'Apple', last_name: 'Orange' }
  let!(:new_hoh) { create :hmis_hud_client, data_source: ds1, first_name: 'Watermelon', last_name: 'Grapefruit' }
  let!(:child) { create :hmis_hud_client, data_source: ds1, first_name: 'Pear', last_name: 'Mango' }

  let!(:prior_hoh_e) { create :hmis_hud_enrollment, client: prior_hoh, data_source: ds1, project: p1, household_id: donor_household_id, relationship_to_hoh: 1, entry_date: 2.weeks.ago }
  let!(:new_hoh_e) { create :hmis_hud_enrollment, client: new_hoh, data_source: ds1, project: p1, household_id: donor_household_id, relationship_to_hoh: 3, entry_date: 2.weeks.ago }
  let!(:child_e) { create :hmis_hud_enrollment, client: child, data_source: ds1, project: p1, household_id: donor_household_id, relationship_to_hoh: 2, entry_date: 2.weeks.ago }

  before(:each) do
    sign_in(hmis_user)
    visit "/client/#{prior_hoh.id}/enrollments/#{prior_hoh_e.id}/household"
    click_link 'Manage Household'
    assert_text 'Edit Household'
    find("button[aria-label='Action menu for #{new_hoh.brief_name}").click
    find("li[aria-label='Split #{new_hoh.brief_name} to new household']").click
    assert_text 'STEP 1 Select Clients'
  end

  describe 'select clients screen' do
    it 'selects the initiator and disallows selecting HoH' do
      hoh_checkbox = find("input[aria-label='Select #{prior_hoh.brief_name}']", visible: :all)
      expect(hoh_checkbox.disabled?).to be_truthy
      expect(hoh_checkbox.checked?).to be_falsey

      new_hoh_checkbox = find("input[aria-label='Select #{new_hoh.brief_name}']", visible: :all)
      expect(new_hoh_checkbox.checked?).to be_truthy

      child_checkbox = find("input[aria-label='Select #{child.brief_name}']", visible: :all)
      expect(child_checkbox.checked?).to be_falsey
      child_checkbox.click
      expect(child_checkbox.checked?).to be_truthy

      click_button 'Add Relationships'
      assert_text 'STEP 2 Add Relationships'
    end

    it 'disables proceeding if you de-select all clients' do
      find("input[aria-label='Select #{new_hoh.brief_name}']", visible: :all).click
      next_button = find_button('Add Relationships', disabled: :all)
      expect(next_button.disabled?).to be_truthy
    end
  end

  describe 'add relationships screen' do
    before(:each) do
      find("input[aria-label='Select #{child.brief_name}']", visible: :all).click
      click_button 'Add Relationships'
      assert_text 'STEP 2 Add Relationships'
    end

    it 'requires you to enter relationships' do
      table = find("table[aria-label='Add Relationships']")
      rows = table.first('tbody').all('tr')
      next_button = find_button('Review Split', disabled: :all)
      expect(rows.count).to eq(2)
      expect(next_button.disabled?).to be_truthy

      mui_table_select 'Self (HoH)', row: new_hoh.brief_name, column: 'Relationship', from: table
      mui_table_select 'Child', row: child.brief_name, column: 'Relationship', from: table

      next_button = find_button('Review Split')
      expect(next_button.disabled?).to be_falsey
      next_button.click
      assert_text 'STEP 3 Review Split'
    end
  end

  describe 'review join and submit' do
    before(:each) do
      find("input[aria-label='Select #{child.brief_name}']", visible: :all).click
      click_button 'Add Relationships'
      assert_text 'STEP 2 Add Relationships'
      table = find("table[aria-label='Add Relationships']")
      mui_table_select 'Self (HoH)', row: new_hoh.brief_name, column: 'Relationship', from: table
      mui_table_select 'Child', row: child.brief_name, column: 'Relationship', from: table
      click_button 'Review Split'
    end

    it 'correctly displays the info about the split' do
      split_table = find("table[aria-label='Split Household']")
      mui_table_expect(new_hoh.brief_name, row_index: 0, column_header: 'Client Name', from: split_table)
      mui_table_expect('HoH', row_index: 0, column_header: 'Relationship', from: split_table)
      mui_table_expect(child.brief_name, row_index: 1, column_header: 'Client Name', from: split_table)
      mui_table_expect('Child', row_index: 1, column_header: 'Relationship', from: split_table)

      remaining_table = find("table[aria-label='Remaining Household']")
      mui_table_expect(prior_hoh.brief_name, row_index: 0, column_header: 'Client Name', from: remaining_table)
      mui_table_expect('HoH', row_index: 0, column_header: 'Relationship', from: remaining_table)
    end

    it 'submits the mutation and shows success' do
      click_button 'Split Enrollments'
      assert_text 'Successful Split'
      click_button "Return to #{prior_hoh.brief_name}’s Enrollment"
      table = find("table[aria-label='Manage Household']")
      rows = table.first('tbody').all('tr')
      expect(rows.count).to eq(1)
    end
  end
end
