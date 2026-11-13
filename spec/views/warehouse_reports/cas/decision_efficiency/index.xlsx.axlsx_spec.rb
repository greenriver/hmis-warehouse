###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Same rationale as _table.haml_spec.rb: the report's @data comes from the CAS database, which
# is a no-op stub in test, so the xlsx template is rendered directly against plain row hashes.
RSpec.describe 'warehouse_reports/cas/decision_efficiency/index', type: :view do
  let!(:user) { create(:acl_user) }
  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds) }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client) }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client) }

  after { GrdaWarehouse::Config.invalidate_cache }

  def row(client, first_name:, last_name:)
    {
      days: 3,
      first_ended_at: 10.days.ago,
      second_ended_at: 7.days.ago,
      match_route: 'Standard',
      program_name: 'Program',
      sub_program_name: 'Sub Program',
      match_id: 1,
      match_stated_at: 10.days.ago,
      client_move_in_date: nil,
      first_name: first_name,
      last_name: last_name,
      warehouse_client_id: client.id,
      hsa_contacts: [],
      hsp_contacts: [],
    }
  end

  before do
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)

    assign(:data, [
             row(restricted_destination_client, first_name: 'Restrictedfirst', last_name: 'Restrictedlast'),
             row(open_destination_client, first_name: 'Openfirst', last_name: 'Openlast'),
           ])
    assign(:filter, double(first_step: 'Selected', second_step: 'Approved'))
    without_partial_double_verification do
      allow(view).to receive(:current_user).and_return(user)
    end
  end

  def render_workbook
    render template: 'warehouse_reports/cas/decision_efficiency/index', formats: [:xlsx], handlers: [:axlsx]
    excel_file = Tempfile.new(['decision_efficiency', '.xlsx'])
    excel_file.binmode
    excel_file.write(rendered)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  # Column layout: index 9 = Client (brief name), index 10 = Warehouse Client ID.
  def rows_by_client_id
    sheet = render_workbook.sheet(0)
    (sheet.first_row..sheet.last_row).map { |i| sheet.row(i) }.index_by { |r| r[10] }
  end

  it 'redacts only the restricted client name when the download toggle is on' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

    rows = rows_by_client_id
    expect(rows.fetch(restricted_destination_client.id)[9]).to eq('Name Redacted')
    expect(rows.fetch(open_destination_client.id)[9]).to eq('Openfirst Openlast')
  end

  it 'redacts every client name when the download toggle is off' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)

    rows = rows_by_client_id
    expect(rows.fetch(restricted_destination_client.id)[9]).to eq('Name Redacted')
    expect(rows.fetch(open_destination_client.id)[9]).to eq('Name Redacted')
  end
end
