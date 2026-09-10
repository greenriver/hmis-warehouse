###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'zip'

RSpec.describe 'WarehouseReports::YouthIntakeExport#create (Download Per-Client Data)', type: :request do
  let!(:role) { create(:can_view_youth_intake, can_view_all_reports: true) }
  let!(:user) do
    user = create(:user)
    user.legacy_roles << role
    user
  end

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Doe') }

  def required_intake_attrs
    {
      user: user,
      engagement_date: Date.current,
      staff_name: 'Staffer',
      staff_email: 'staffer@example.com',
      unaccompanied: 'No',
      street_outreach_contact: 'No',
      housing_status: 'x',
      other_agency_involvements: ['x'],
      secondary_education: 'x',
      attending_college: 'x',
      health_insurance: 'x',
      staff_believes_youth_under_24: 'x',
      client_gender: 0,
      client_lgbtq: 'x',
      client_primary_language: 'x',
      pregnant_or_parenting: 'x',
      needs_shelter: 'x',
      in_stable_housing: 'x',
      youth_experiencing_homelessness_at_start: 'x',
      client_race: ['x'],
      disabilities: ['x'],
      requesting_financial_assistance: 'x',
      referred_to_shelter: 'f',
    }
  end

  let!(:restricted_intake) do
    GrdaWarehouse::YouthIntake::Entry.create!(
      required_intake_attrs.merge(
        client: restricted_destination_client,
        first_name: 'Restricted',
        last_name: 'Client',
        ssn: '123456789',
        client_dob: Date.new(1990, 1, 1),
      ),
    )
  end
  let!(:open_intake) do
    GrdaWarehouse::YouthIntake::Entry.create!(
      required_intake_attrs.merge(
        client: open_destination_client,
        first_name: 'Open',
        last_name: 'Doe',
        ssn: '987654321',
        client_dob: Date.new(1985, 6, 15),
      ),
    )
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    allow_any_instance_of(WarehouseReports::YouthIntakeExportController).to receive(:report_visible?).and_return(true)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
    sign_in(user)
  end

  def sheet_for(zip_bytes, client_id)
    Zip::File.open_buffer(zip_bytes) do |zip|
      entry = zip.glob("Client #{client_id} - *.xlsx").first
      excel_file = Tempfile.new(['per_client', '.xlsx'])
      excel_file.binmode
      excel_file.write(entry.get_input_stream.read)
      excel_file.close
      begin
        return Roo::Excelx.new(excel_file.path).sheet('Youth Intakes')
      ensure
        excel_file.unlink
      end
    end
  end

  it 'redacts the restricted client and leaves the unrestricted client intact in the per-client Excel export' do
    post warehouse_reports_youth_intake_export_index_path(
      commit: 'Download Per-Client Data',
      format: :xlsx,
      filter: { start: 1.day.ago.to_date, end: Date.tomorrow },
    )

    expect(response).to have_http_status(:success)

    restricted_sheet = sheet_for(response.body, restricted_destination_client.id)
    open_sheet = sheet_for(response.body, open_destination_client.id)

    restricted_rows = (restricted_sheet.first_row..restricted_sheet.last_row).map { |i| restricted_sheet.row(i) }.to_h { |k, v| [k, v] }
    open_rows = (open_sheet.first_row..open_sheet.last_row).map { |i| open_sheet.row(i) }.to_h { |k, v| [k, v] }

    expect(restricted_rows['First Name']).to eq(GrdaWarehouse::PiiProvider::REDACTED)
    expect(restricted_rows['SSN']).to eq(GrdaWarehouse::PiiProvider::REDACTED)
    expect(restricted_rows['Client DOB']).to eq(GrdaWarehouse::PiiProvider::REDACTED)
    expect(open_rows['First Name']).to eq('Open')
    expect(open_rows['SSN'].to_s).to eq('987654321')
  end
end
