###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::ExportCovidImpactAssessmentsController', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  # `@clients` is filtered through `Client.destination_visible_to`, which (via
  # `EnrollmentArbiter#clients_source_visible_to`) requires real ACL client-visibility,
  # granted here on `hmis_ds` directly -- matching the pattern in
  # `spec/requests/warehouse_reports/health_emergency/vaccinations_controller_spec.rb`.
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_clients: true, can_view_client_name: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/export_covid_impact_assessments', name: 'COVID-19 Impact Assessment Export') }
  let!(:hmis_ds_viewable_collection) { create(:collection) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'RClient') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'RClient') }
  let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'OClient') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'OClient') }
  let!(:organization) { create(:hud_organization, data_source: hmis_ds) }
  let!(:project) { create(:grda_warehouse_hud_project, organization: organization, data_source: hmis_ds) }
  # `can_view_client_name` is granted per client through the client's enrolled project's
  # collection, so the open source client needs a real enrollment in the viewable project --
  # unlike the `WarehouseClient` link below, which only maps identity. The restricted client
  # doesn't need one: `mark_as_restricted!` overrides name visibility regardless.
  let!(:open_enrollment) { create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(open_source_client.id), data_source: hmis_ds, project: project) }

  let!(:hmis_assessment_row) do
    GrdaWarehouse::Hmis::Assessment.create!(
      data_source_id: hmis_ds.id,
      site_id: 1,
      assessment_id: 1,
      name: 'COVID-19 Impact Assessment',
      site_name: 'Main Site',
      confidential: false,
      active: true,
      covid_19_impact_assessment: true,
    )
  end
  let!(:restricted_form) do
    GrdaWarehouse::HmisForm.create!(
      client_id: restricted_source_client.id,
      data_source_id: hmis_ds.id,
      site_id: 1,
      assessment_id: 1,
      name: 'COVID-19 Impact Assessment',
      collected_at: Date.current,
      staff: 'Staff Member',
      answers: { sections: [] },
      number_of_bedrooms: 2,
      total_subsidy: 500,
      subsidy_months: 12,
      monthly_rent_total: 1000,
      percent_ami: 30,
      household_type: 'Family',
      household_size: 3,
    )
  end
  let!(:open_form) do
    GrdaWarehouse::HmisForm.create!(
      client_id: open_source_client.id,
      data_source_id: hmis_ds.id,
      site_id: 1,
      assessment_id: 1,
      name: 'COVID-19 Impact Assessment',
      collected_at: Date.current,
      staff: 'Staff Member',
      answers: { sections: [] },
      number_of_bedrooms: 2,
      total_subsidy: 500,
      subsidy_months: 12,
      monthly_rent_total: 1000,
      percent_ami: 30,
      household_type: 'Family',
      household_size: 3,
    )
  end

  # `GrdaWarehouse::Config.get` caches the settings row at the class level for 30 seconds,
  # independent of each example's DB transaction rollback -- without this, an earlier example's
  # `include_pii_in_detail_downloads` change can leak into a later one regardless of run order.
  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    # `destination_visible_to` (`EnrollmentArbiter`) resolves through several `Rails.cache`-backed
    # lookups (data source id lists, ACL grants, etc.) that live outside each example's DB
    # transaction rollback -- a value cached while another spec file's now-rolled-back fixtures
    # were live can otherwise leak in here (or vice versa), matching the pattern in
    # `vaccinations_controller_spec.rb`.
    Rails.cache.clear
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id], projects: [project.id] })
    hmis_ds_viewable_collection.add_viewable(hmis_ds)
    setup_access_control(user, role, collection)
    setup_access_control(user, role, hmis_ds_viewable_collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  # `.xlsx` responses are a compressed OOXML zip, not plain text -- `response.body.include?` would
  # pass even on unredacted data, since the raw string never appears uncompressed. Parse the actual
  # workbook instead, matching the pattern in `open_enrollments_no_service_controller_spec.rb`.
  def rendered_workbook
    excel_file = Tempfile.new(['export_covid_impact_assessments', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'redacts the restricted client name in the HTML view but shows the unrestricted client name' do
    get warehouse_reports_export_covid_impact_assessments_path

    expect(response.body).not_to include('>Restricted<')
    expect(response.body).not_to include('>RClient<')
    expect(response.body).to include('Name Redacted')
    expect(response.body).to include('>Open<')
    expect(response.body).to include('>OClient<')
  end

  it 'redacts the restricted client name in the Excel export when the download toggle is on, leaving the unrestricted client intact' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
    GrdaWarehouse::Config.invalidate_cache

    get warehouse_reports_export_covid_impact_assessments_path(format: :xlsx)

    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    data_rows = ((sheet.first_row + 1)..sheet.last_row).map { |i| sheet.row(i) }

    restricted_row = data_rows.find { |r| r.first(2) == ['Name Redacted', 'Name Redacted'] }
    expect(restricted_row).to be_present

    open_row = data_rows.find { |r| r[0] == 'OClient' }
    expect(open_row[1]).to eq('Open')
  end

  it 'redacts every client name in the Excel export when the download toggle is off' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
    GrdaWarehouse::Config.invalidate_cache

    get warehouse_reports_export_covid_impact_assessments_path(format: :xlsx)

    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    data_rows = ((sheet.first_row + 1)..sheet.last_row).map { |i| sheet.row(i) }

    expect(data_rows).to all(satisfy { |r| r.first(2) == ['Name Redacted', 'Name Redacted'] })
  end
end
