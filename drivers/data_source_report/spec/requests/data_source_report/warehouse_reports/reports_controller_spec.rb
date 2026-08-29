###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataSourceReport::WarehouseReports::ReportsController, type: :request do
  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_assigned_reports: true, can_view_projects: true) }
  let(:collection) { create(:collection) }
  let!(:report_definition) { create(:data_source_report) }
  let!(:data_source) { create(:source_data_source, name: 'Stale Vendor') }

  before do
    collection.set_viewables(reports: [report_definition.id], data_sources: [data_source.id], projects: [])
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  describe 'GET #index' do
    it 'shows the stalled-import label for a data source whose most recent import is stale' do
      create(:grda_warehouse_hmis_import_config, data_source: data_source, file_count: 1)
      create(:grda_warehouse_upload, data_source: data_source, user: User.system_user, percent_complete: 100, completed_at: 30.hours.ago)
      GrdaWarehouse::ImportLog.create!(data_source: data_source, completed_at: 30.hours.ago)

      get data_source_report_warehouse_reports_reports_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('same file since:')
    end

    it 'shows no stalled-import label for a data source with no import history' do
      get data_source_report_warehouse_reports_reports_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('same file since:')
    end
  end

  describe 'GET #index query efficiency' do
    def create_linked_client(within_data_source, destination_data_source)
      source_client = create(:hud_client, data_source: within_data_source)
      destination_client = source_client.dup
      destination_client.data_source = destination_data_source
      destination_client.save!
      create(:warehouse_client, destination_id: destination_client.id, source_id: source_client.id)
      source_client
    end

    def build_data_source_with_data(name:, destination_data_source:)
      ds = create(:source_data_source, name: name)
      org = create(:hud_organization, data_source: ds)
      project = create(:hud_project, data_source: ds, OrganizationID: org.OrganizationID)
      create_list(:hud_client, 2, data_source: ds)
      create(:hud_enrollment, data_source: ds, project: project, client: create_linked_client(ds, destination_data_source), processed_as: nil)
      GrdaWarehouse::ImportLog.create!(data_source: ds, completed_at: 1.day.ago)
      ds
    end

    it 'runs a bounded number of queries regardless of how many data sources are on the page' do
      count_queries = lambda do |&block|
        count = 0
        callback = ->(*) { count += 1 }
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &block)
        count
      end

      destination_data_source = create(:destination_data_source)
      small_batch = Array.new(3) { |i| build_data_source_with_data(name: "Small Vendor #{i}", destination_data_source: destination_data_source) }
      collection.set_viewables(reports: [report_definition.id], data_sources: small_batch.map(&:id), projects: [])

      # Warm up one-time schema-cache/connection-setup queries so they don't confound
      # the small-vs-large comparison below.
      get data_source_report_warehouse_reports_reports_path
      expect(response).to have_http_status(:ok)

      small_queries = count_queries.call { get data_source_report_warehouse_reports_reports_path }
      expect(response).to have_http_status(:ok)

      large_batch = small_batch + Array.new(9) { |i| build_data_source_with_data(name: "Large Vendor #{i}", destination_data_source: destination_data_source) }
      collection.set_viewables(reports: [report_definition.id], data_sources: large_batch.map(&:id), projects: [])
      # This comparison only holds if every data source in large_batch lands on page 1;
      # otherwise large_queries would undercount and the assertion below would pass for
      # the wrong reason.
      expect(large_batch.size).to be <= Pagy::DEFAULT[:items]

      large_queries = count_queries.call { get data_source_report_warehouse_reports_reports_path }
      expect(response).to have_http_status(:ok)

      # A regression to a per-row query pattern (client/project/unprocessed-enrollment counts
      # and last-import timestamps each queried once per row) would make large_queries scale
      # with data source count (9 more data sources here); a small constant tolerance
      # accommodates incidental preload-boundary variance without masking that regression.
      expect(large_queries).to be_within(5).of(small_queries)
    end
  end
end
