###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# CasAccess::Client (and every model under CasBase) is a no-op stub in this test
# environment -- ENV['DATABASE_CAS_DB'] is only set in development, so `CasBase` never
# connects to a real second database here (see app/models/cas_base.rb). `#clients`, the one
# method WarehouseReport::CasDeclines uses to look up a name, is stubbed on the real report
# instance below; `cancels`/`declines`/`all_steps` all run against real `GrdaWarehouse::CasReport`
# rows (a warehouse-DB table, unaffected by the CAS DB gap).
RSpec.describe 'WarehouseReports::Cas::DeclineReasonController#index', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_client_name: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/cas/decline_reason', name: 'CAS Decline Reasons') }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds) }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client) }
  let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds) }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client) }
  let(:restricted_cas_client_id) { 1 }
  let(:open_cas_client_id) { 2 }

  after { GrdaWarehouse::Config.invalidate_cache }

  # GrdaWarehouse::CasReport is `readonly?` (populated by an external CAS sync job), so rows are
  # inserted directly rather than through `create!`/`save`.
  def insert_cas_report(client:, cas_client_id:, match_id:, decision_status:, decline_reason: nil, administrative_cancel_reason: nil)
    GrdaWarehouse::CasReport.insert!(
      {
        client_id: client.id,
        cas_client_id: cas_client_id,
        match_id: match_id,
        decision_id: match_id,
        decision_order: 1,
        match_step: 'Housing Search',
        decision_status: decision_status,
        decline_reason: decline_reason,
        administrative_cancel_reason: administrative_cancel_reason,
        match_started_at: 6.months.ago,
        shelter_agency_contacts: [],
        hsa_contacts: [],
        created_at: 6.months.ago,
        updated_at: 6.months.ago,
      },
    )
  end

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)

    insert_cas_report(client: restricted_destination_client, cas_client_id: restricted_cas_client_id, match_id: 1, decision_status: 'Declined', decline_reason: 'Client declined')
    insert_cas_report(client: open_destination_client, cas_client_id: open_cas_client_id, match_id: 2, decision_status: 'Declined', decline_reason: 'Client declined')
    insert_cas_report(client: restricted_destination_client, cas_client_id: restricted_cas_client_id, match_id: 3, decision_status: 'Canceled', administrative_cancel_reason: 'Other')
    insert_cas_report(client: open_destination_client, cas_client_id: open_cas_client_id, match_id: 4, decision_status: 'Canceled', administrative_cancel_reason: 'Other')

    cas_client = Struct.new(:first_name, :last_name)
    cas_clients = {
      restricted_cas_client_id => cas_client.new('Restrictedfirst', 'Restrictedlast'),
      open_cas_client_id => cas_client.new('Openfirst', 'Openlast'),
    }
    allow(WarehouseReport::CasDeclines).to receive(:new).and_wrap_original do |original, **kwargs|
      original.call(**kwargs).tap { |instance| allow(instance).to receive(:clients).and_return(cas_clients) }
    end

    sign_in user
  end

  def rendered_workbook
    excel_file = Tempfile.new(['decline_reason', '.xlsx'])
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

  # Column A is 'Canceled'/'Declined'; column B (index 1) is the warehouse client_id.
  def row_for(rows, kind:, client:)
    rows.find { |r| r[0] == kind && r[1] == client.id }
  end

  it 'redacts the restricted client and shows the unrestricted client in both the Declined and Canceled sections when the download toggle is on' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

    get warehouse_reports_cas_decline_reason_index_path(format: :xlsx)

    expect(response).to have_http_status(:success)
    rows = workbook_rows

    ['Declined', 'Canceled'].each do |kind|
      restricted_row = row_for(rows, kind: kind, client: restricted_destination_client)
      expect(restricted_row).not_to be_nil, "missing #{kind} row for the restricted client"
      expect(restricted_row[5]).to eq('Name Redacted')
      expect(restricted_row[6]).to eq('Name Redacted')

      open_row = row_for(rows, kind: kind, client: open_destination_client)
      expect(open_row).not_to be_nil, "missing #{kind} row for the open client"
      expect(open_row[5]).to eq('Openfirst')
      expect(open_row[6]).to eq('Openlast')
    end
  end

  it 'redacts every client in both sections when the download toggle is off' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)

    get warehouse_reports_cas_decline_reason_index_path(format: :xlsx)

    expect(response).to have_http_status(:success)
    rows = workbook_rows
    ['Declined', 'Canceled'].each do |kind|
      [restricted_destination_client, open_destination_client].each do |client|
        row = row_for(rows, kind: kind, client: client)
        expect(row).not_to be_nil, "missing #{kind} row for client #{client.id}"
        expect(row[5]).to eq('Name Redacted')
        expect(row[6]).to eq('Name Redacted')
      end
    end
  end
end
