###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::ActiveVeteransController#show', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/active_veterans', name: 'Active Veterans') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:active_veterans_report) do
    create(
      :active_veterans_report,
      user: user,
      data: [
        {
          'id' => restricted_destination_client.id,
          'FirstName' => restricted_destination_client.FirstName,
          'LastName' => restricted_destination_client.LastName,
          'DOB' => Date.new(1990, 1, 1),
          'SSN' => '111223333',
          'data_sources' => ['DS'],
          'first_date_served' => 1.year.ago.to_date,
          'enrollments' => [
            {
              'ds_short_name' => 'DS',
              'project_type' => 1,
              'project_name' => 'Project',
              'first_date_in_program' => 1.year.ago.to_date,
              'last_date_in_program' => nil,
            },
          ],
        },
      ],
    )
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  def rendered_workbook
    excel_file = Tempfile.new(['active_veterans', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'redacts the restricted client name, DOB, and SSN in the Excel export' do
    get warehouse_reports_active_veteran_path(active_veterans_report, format: :xlsx)

    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    row = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }.find { |r| r[0] == restricted_destination_client.id }
    expect(row[1]).to eq('Name Redacted')
    expect(row[2]).to eq('Name Redacted')
    # PiiProvider#dob_or_age falls back to age when the full DOB is hidden.
    expect(row[3]).to be_a(Numeric)
    expect(row[4]).to eq('Redacted')
  end
end
