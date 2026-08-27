###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::HealthEmergency::TestingResultsController#index', type: :request do
  let!(:user) { create(:acl_user) }
  # See `spec/requests/warehouse_reports/health_emergency/tests_tables_spec.rb` for the full
  # explanation of this exact permission combination — `require_health_emergency!`
  # (`can_see_health_emergency`), `require_can_see_health_emergency_clinical!`
  # (`can_see_health_emergency_clinical`), and `report_visible?` (`can_view_assigned_reports`
  # specifically, for an ACL user).
  let!(:role) do
    create(:role, can_see_health_emergency: true, can_see_health_emergency_clinical: true, can_edit_health_emergency_clinical: true,
                  can_view_all_reports: true, can_view_assigned_reports: true)
  end
  let!(:collection) { create(:collection) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/health_emergency/testing_results', name: 'Test Results') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:project) { create(:hud_project) }
  let!(:she) { create(:she_entry, client: restricted_destination_client, project: project) }
  let!(:warehouse_client) { GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s) }
  # `TestingResultsController#index` inner-joins `client: [:processed_service_history, ...]` —
  # without a matching row here the client is excluded from `@results` entirely, regardless of
  # the `HealthEmergency::Test` row existing.
  let!(:processed_service_history) { GrdaWarehouse::WarehouseClientsProcessed.create!(client_id: restricted_destination_client.id, routine: 'service_history') }
  let!(:test_result) { GrdaWarehouse::HealthEmergency::Test.create!(client: restricted_destination_client, user: user, tested_on: Date.current, result: 'Negative') }

  # `GrdaWarehouse::Config.get` caches the settings row at the class level for 30 seconds,
  # independent of each example's DB transaction rollback — without this, a `health_emergency`
  # value set (or unset) by another spec file running earlier in the same process can leak in
  # here, and vice versa. Matches the established pattern in
  # `spec/requests/warehouse_reports/chronic_housed_controller_spec.rb`.
  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id] })
    setup_access_control(user, role, collection)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    GrdaWarehouse::Config.first_or_create.update!(health_emergency: 'boston_covid_19')
    GrdaWarehouse::Config.invalidate_cache
    sign_in user
  end

  it 'redacts the client name in the HTML view' do
    get warehouse_reports_health_emergency_testing_results_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('Restricted Client')
    expect(response.body).to include('Name Redacted')
  end

  # `.xlsx` responses are a compressed OOXML zip, not plain text — `response.body.include?` would
  # pass even on unredacted data, since the raw string never appears uncompressed. Parse the actual
  # workbook instead, matching the established pattern in `spec/requests/warehouse_reports/chronic_housed_controller_spec.rb`.
  def rendered_workbook
    excel_file = Tempfile.new(['testing_results', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'redacts the client name in the Excel export' do
    get warehouse_reports_health_emergency_testing_results_path(format: :xlsx)

    expect(response).to have_http_status(:ok)
    data_row = rendered_workbook.sheet(0).row(3)
    expect(data_row[1]).to eq('Name Redacted')
    expect(data_row[2]).to eq('Name Redacted')
  end
end
