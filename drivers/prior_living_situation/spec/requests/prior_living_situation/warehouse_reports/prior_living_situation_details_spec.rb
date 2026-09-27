###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/hud_enrollment_builders'

RSpec.describe 'PriorLivingSituation::WarehouseReports::PriorLivingSituationController#details', type: :request do
  include_context 'HUD enrollment builders'
  include ArelHelper

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true, can_view_clients: true, can_view_projects: true) }
  let!(:report_definition) { create(:touch_point_report, url: 'prior_living_situation/warehouse_reports/prior_living_situation', name: 'Prior Living Situation') }
  let!(:project) { create_project(project_type: 1) }

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    sign_in user
  end

  def build_preload_client(index)
    destination = create(:grda_warehouse_hud_client, FirstName: "Preload#{index}", LastName: 'Coverage')
    create(:she_entry, client: destination, project: project, record_type: :entry, project_type: 1, first_date_in_program: 2.months.ago.to_date, last_date_in_program: nil)
    destination
  end

  def stub_detail_rows(clients)
    scope = GrdaWarehouse::ServiceHistoryEnrollment.joins(:client).where(client_id: clients.map(&:id))
    columns = [she_t[:client_id], c_t[:FirstName], c_t[:LastName]]
    allow_any_instance_of(PriorLivingSituation::PriorLivingSituationReport).to receive(:detail_scope_from_key).and_return(scope)
    allow_any_instance_of(PriorLivingSituation::PriorLivingSituationReport).to receive(:header_for).and_return(['Client ID', 'First Name', 'Last Name'])
    allow_any_instance_of(PriorLivingSituation::PriorLivingSituationReport).to receive(:columns_for).and_return(columns)
    allow_any_instance_of(PriorLivingSituation::PriorLivingSituationReport).to receive(:support_title).and_return('Preload coverage')
  end

  it 'lists every client when more clients than the preload miss threshold are in the detail table' do
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }
    stub_detail_rows(extra)

    get details_prior_living_situation_warehouse_reports_prior_living_situation_index_path(key: 'preload', filters: { start: 1.year.ago.to_date, end: Date.current })

    expect(response).to have_http_status(:ok)
    extra.each { |client| expect(response.body).to include(client.FirstName) }
  end

  it 'exports every client when more clients than the preload miss threshold are in the detail table' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
    GrdaWarehouse::Config.invalidate_cache
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }
    stub_detail_rows(extra)

    get details_prior_living_situation_warehouse_reports_prior_living_situation_index_path(key: 'preload', filters: { start: 1.year.ago.to_date, end: Date.current }, format: :xlsx)

    expect(response).to have_http_status(:ok)
    expect(xlsx_cell_values(response)).to include(*extra.map(&:FirstName))
  end
end
