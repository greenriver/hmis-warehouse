###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cohorts::ReportsController, type: :request do
  let!(:user) { create(:acl_user) }
  let!(:all_cohorts_collection) { Collection.system_collection(:cohorts) }
  let!(:cohort_role) { create(:role, can_view_clients: true, can_view_cohorts: true, can_view_cohort_client_changes_report: true) }
  let!(:cohort) { create(:cohort) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:cohort_client) { GrdaWarehouse::CohortClient.create!(cohort: cohort, client: restricted_destination_client) }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client') }
  let!(:open_cohort_client) { GrdaWarehouse::CohortClient.create!(cohort: cohort, client: open_destination_client) }
  let!(:change) { GrdaWarehouse::CohortClientChange.create!(cohort_client: cohort_client, cohort: cohort, user: user, change: 'add', changed_at: Time.current) }
  let!(:open_change) { GrdaWarehouse::CohortClientChange.create!(cohort_client: open_cohort_client, cohort: cohort, user: user, change: 'add', changed_at: Time.current) }

  # `GrdaWarehouse::Config.get` caches the settings row at the class level for 30 seconds,
  # independent of each example's DB transaction rollback — without this, an earlier example's
  # `include_pii_in_detail_downloads` change can leak into a later one regardless of run order.
  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Rails.cache.clear
    Collection.maintain_system_groups
    setup_access_control(user, cohort_role, all_cohorts_collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  it 'redacts the client name in the changes report table' do
    get cohort_report_path(cohort)

    expect(response.body).not_to include('Restricted Client')
    expect(response.body).to include('Name Redacted')
  end

  # `.xlsx` responses are a compressed OOXML zip, not plain text — `response.body.include?` would
  # pass even on unredacted data, since the raw string never appears uncompressed. Parse the actual
  # workbook instead, matching the established pattern in
  # `drivers/homeless_summary_report/spec/requests/homeless_summary_report/warehouse_reports/reports_controller_details_spec.rb`.
  def rendered_workbook
    excel_file = Tempfile.new(['cohort_report', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'redacts the client name in the Excel export regardless of the PII-download setting' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
    GrdaWarehouse::Config.invalidate_cache

    get cohort_report_path(cohort, format: :xlsx)

    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    data_row = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }.find { |r| r[0] == restricted_destination_client.id }
    expect(data_row[1]).to eq('Name Redacted')
  end

  it 'shows the unrestricted client name in the HTML view but redacts it in the Excel export when the download toggle is off' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
    GrdaWarehouse::Config.invalidate_cache

    get cohort_report_path(cohort)
    expect(response.body).to include('Open Client')

    get cohort_report_path(cohort, format: :xlsx)
    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    row = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }.find { |r| r[0] == open_destination_client.id }
    expect(row[1]).to eq('Name Redacted')
  end
end
