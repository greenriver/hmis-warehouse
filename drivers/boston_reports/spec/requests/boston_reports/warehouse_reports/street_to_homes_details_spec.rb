###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../../spec/shared_contexts/hud_enrollment_builders'

RSpec.describe 'BostonReports::WarehouseReports::StreetToHomesController#details', type: :request do
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true, can_view_clients: true, can_view_projects: true) }
  let!(:report_definition) { create(:touch_point_report, url: 'boston_reports/warehouse_reports/street_to_homes', name: 'Street to Home') }
  let!(:cohort) { create(:cohort) }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id] })
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  def build_preload_client(index)
    source = create_client_with_warehouse_link(first_name: "Preload#{index}", last_name: 'Coverage')
    destination = source.destination_client
    GrdaWarehouse::CohortClient.create!(cohort: cohort, client: destination, user_select_12: 'Cohort A', active: true)
    destination
  end

  let(:street_filters) do
    { cohort_ids: [cohort.id], cohort_column: 'user_select_12', cohort_column_voucher_type: 'user_select_9', cohort_column_housed_date: 'housed_date', start: 1.year.ago.to_date, end: Date.current }
  end

  it 'lists every client name when more clients than the preload miss threshold are in the set' do
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }

    get details_boston_reports_warehouse_reports_street_to_homes_path(filters: street_filters, sets: ['Total'])

    expect(response).to have_http_status(:ok)
    extra.each { |client| expect(response.body).to include(client.FirstName) }
  end

  it 'exports every client name when more clients than the preload miss threshold are in the set' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
    GrdaWarehouse::Config.invalidate_cache
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }

    get details_boston_reports_warehouse_reports_street_to_homes_path(filters: street_filters, sets: ['Total'], format: :xlsx)

    expect(response).to have_http_status(:ok)
    expect(xlsx_cell_values(response)).to include(*extra.map(&:FirstName))
  end

  after { GrdaWarehouse::Config.invalidate_cache }
end
