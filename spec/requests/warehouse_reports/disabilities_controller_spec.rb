###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WarehouseReports::DisabilitiesController#show', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let(:sensitive_permissions) { {} }
  let!(:role) do
    create(
      :role,
      can_view_all_reports: true,
      can_view_assigned_reports: true,
      can_view_client_name: true,
      **sensitive_permissions,
    )
  end
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/disabilities', name: 'Enrolled clients with selected disabilities') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restrictedfirst', last_name: 'Restrictedlast') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restrictedfirst', LastName: 'Restrictedlast') }
  let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Openfirst', last_name: 'Openlast') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Openfirst', LastName: 'Openlast') }

  def client_row(client)
    {
      'id' => client.id,
      'FirstName' => client.FirstName,
      'LastName' => client.LastName,
      'VeteranStatus' => 0,
      'enrollment' => { 'age' => 40, 'unaccompanied_youth' => false, 'parenting_youth' => false, 'head_of_household' => true },
      'disabilities' => ['Physical disability', 'HIV/AIDS', 'Mental health disorder'],
    }
  end

  let!(:disability_report) do
    create(:enrolled_disabled_report, data: [client_row(restricted_destination_client), client_row(open_destination_client)])
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in user
  end

  it 'redacts only the restricted client name in the html view' do
    get warehouse_reports_disability_path(disability_report)

    expect(response.body).not_to include('Restrictedfirst')
    expect(response.body).not_to include('Restrictedlast')
    expect(response.body).to include('Name Redacted')
    expect(response.body).to include('Openfirst')
    expect(response.body).to include('Openlast')
  end

  def rendered_workbook
    excel_file = Tempfile.new(['disabilities', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'redacts only the restricted client name in the Excel export' do
    get warehouse_reports_disability_path(disability_report, format: :xlsx)

    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    rows = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }

    restricted_row = rows.find { |r| r[0] == restricted_destination_client.id }
    expect(restricted_row[1]).to eq('Name Redacted')
    expect(restricted_row[2]).to eq('Name Redacted')

    open_row = rows.find { |r| r[0] == open_destination_client.id }
    expect(open_row[1]).to eq('Openfirst')
    expect(open_row[2]).to eq('Openlast')
  end

  describe 'sensitive disability labels' do
    # The viewer lacks can_view_clients, so rows have no client links; find the row by last name
    def html_labels_for(last_name)
      rows = Nokogiri::HTML(response.body).css('tbody tr')
      row = rows.find { |r| r.text.include?(last_name) }
      row.css('label').map { |label| label.text.strip }
    end

    def xlsx_labels_for(client)
      sheet = rendered_workbook.sheet(0)
      rows = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }
      rows.find { |r| r[0] == client.id }[8].to_s.split(', ')
    end

    context 'when the viewer cannot view HIV or mental health status' do
      it 'hides both labels in the html view' do
        get warehouse_reports_disability_path(disability_report)

        expect(html_labels_for('Openlast')).to eq(['Physical disability'])
      end

      it 'hides both labels in the Excel export' do
        get warehouse_reports_disability_path(disability_report, format: :xlsx)

        expect(xlsx_labels_for(open_destination_client)).to eq(['Physical disability'])
      end
    end

    context 'when the viewer can view HIV and mental health status' do
      let(:sensitive_permissions) { { can_view_hiv_status: true, can_view_dmh_status: true } }

      it 'shows both labels for an unrestricted client' do
        get warehouse_reports_disability_path(disability_report, format: :xlsx)

        expect(xlsx_labels_for(open_destination_client)).to eq(['Physical disability', 'HIV/AIDS', 'Mental health disorder'])
      end

      it 'hides HIV/AIDS for a restricted client' do
        get warehouse_reports_disability_path(disability_report, format: :xlsx)

        expect(xlsx_labels_for(restricted_destination_client)).to eq(['Physical disability', 'Mental health disorder'])
      end

      it 'hides HIV/AIDS in the Excel export when detail downloads exclude PII' do
        allow(GrdaWarehouse::Config).to receive(:get).and_call_original
        allow(GrdaWarehouse::Config).to receive(:get).with(:include_pii_in_detail_downloads).and_return(false)

        get warehouse_reports_disability_path(disability_report, format: :xlsx)

        expect(xlsx_labels_for(open_destination_client)).to eq(['Physical disability', 'Mental health disorder'])
      end

      it 'hides HIV/AIDS for a restricted client in the html view' do
        get warehouse_reports_disability_path(disability_report)

        expect(html_labels_for('Openlast')).to eq(['Physical disability', 'HIV/AIDS', 'Mental health disorder'])
        expect(html_labels_for('Name Redacted')).to eq(['Physical disability', 'Mental health disorder'])
      end
    end
  end

  describe 'with more clients than the preload miss threshold' do
    let!(:many_clients) do
      Array.new(preload_miss_client_count) do |i|
        create(:grda_warehouse_hud_client, FirstName: "Manyfirst#{i}", LastName: "Manylast#{i}")
      end
    end
    let!(:large_report) { create(:enrolled_disabled_report, data: many_clients.map { |client| client_row(client) }) }

    it 'renders every client in the html view' do
      get warehouse_reports_disability_path(large_report)

      expect(response).to have_http_status(:ok)
      many_clients.each { |client| expect(response.body).to include(client.LastName) }
    end

    it 'renders every client in the Excel export' do
      get warehouse_reports_disability_path(large_report, format: :xlsx)

      expect(response).to have_http_status(:ok)
      expect(xlsx_cell_values(response)).to include(*many_clients.map(&:id))
    end
  end
end
