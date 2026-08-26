###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ServiceScanning::ServicesController#index (last added panel)', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:role) { create(:role, can_use_service_register: true, can_view_clients: true) }
  let!(:collection) { create(:collection) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:project) { create(:hud_project) }
  # No FactoryBot factory exists for ServiceScanning::Service anywhere in this codebase
  # (confirmed via repo-wide grep — the driver has no spec/factories directory at all) — build
  # the concrete STI subclass directly. `Service` is an abstract STI base
  # (`validates_presence_of :project_id`); `ServiceScanning::OtherService` is a real, directly
  # instantiable subclass (see `Service.type_map`).
  let!(:service) { ServiceScanning::OtherService.create!(client_id: restricted_destination_client.id, project: project, provided_at: Time.current, user: user) }

  before do
    Collection.maintain_system_groups
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  it 'redacts the client name in the last-added service panel' do
    get service_scanning_services_path(service: { client_id: restricted_destination_client.id, service_id: service.id, project_id: project.id })

    expect(response.body).not_to include('Restricted Client')
    expect(response.body).to include('Name Redacted')
  end
end
