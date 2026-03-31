###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'

## System spec for the Client Search page.
# Confirms desired behavior of searchQueryId in URL params
RSpec.feature 'Client Search', type: :system do
  let!(:ds1) { GrdaWarehouse::DataSource.hmis.find_by(hmis: 'localhost') }
  let!(:user) { create(:user) }
  let(:hmis_user) { user.related_hmis_user(ds1) }
  let!(:p1) { create :hmis_hud_project, data_source: ds1 }
  let!(:access_control) { create_access_control(hmis_user, p1) }

  let!(:c1) { create :hmis_hud_client, first_name: 'Searchable', last_name: 'Client', data_source: ds1 }
  let!(:c2) { create :hmis_hud_client, first_name: 'Another', last_name: 'Person', data_source: ds1 }

  before(:each) do
    sign_in(hmis_user)
    visit '/'
  end

  describe 'search query ID in URL' do
    it 'populates searchQueryId in URL params after search, without a separate network request' do
      fill_in 'search clients', with: 'Searchable Client'
      find('[data-testid="clientSearchInput"]').native.send_keys(:enter)

      # Confirm the client shows up in results
      expect(page).to have_text('Displaying 1 of 1 client')
      table = find('table')
      mui_table_expect('Searchable Client', row_index: 0, column_header: 'Client Name', from: table)

      # Confirm the search query was created and the page's URL search params were populated
      search_query = Hmis::ClientSearchQuery.sole
      expect(search_query.params).to eq({ 'text_search' => 'Searchable Client' })
      expect(page).to have_current_path("/?searchQueryId=#{search_query.id}")
    end

    it 'restores search results when navigating back after viewing a client profile' do
      fill_in 'search clients', with: 'Searchable'
      find('[data-testid="clientSearchInput"]').native.send_keys(:enter)

      expect(page).to have_text('Searchable Client')
      search_query = Hmis::ClientSearchQuery.sole
      click_link 'Searchable Client'

      # Confirm we are on the client profile
      expect(page).to have_current_path("/client/#{c1.id}/profile")
      expect(page).to have_text('No Client Photo')
      expect(page).to have_text('Client Alerts (0)')

      # Click the back button and confirm the search results are still shown
      page.go_back
      expect(page).to have_current_path("/?searchQueryId=#{search_query.id}")
      expect(page).to have_text('Searchable Client')
    end

    context 'when there is an existing search query' do
      let!(:search_query) { create :hmis_client_search_query, created_by: hmis_user, params: { 'text_search' => 'Searchable' } }

      it 'when repeating the search, loads existing search query' do
        expect do
          # Searching for
          fill_in 'search clients', with: 'Searchable'
          find('[data-testid="clientSearchInput"]').native.send_keys(:enter)
          expect(page).to have_text('Displaying 1 of 1 client')
          expect(page).to have_text('Searchable Client')
          expect(page).to have_current_path("/?searchQueryId=#{search_query.id}")
        end.to not_change(Hmis::ClientSearchQuery, :count)
      end

      it 'when navigating directly, loads existing search query params from network' do
        expect do
          visit "/?searchQueryId=#{search_query.id}"
          expect(page).to have_text('Displaying 1 of 1 client')
          expect(page).to have_text('Searchable Client')
          expect(page).to have_current_path("/?searchQueryId=#{search_query.id}")
        end.to not_change(Hmis::ClientSearchQuery, :count)
      end
    end
  end

  describe 'display toggle' do
    it 'displays clients as rows by default and can switch to cards' do
      fill_in 'search clients', with: 'Searchable'
      find('[data-testid="clientSearchInput"]').native.send_keys(:enter)

      # Confirm the original results are laid out as table rows
      expect(page).to have_text('Displaying 1 of 1 client')
      table = find('table')
      mui_table_expect('Searchable Client', row_index: 0, column_header: 'Client Name', from: table)
      mui_table_expect(/Hidden[\n\r\s]+\(24\)/, row_index: 0, column_header: 'DOB', from: table)
      expect(page).not_to have_css('[data-testid="clientSearchResultCard"]', visible: true)

      # Click the card toggle button and confirm the layout changes
      find('[data-testid="cardToggleButton"]').click
      card_element = find('[data-testid="clientSearchResultCard"]')
      expect(card_element).to have_text('Searchable Client')
      expect(card_element).to have_text('Last Updated on')
      expect(card_element).to have_text('DOB (Age): Hidden (24)')
    end
  end

  describe 'specific (advanced) search' do
    it 'supports specific search with first and last name' do
      find('[data-testid="specificSearchToggleButton"]').click

      expect(page).to have_current_path(/\/advanced-search/)

      fill_in 'First Name', with: 'Searchable'
      fill_in 'Last Name', with: 'Client'
      click_button 'Search'

      expect(page).to have_text('Displaying 1 of 1 client')
      search_query = Hmis::ClientSearchQuery.sole
      expect(search_query.params).to eq({ 'first_name' => 'Searchable', 'last_name' => 'Client' })
      expect(page).to have_current_path("/advanced-search?searchQueryId=#{search_query.id}")
      table = find('table')
      mui_table_expect('Searchable Client', row_index: 0, column_header: 'Client Name', from: table)
    end
  end

  # Basic permission test. Permissions are tested in more detail in drivers/hmis/spec/requests/hmis/client_search_spec.rb
  describe 'user permissions' do
    # c3 is enrolled at a project the user doesn't have access to
    let!(:p2) { create :hmis_hud_project, data_source: ds1 }
    let!(:c3) { create :hmis_hud_client, first_name: 'Hidden', last_name: 'Client', data_source: ds1 }
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p2, client: c3 }

    it 'does not return clients the user lacks permission to view' do
      fill_in 'search clients', with: 'Client'
      find('[data-testid="clientSearchInput"]').native.send_keys(:enter)

      # Both names match "Client", but only the client we can view appears in results
      expect(page).to have_text('Displaying 1 of 1 client')
      table = find('table')
      mui_table_expect('Searchable Client', row_index: 0, column_header: 'Client Name', from: table)
      expect(page).not_to have_text('Hidden Client')
    end
  end
end
