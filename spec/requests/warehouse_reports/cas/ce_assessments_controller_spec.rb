###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::Cas::CeAssessmentsController', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) do
    create(
      :role,
      can_view_all_reports: true,
      can_view_assigned_reports: true,
      can_view_projects: true,
      can_view_clients: true,
      can_view_client_name: true,
      can_view_full_ssn: true,
      can_view_full_dob: true,
    )
  end
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/cas/ce_assessments', name: 'CE Assessment Status') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restrictedfirst', last_name: 'Restrictedlast') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restrictedfirst', LastName: 'Restrictedlast', SSN: '111223333', DOB: Date.new(1990, 1, 1)) }
  let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Openfirst', last_name: 'Openlast') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Openfirst', LastName: 'Openlast', SSN: '444556666', DOB: Date.new(1985, 5, 5)) }
  let!(:organization) { create(:hud_organization, data_source: hmis_ds) }
  let!(:project) { create(:hud_project, data_source: hmis_ds, OrganizationID: organization.OrganizationID, ProjectType: 1, TrackingMethod: 3) } # ES, Night-by-Night
  let!(:she) do
    create(:she_entry, client: restricted_destination_client, project: project,
                       record_type: :entry, project_type: 1, age: 30, first_date_in_program: 2.years.ago.to_date, last_date_in_program: nil)
  end
  let!(:open_she) do
    create(:she_entry, client: open_destination_client, project: project,
                       record_type: :entry, project_type: 1, age: 30, first_date_in_program: 2.years.ago.to_date, last_date_in_program: nil)
  end
  # `SourceClientPolicy#add_project_based_permissions` grants the role's client-PII permissions
  # only for projects a *source* client has a real HUD enrollment in (`Project#clients` joins
  # `:enrollments`) -- the destination-scoped `she_entry` above satisfies the report's own
  # homeless/ongoing filtering but not this permission check.
  let!(:enrollment) { create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(restricted_source_client.id), project: project, data_source: hmis_ds) }
  let!(:open_enrollment) { create(:hud_enrollment, client: GrdaWarehouse::Hud::Client.find(open_source_client.id), project: project, data_source: hmis_ds) }
  let!(:processed) { create(:grda_warehouse_warehouse_clients_processed, client: restricted_destination_client, days_homeless_last_three_years: 300, literally_homeless_last_three_years: 300) }
  let!(:open_processed) { create(:grda_warehouse_warehouse_clients_processed, client: open_destination_client, days_homeless_last_three_years: 300, literally_homeless_last_three_years: 300) }

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  def rendered_workbook
    excel_file = Tempfile.new(['ce_assessments', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  describe 'html' do
    it 'redacts the name, SSN, and DOB year for a restricted client while showing them for an unrestricted client' do
      get warehouse_reports_cas_ce_assessments_path(filter: { project_id: project.id })

      expect(response.body).not_to include('Restrictedfirst')
      expect(response.body).not_to include('Restrictedlast')
      expect(response.body).not_to include('111223333')
      expect(response.body).not_to include('111-22-3333')
      expect(response.body).not_to include('1990')
      expect(response.body.scan('Name Redacted').size).to eq(2)

      expect(response.body).to include('Openfirst')
      expect(response.body).to include('Openlast')
      expect(response.body).to include('444-55-6666')
      expect(response.body).to include('1985')

      # First/Last name are the only linked cells, so the restricted client's row is found by its
      # client-dashboard href rather than by name text (which is redacted).
      doc = Nokogiri::HTML(response.body)
      restricted_row = doc.css('tbody tr').find { |tr| tr.at_css(%(a[href*="/clients/#{restricted_destination_client.id}/"])) }
      expect(restricted_row).not_to be_nil
      row_cell_texts = restricted_row.css('td').map { |td| td.text.strip }
      expect(row_cell_texts[2]).to eq(GrdaWarehouse::PiiProvider::REDACTED)
    end
  end

  describe 'xlsx' do
    it 'redacts the restricted client and shows the unrestricted client when the download toggle is on' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

      get warehouse_reports_cas_ce_assessments_path(filter: { project_id: project.id }, format: :xlsx)

      expect(response).to have_http_status(:success)
      sheet = rendered_workbook.sheet(0)
      rows = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }

      restricted_row = rows.find { |r| r[0] == restricted_destination_client.id }
      expect(restricted_row[1]).to eq('Name Redacted')
      expect(restricted_row[2]).to eq('Name Redacted')
      expect(restricted_row[3]).to eq('Redacted')
      expect(restricted_row[4]).to be_nil

      open_row = rows.find { |r| r[0] == open_destination_client.id }
      expect(open_row[1]).to eq('Openfirst')
      expect(open_row[2]).to eq('Openlast')
      expect(open_row[3]).to eq('444-55-6666')
      expect(open_row[4]).to eq(1985)
    end

    it 'redacts the name, SSN, and DOB year for every client when the download toggle is off' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
      GrdaWarehouse::Config.invalidate_cache

      get warehouse_reports_cas_ce_assessments_path(filter: { project_id: project.id }, format: :xlsx)

      expect(response).to have_http_status(:success)
      sheet = rendered_workbook.sheet(0)
      rows = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }

      [restricted_destination_client, open_destination_client].each do |client|
        row = rows.find { |r| r[0] == client.id }
        expect(row[1]).to eq('Name Redacted')
        expect(row[2]).to eq('Name Redacted')
        expect(row[3]).to eq('Redacted')
        expect(row[4]).to be_nil
      end
    end
  end
end
