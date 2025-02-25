###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'Join Households', type: :system do
  include_context 'hmis base setup'
  let!(:ds1) { create(:hmis_data_source, hmis: 'localhost') }

  let!(:c1) { create :hmis_hud_client, data_source: ds1, first_name: 'Apple', last_name: 'Orange' }
  let!(:receiving_enrollment) { create :hmis_hud_enrollment, client: c1, data_source: ds1, project: p1, entry_date: 2.weeks.ago }

  let!(:c2) { create :hmis_hud_client, data_source: ds1, first_name: 'Watermelon', last_name: 'Grapefruit' }
  let!(:c3) { create :hmis_hud_client, data_source: ds1, first_name: 'Pear', last_name: 'Mango' }

  let!(:access_control) { create_access_control(hmis_user, p1) }

  let(:today) { Date.current }

  before(:each) do
    sign_in(hmis_user)
    visit "/client/#{c1.id}/enrollments/#{receiving_enrollment.id}/household"
    find("[role='button']", text: 'Add Household Member').click # expand search card
    fill_in 'Search for Client', with: c2.brief_name
    click_button 'Search'
    click_button 'Add to Household'
    assert_text "Enroll #{c2.brief_name}"
    mui_select 'Spouse or partner', from: 'Relationship to HoH'
  end

  context 'when client has a conflicting enrollment' do
    let!(:donor_household_id) { Hmis::Hud::Base.generate_uuid }
    let!(:joining_e1) { create :hmis_hud_enrollment, client: c2, data_source: ds1, project: p1, entry_date: 2.weeks.ago, household_id: donor_household_id }
    let!(:joining_e2) { create :hmis_hud_enrollment, client: c3, data_source: ds1, project: p1, entry_date: 2.weeks.ago, relationship_to_hoh: 2, household_id: donor_household_id }

    before(:each) do
      click_button 'Enroll'
      assert_text 'Conflicting Enrollment'
      click_button 'Join Enrollments'
      assert_text 'STEP 1 Select Clients'
    end

    describe 'select clients screen' do
      let!(:rows) { find("table[aria-label='Select Clients']").first('tbody').all('tr') }
      let!(:hoh_cells) { rows.first.all('td') }
      let!(:hoh_checkbox) { hoh_cells[0].first("span input[type='checkbox']", visible: :all) } # MUI hides the actual input
      let!(:hhm_cells) { rows.last.all('td') }
      let!(:hhm_checkbox) { hhm_cells[0].first("span input[type='checkbox']", visible: :all) }

      it 'auto-selects the joining client and selects all HHM' do
        assert_text 'Head of Household Selected'
        expect(rows.count).to eq(2)
        expect(hoh_cells[1].text).to eq(c2.brief_name)
        expect(hoh_checkbox.checked?).to be_truthy
        expect(hoh_checkbox.disabled?).to be_falsey # HoH could be deselected
        expect(hhm_cells[1].text).to eq(c3.brief_name)
        expect(hhm_checkbox.checked?).to be_truthy
        expect(hhm_checkbox.disabled?).to be_truthy # as long as HoH is selected, other hhm cannot be deselected
        click_button 'Add Relationships'
        assert_text 'STEP 2 Add Relationships'
      end

      it 'disables proceeding if you de-select the joining client' do
        hoh_checkbox.click # click to deselect
        hhm_checkbox.click
        next_button = find('button', text: 'Add Relationships', visible: :all)
        expect(next_button.disabled?).to be_truthy # can't proceed
      end
    end

    describe 'add relationships screen' do
      before(:each) do
        click_button 'Add Relationships'
        assert_text 'STEP 2 Add Relationships'
      end

      it 'requires you to enter relationships' do
        table = find("table[aria-label='Add Relationships']")
        rows = table.first('tbody').all('tr')
        next_button = find('button', text: 'Review Join', visible: :all)
        expect(rows.count).to eq(3)
        expect(next_button.disabled?).to be_truthy

        mui_table_expect(c1.brief_name, row_index: 0, column_header: 'Client Name', from: table)
        mui_table_expect('Self (HoH)', row_index: 0, column_header: 'Relationship', from: table)

        mui_table_expect(c2.brief_name, row_index: 1, column_header: 'Client Name', from: table)
        mui_table_select 'Spouse or partner', row: c2.brief_name, column: 'Relationship', from: table

        mui_table_expect(c3.brief_name, row_index: 2, column_header: 'Client Name', from: table)
        mui_table_select 'Other relative', row: c3.brief_name, column: 'Relationship', from: table

        next_button = find('button', text: 'Review Join', visible: :all)
        expect(next_button.disabled?).to be_falsey
        next_button.click
        assert_text 'STEP 3 Review Join'
      end
    end

    describe 'review join and submit' do
      before(:each) do
        click_button 'Add Relationships'
        table = find("table[aria-label='Add Relationships']")
        mui_table_select 'Spouse or partner', row: c2.brief_name, column: 'Relationship', from: table
        mui_table_select 'Other relative', row: c3.brief_name, column: 'Relationship', from: table
        click_button 'Review Join'
      end

      it 'correctly displays the info about the join' do
        table = find("table[aria-label='Joining Household']")
        mui_table_expect(c1.brief_name, row_index: 0, column_header: 'Client Name', from: table)
        mui_table_expect('HoH', row_index: 0, column_header: 'Relationship', from: table)
        mui_table_expect(c2.brief_name, row_index: 1, column_header: 'Client Name', from: table)
        mui_table_expect('Spouse or partner', row_index: 1, column_header: 'Relationship', from: table)
        mui_table_expect(c3.brief_name, row_index: 2, column_header: 'Client Name', from: table)
        mui_table_expect('Other relative', row_index: 2, column_header: 'Relationship', from: table)
      end

      it 'submits the mutation and shows success' do
        click_button 'Join Enrollments'
        assert_text 'Successful Join'
        click_button "Return to #{c1.brief_name}’s Enrollment"
        table = find("table[aria-label='Manage Household']")
        rows = table.first('tbody').all('tr')
        expect(rows.count).to eq(3)
      end
    end
  end

  context 'when there is no conflicting enrollment' do
    it 'enrolls the client in the household' do
      expect do
        click_button 'Enroll'
        assert_no_selector "[role='dialog']" # wait for dialog to close
        assert_text c2.brief_name

        header_cells = first('thead').all('th')
        name_index = header_cells.find_index { |cell| cell.text == 'Name' }
        relationship_index = header_cells.find_index { |cell| cell.text == 'Relationship to HoH' }
        expect(name_index).not_to be_nil
        expect(relationship_index).not_to be_nil

        # 2 rows in household table
        expect(first('tbody').all('tr').count).to eq(2)
        # new client's relationship appears
        within('tr', text: c2.brief_name) do
          expect(page).to have_content 'Spouse or partner'
        end

        receiving_enrollment.reload
        c2.reload
      end.to change(c2.enrollments, :count).from(0).to(1).
        and change(receiving_enrollment.household_members, :count).from(1).to(2)

      expect(c2.enrollments.first.household_id).to eq(receiving_enrollment.household_id)
    end
  end
end
