###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::HealthEmergency::MedicalRestrictionsController#index', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:role) do
    create(:role, can_see_health_emergency: true, can_see_health_emergency_clinical: true, can_edit_health_emergency_clinical: true,
                  can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true)
  end
  let!(:collection) { create(:collection) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/health_emergency/medical_restrictions', name: 'Medical Restrictions') }
  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:project) { create(:hud_project, data_source: hmis_ds) }

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::Config.first_or_create.update!(health_emergency: 'boston_covid_19')
    GrdaWarehouse::Config.invalidate_cache
    sign_in user
  end

  def build_preload_client(index)
    source = create(:hmis_hud_client, data_source: hmis_ds, first_name: "Preload#{index}", last_name: 'Coverage')
    destination = create(:grda_warehouse_hud_client, FirstName: "Preload#{index}", LastName: 'Coverage')
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination.id, source_id: source.id, data_source_id: hmis_ds.id, id_in_source: source.id.to_s)
    GrdaWarehouse::WarehouseClientsProcessed.create!(client_id: destination.id, routine: 'service_history')
    create(:she_entry, client: destination, project: project)
    create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(source.id), project: project, data_source: hmis_ds)
    GrdaWarehouse::HealthEmergency::AmaRestriction.create!(client: destination, user: user, restricted: 'Yes')
    destination
  end

  it 'lists every client when more clients than the preload miss threshold have a restriction' do
    clients = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }

    get warehouse_reports_health_emergency_medical_restrictions_path

    expect(response).to have_http_status(:ok)
    clients.each { |client| expect(response.body).to include(client.FirstName) }
  end
end
