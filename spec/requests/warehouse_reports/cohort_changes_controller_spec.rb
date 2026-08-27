###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::CohortChangesController', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:report_viewer) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/cohort_changes', name: 'Cohort Changes') }
  let!(:cohort) { create(:cohort) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:cohort_client) { GrdaWarehouse::CohortClient.create!(cohort: cohort, client: restricted_destination_client) }
  # No FactoryBot factory exists for GrdaWarehouse::CohortClientChange anywhere in this codebase
  # (confirmed via repo-wide grep of spec/factories) — build directly. The `combined_cohort_client_changes`
  # view (what WarehouseReport::CohortChanges#cohort_enrollments actually reads) is a read-only,
  # non-insertable Postgres VIEW derived from this table, filtered to change: create/activate for entries.
  let!(:cohort_client_change) do
    GrdaWarehouse::CohortClientChange.create!(cohort: cohort, cohort_client: cohort_client, user: user, change: 'create', changed_at: 1.week.ago)
  end
  let(:filter_params) { { start: 1.month.ago.to_date.to_s, end: Date.current.to_s, cohort_id: cohort.id } }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  it 'redacts the client name in the HTML view' do
    get warehouse_reports_cohort_changes_path(filter: filter_params)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('Restricted')
    expect(response.body).to include('Name Redacted')
  end

  # `.xlsx` responses are a compressed OOXML zip, not plain text — `response.body.include?` would
  # pass even on unredacted data, since the raw string never appears uncompressed. Parse the actual
  # workbook instead, matching the established pattern in `spec/requests/warehouse_reports/chronic_housed_controller_spec.rb`.
  def rendered_workbook
    excel_file = Tempfile.new(['cohort_changes', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'redacts the client name in the Excel export' do
    get warehouse_reports_cohort_changes_path(filter: filter_params, format: :xlsx)

    expect(response).to have_http_status(:ok)
    data_row = rendered_workbook.sheet(0).row(2)
    expect(data_row[1]).to eq('Name Redacted')
    expect(data_row[2]).to eq('Name Redacted')
  end

  context 'when the matching client is not restricted' do
    let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'Client') }
    let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client') }
    let!(:open_cohort_client) { GrdaWarehouse::CohortClient.create!(cohort: cohort, client: open_destination_client) }
    let!(:open_cohort_client_change) do
      GrdaWarehouse::CohortClientChange.create!(cohort: cohort, cohort_client: open_cohort_client, user: user, change: 'create', changed_at: 1.week.ago)
    end

    before do
      GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
    end

    it 'shows its real name alongside the redacted restricted client' do
      get warehouse_reports_cohort_changes_path(filter: filter_params)

      expect(response.body).to include('Open')
      expect(response.body).to include('Name Redacted')
    end
  end
end
