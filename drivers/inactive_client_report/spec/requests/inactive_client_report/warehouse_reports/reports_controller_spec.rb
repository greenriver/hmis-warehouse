###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'InactiveClientReport::WarehouseReports::ReportsController#data', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_projects: true, can_view_client_name: true, can_view_full_dob: true) }
  let!(:report_definition) { create(:touch_point_report, url: InactiveClientReport::Report.url, name: 'Client Activity Report') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:organization) { create(:hud_organization, data_source: hmis_ds) }
  let!(:project) { create(:hud_project, data_source: hmis_ds, OrganizationID: organization.OrganizationID, ProjectType: 1) } # ES

  let(:on_date) { Date.current }
  let(:report_filters) do
    {
      on: on_date.to_s,
      start: 1.year.ago.to_date.to_s,
      end: on_date.to_s,
      project_ids: [project.id],
      require_service_during_range: 'false',
    }
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Rails.cache.clear
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  def build_preload_client(index)
    source = create(:hmis_hud_client, data_source: hmis_ds, first_name: "Preload#{index}", last_name: 'Coverage')
    destination = create(:grda_warehouse_hud_client, FirstName: "Preload#{index}", LastName: 'Coverage', DOB: '1990-06-15')
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination.id, source_id: source.id, data_source_id: hmis_ds.id, id_in_source: source.id.to_s)
    create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(source.id), data_source: hmis_ds, project: project)
    create(:she_entry, client: destination, project: project, record_type: :entry, project_type: 1, first_date_in_program: 6.months.ago.to_date, last_date_in_program: nil)
    destination
  end

  it 'lists every client when more clients than the preload miss threshold are inactive' do
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }

    get data_inactive_client_report_warehouse_reports_reports_path(filters: report_filters)

    expect(response).to have_http_status(:ok)
    extra.each { |client| expect(response.body).to include(client.FirstName) }
  end
end
