###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../shared_contexts/hud_enrollment_builders'

RSpec.describe 'WarehouseReports::CeAssessmentsController#index', type: :request do
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) do
    create(
      :role,
      can_view_all_reports: true,
      can_view_assigned_reports: true,
      can_view_client_name: true,
      can_view_clients: true,
      can_view_projects: true,
      can_view_ce_assessment: true,
    )
  end
  let!(:report_definition) { create(:touch_point_report, url: 'warehouse_reports/ce_assessments', name: 'CE Assessments') }
  let!(:project) { create_project(project_type: 1) }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  def build_preload_client(index)
    source = create_client_with_warehouse_link(first_name: "Preload#{index}", last_name: 'Coverage')
    create_enrollment(client: source, project: project, entry_date: 1.year.ago.to_date)
    destination = source.destination_client
    GrdaWarehouse::CoordinatedEntryAssessment::Individual.create!(client: destination, user: user, assessor: user, active: true)
    destination
  end

  it 'lists every client when more clients than the preload miss threshold have an assessment' do
    clients = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }

    get warehouse_reports_ce_assessments_path

    expect(response).to have_http_status(:ok)
    clients.each { |client| expect(response.body).to include(client.FirstName) }
  end

  describe 'xlsx' do
    let!(:clients) { Array.new(preload_miss_client_count) { |i| build_preload_client(i) } }

    def request_xlsx
      get warehouse_reports_ce_assessments_path(format: :xlsx)
      xlsx_cell_values(response)
    end

    def configure_download_pii(enabled)
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: enabled)
      GrdaWarehouse::Config.invalidate_cache
    end

    after { GrdaWarehouse::Config.invalidate_cache }

    it 'omits names and DOBs but keeps each row when the download toggle is off' do
      configure_download_pii(false)

      values = request_xlsx

      expect(values).to include(*clients.map(&:id))
      clients.each do |client|
        expect(values).not_to include(client.FirstName)
        expect(values).not_to include("#{client.FirstName} #{client.LastName}")
        expect(values).not_to include(client.DOB)
      end
    end

    it 'includes every full name when the download toggle is on' do
      configure_download_pii(true)

      values = request_xlsx

      expect(values).to include(*clients.map { |client| "#{client.FirstName} #{client.LastName}" })
    end

    it 'omits a restricted client name but keeps the row when the download toggle is on' do
      configure_download_pii(true)
      hmis_ds = create(:hmis_primary_data_source)
      hmis_user = create(:hmis_user, data_source: hmis_ds)
      hmis_organization = create(:hud_organization, data_source: hmis_ds)
      hmis_project = create(:hud_project, data_source: hmis_ds, OrganizationID: hmis_organization.OrganizationID, ProjectType: 1)
      collection.set_viewables({ reports: [report_definition.id], projects: [project.id, hmis_project.id] })
      Rails.cache.clear
      restricted_source = create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restrictedfirst', last_name: 'Restrictedlast')
      restricted = create(:grda_warehouse_hud_client, FirstName: 'Restrictedfirst', LastName: 'Restrictedlast')
      GrdaWarehouse::WarehouseClient.create!(destination_id: restricted.id, source_id: restricted_source.id, data_source_id: hmis_ds.id, id_in_source: restricted_source.id.to_s)
      create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(restricted_source.id), project: hmis_project, data_source: hmis_ds)
      GrdaWarehouse::CoordinatedEntryAssessment::Individual.create!(client: restricted, user: user, assessor: user, active: true)
      restricted_source.mark_as_restricted!(user: hmis_user)

      values = request_xlsx

      expect(values).to include(restricted.id)
      expect(values).not_to include('Restrictedfirst Restrictedlast')
      expect(values).to include(*clients.map { |client| "#{client.FirstName} #{client.LastName}" })
    end
  end
end
