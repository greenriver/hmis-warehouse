###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CensusTracking::WarehouseReports::CensusTrackers#details', type: :request do
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_assigned_reports: true, can_view_clients: true, can_view_client_name: true) }
  let!(:user) { create(:acl_user) }

  let!(:project_data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: project_data_source) }
  let!(:project) { create(:hud_project, data_source: project_data_source, OrganizationID: organization.OrganizationID) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Doe') }

  let(:census_row) { Struct.new(:client_id, :first_name, :last_name, :age, :project_name) }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ projects: [project.id] })
    setup_access_control(user, role, collection)
    allow_any_instance_of(CensusTracking::WarehouseReports::CensusTrackersController).to receive(:report_visible?).and_return(true)
    allow_any_instance_of(CensusTracking::Worksheet).to receive(:clients_by_project).and_return(
      [
        census_row.new(restricted_destination_client.id, 'Restricted', 'Client', 30, project.name),
        census_row.new(open_destination_client.id, 'Open', 'Doe', 40, project.name),
      ],
    )
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in(user)
  end

  def name_cells
    Nokogiri::HTML(response.body).css('table.table-sm tbody td').map { |td| td.text.strip }
  end

  context 'when the role grants can_view_client_name' do
    it 'redacts the restricted client and shows the unrestricted client' do
      get details_census_tracking_warehouse_reports_census_trackers_path(project: project.id, key: 'test')

      expect(response).to have_http_status(:success)
      cells = name_cells
      expect(cells).to include('Open', 'Doe')
      expect(cells).not_to include('Restricted', 'Client')
      expect(cells.count(GrdaWarehouse::PiiProvider::NAME_REDACTED)).to eq(2)
    end
  end

  context 'when the role lacks can_view_client_name' do
    let!(:role) { create(:role, can_view_assigned_reports: true, can_view_clients: true) }

    it 'redacts both clients' do
      get details_census_tracking_warehouse_reports_census_trackers_path(project: project.id, key: 'test')

      expect(response).to have_http_status(:success)
      cells = name_cells
      expect(cells).not_to include('Open', 'Doe', 'Restricted', 'Client')
      expect(cells.count(GrdaWarehouse::PiiProvider::NAME_REDACTED)).to eq(4)
    end
  end
end
