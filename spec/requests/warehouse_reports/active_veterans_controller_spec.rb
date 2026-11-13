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
  # PII here resolves through DestinationClientPolicy -> SourceClientPolicy, so the role needs the
  # specific PII permissions and the collection must grant the client's enrolled project.
  let!(:role) do
    create(
      :role,
      can_view_all_reports: true,
      can_view_assigned_reports: true,
      can_view_clients: true,
      can_view_client_name: true,
      can_view_full_dob: true,
      can_view_full_ssn: true,
    )
  end
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/active_veterans', name: 'Active Veterans') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:destination_ds) { create(:destination_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:project) { create(:hud_project, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restrictedfirst', last_name: 'Restrictedlast') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, data_source: destination_ds, FirstName: 'Restrictedfirst', LastName: 'Restrictedlast') }
  let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Openfirst', last_name: 'Openlast') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, data_source: destination_ds, FirstName: 'Openfirst', LastName: 'Openlast') }

  def client_row(client, dob:, ssn:)
    {
      'id' => client.id,
      'FirstName' => client.FirstName,
      'LastName' => client.LastName,
      'DOB' => dob,
      'SSN' => ssn,
      'data_sources' => ['DS'],
      'first_date_served' => 1.year.ago.to_date,
      'first_service_history' => 1.year.ago.to_date,
      'enrollments' => [
        {
          'ds_short_name' => 'DS',
          'project_type' => 1,
          'project_id' => project.id,
          'project_name' => 'Project',
          'first_date_in_program' => 1.year.ago.to_date,
          'last_date_in_program' => nil,
        },
      ],
    }
  end

  let!(:active_veterans_report) do
    create(
      :active_veterans_report,
      user: user,
      parameters: { 'range' => {} },
      data: [
        client_row(restricted_destination_client, dob: Date.new(1990, 1, 1), ssn: '111223333'),
        client_row(open_destination_client, dob: Date.new(1985, 6, 15), ssn: '999887777'),
      ],
    )
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
    # Both clients are enrolled in the granted project so that, absent restriction, both would be
    # visible -- the restricted row's redaction is then attributable only to the restriction.
    create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(restricted_source_client.id), project: project, data_source: hmis_ds)
    create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(open_source_client.id), project: project, data_source: hmis_ds)
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

  def workbook_rows
    sheet = rendered_workbook.sheet(0)
    (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }
  end

  describe 'html' do
    it 'redacts the restricted client name, DOB, and SSN' do
      get warehouse_reports_active_veteran_path(active_veterans_report)

      expect(response.body).not_to include('Restrictedfirst')
      expect(response.body).not_to include('Restrictedlast')
      expect(response.body).not_to include('Jan  1, 1990')
      expect(response.body).not_to include('111-22-3333')
      expect(response.body).not_to include('XXX-XX-3333')
      expect(response.body).to include('Name Redacted')
    end

    it 'shows the unrestricted client name, DOB, and SSN when the role grants them on an enrolled project' do
      get warehouse_reports_active_veteran_path(active_veterans_report)

      expect(response.body).to include('Openfirst Openlast')
      expect(response.body).to include('Jun 15, 1985')
      expect(response.body).to include('999-88-7777')
    end

    it 'masks the unrestricted client SSN and shows age instead of DOB when the role lacks those permissions' do
      role.update!(can_view_full_dob: false, can_view_full_ssn: false)

      get warehouse_reports_active_veteran_path(active_veterans_report)

      expect(response.body).to include('Openfirst Openlast')
      expect(response.body).not_to include('Jun 15, 1985')
      expect(response.body).to include(GrdaWarehouse::Hud::Client.age(date: Date.current, dob: Date.new(1985, 6, 15)).to_s)
      expect(response.body).not_to include('999-88-7777')
      expect(response.body).to include('XXX-XX-7777')
    end
  end

  describe 'xlsx' do
    it 'redacts the restricted client and shows the unrestricted client when the download toggle is on' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

      get warehouse_reports_active_veteran_path(active_veterans_report, format: :xlsx)

      expect(response).to have_http_status(:success)
      rows = workbook_rows

      restricted_row = rows.find { |r| r[0] == restricted_destination_client.id }
      expect(restricted_row[1]).to eq('Name Redacted')
      expect(restricted_row[2]).to eq('Name Redacted')
      # PiiProvider#dob_or_age falls back to the age when the full DOB is hidden.
      expect(restricted_row[3]).to eq(GrdaWarehouse::Hud::Client.age(date: Date.current, dob: Date.new(1990, 1, 1)))
      expect(restricted_row[4]).to eq('Redacted')

      open_row = rows.find { |r| r[0] == open_destination_client.id }
      expect(open_row[1]).to eq('Openfirst')
      expect(open_row[2]).to eq('Openlast')
      expect(open_row[3].to_s).to eq('Jun 15, 1985')
      expect(open_row[4].to_s).to eq('999-88-7777')
    end

    it 'redacts every client when the download toggle is off' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)

      get warehouse_reports_active_veteran_path(active_veterans_report, format: :xlsx)

      expect(response).to have_http_status(:success)
      rows = workbook_rows
      [restricted_destination_client, open_destination_client].each do |client|
        row = rows.find { |r| r[0] == client.id }
        expect(row[1]).to eq('Name Redacted')
        expect(row[2]).to eq('Name Redacted')
        expect(row[4]).to eq('Redacted')
      end
    end
  end
end
