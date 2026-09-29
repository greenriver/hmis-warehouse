###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ServiceScanning::ScannerIdsController#index', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:role) { create(:role, can_use_service_register: true, can_search_own_clients: true, can_view_client_name: true, can_view_clients: true) }
  let!(:window_ds) { create(:visible_data_source) }
  let!(:window_project) { create(:grda_warehouse_hud_project, data_source_id: window_ds.id) }

  before do
    Collection.maintain_system_groups
    setup_access_control(user, role, Collection.system_collection(:data_sources))
    sign_in user
  end

  it 'lists every matching client when more clients than the preload miss threshold match the search' do
    clients = Array.new(preload_miss_client_count) do |i|
      source = create(:grda_warehouse_hud_client, data_source_id: window_ds.id, FirstName: "Preload#{i}", LastName: 'Coverage')
      create(:grda_warehouse_hud_enrollment, data_source_id: window_ds.id, PersonalID: source.PersonalID, ProjectID: window_project.ProjectID, EntryDate: 1.month.ago.to_date)
      destination = create(:grda_warehouse_hud_client, FirstName: "Preload#{i}", LastName: 'Coverage')
      GrdaWarehouse::WarehouseClient.create!(destination_id: destination.id, source_id: source.id, data_source_id: window_ds.id, id_in_source: source.PersonalID)
      destination
    end

    get service_scanning_scanner_ids_path(q: 'Coverage')

    expect(response).to have_http_status(:ok)
    clients.each { |client| expect(response.body).to include(client.FirstName) }
  end
end
