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
  let(:cas_client_id) { 1 }

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id] })
    setup_access_control(user, role, collection)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)

    # GrdaWarehouse::CasReport is `readonly?` (populated by an external CAS sync job), so
    # rows are inserted directly rather than through `create!`/`save`.
    GrdaWarehouse::CasReport.insert!(
      {
        client_id: restricted_destination_client.id,
        cas_client_id: cas_client_id,
        match_id: 1,
        decision_id: 1,
        decision_order: 1,
        match_step: 'Housing Search',
        decision_status: 'Declined',
        decline_reason: 'Client declined',
        match_started_at: 6.months.ago,
        shelter_agency_contacts: [],
        hsa_contacts: [],
        created_at: Time.current,
        updated_at: Time.current,
      },
    )

    cas_client = Struct.new(:first_name, :last_name).new('Restricted', 'Client')
    allow(WarehouseReport::CasDeclines).to receive(:new).and_wrap_original do |original, **kwargs|
      original.call(**kwargs).tap { |instance| allow(instance).to receive(:clients).and_return(cas_client_id => cas_client) }
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

  it 'redacts the restricted client name in the Excel export' do
    get warehouse_reports_cas_decline_reason_index_path(format: :xlsx)

    expect(response).to have_http_status(:success)
    sheet = rendered_workbook.sheet(0)
    rows = (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }
    expect(rows.flatten).not_to include('Restricted')
    expect(rows.flatten).to include('Name Redacted')
  end
end
