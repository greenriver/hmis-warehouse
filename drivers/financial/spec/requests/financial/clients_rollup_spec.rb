###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'

RSpec.describe 'Financial client rollup', type: :request do
  include_context 'visibility test context'

  let!(:user) { create :acl_user }

  before do
    Collection.maintain_system_groups
    window_destination_client.update!(FirstName: 'Warehouse', LastName: 'Client')
    2.times do |i|
      Financial::Client.create!(client: window_destination_client, external_client_id: i + 1, data_source_id: window_visible_data_source.id, client_first_name: 'Fina', client_last_name: 'Ncial')
    end
    sign_in user
  end

  def request_financial_clients
    get financial_client_rollup_path(window_destination_client, partial: 'financial_clients'), xhr: true
  end

  context 'with permission to see client names' do
    before do
      setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
      setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
    end

    it 'shows the financial record name' do
      request_financial_clients

      expect(response).to have_http_status(:ok)
      expect(response.body.scan('Fina Ncial').size).to eq(2)
    end
  end

  context 'without permission to see client names' do
    before do
      setup_access_control(user, create(:role, can_view_clients: true), Collection.system_collection(:window_data_sources))
    end

    it 'redacts the financial record name' do
      request_financial_clients

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Fina')
      expect(response.body).to include('Name Redacted')
    end
  end
end
