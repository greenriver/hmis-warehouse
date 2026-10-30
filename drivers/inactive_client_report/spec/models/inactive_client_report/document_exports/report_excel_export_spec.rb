###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'roo'

RSpec.describe InactiveClientReport::DocumentExports::ReportExcelExport, type: :model do
  include_context 'inactive client report fixtures'

  let!(:restricted_destination_client) { create_report_client(first_name: 'Restricted', last_name: 'RClient') }
  let!(:open_destination_client) { create_report_client(first_name: 'Open', last_name: 'OClient') }

  let(:query_string) do
    {
      filters: {
        on: on_date.to_s,
        start: 1.year.ago.to_date.to_s,
        end: on_date.to_s,
        project_ids: [project.id],
        require_service_during_range: 'false',
      },
    }.to_query
  end
  let(:export) { described_class.new(user_id: user.id, query_string: query_string) }

  after { GrdaWarehouse::Config.invalidate_cache }

  before do
    Hmis::Hud::Client.find(restricted_destination_client.source_clients.first.id).mark_as_restricted!(user: hmis_user)
  end

  def generated_sheet
    export.perform
    expect(export.status).to eq(GrdaWarehouse::DocumentExport::COMPLETED_STATUS)
    file = Tempfile.new(['inactive_client_export', '.xlsx'])
    file.binmode
    file.write(export.file_data)
    file.close
    Roo::Excelx.new(file.path).sheet(0)
  ensure
    file&.unlink
  end

  it 'is authorized for a user with report and project access' do
    expect(export.authorized?).to eq(true)
  end

  it 'redacts the restricted client name and DOB and shows them for the unrestricted client when the download toggle is on' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
    GrdaWarehouse::Config.invalidate_cache

    sheet = generated_sheet
    restricted_row = sheet_row_by_header(sheet, key: restricted_destination_client.id)
    open_row = sheet_row_by_header(sheet, key: open_destination_client.id)

    expect(restricted_row.values_at('Last Name', 'First Name')).to eq(['Name Redacted', 'Name Redacted'])
    expect(restricted_row['DOB']).to be_nil
    expect(open_row.values_at('Last Name', 'First Name')).to eq(['OClient', 'Open'])
    expect(open_row['DOB'].to_date).to eq(Date.new(1990, 6, 15))
  end

  it 'keeps the Age column for both clients when the download toggle is on' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
    GrdaWarehouse::Config.invalidate_cache

    sheet = generated_sheet
    expected_age = GrdaWarehouse::Hud::Client.age(date: Date.current, dob: Date.new(1990, 6, 15))

    expect(sheet_row_by_header(sheet, key: restricted_destination_client.id)['Age'].to_i).to eq(expected_age)
    expect(sheet_row_by_header(sheet, key: open_destination_client.id)['Age'].to_i).to eq(expected_age)
  end

  it 'omits the name and DOB columns for every client when the download toggle is off' do
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
    GrdaWarehouse::Config.invalidate_cache

    sheet = generated_sheet
    restricted_row = sheet_row_by_header(sheet, key: restricted_destination_client.id)
    open_row = sheet_row_by_header(sheet, key: open_destination_client.id)

    expect(restricted_row.keys).not_to include('Last Name', 'First Name', 'DOB')
    expect(open_row.keys).not_to include('Last Name', 'First Name', 'DOB')
    expect(open_row.keys).to include('Warehouse ID', 'Age', 'Last Seen', 'Ongoing Enrollments')
  end

  describe 'with the days-since-contact filter on and one client per batch' do
    let(:query_string) do
      {
        filters: {
          on: on_date.to_s,
          project_ids: [project.id],
          require_service_during_range: 'false',
          days_since_contact_min: 0,
          days_since_contact_max: 10_000,
        },
      }.to_query
    end
    let(:restricted_service_date) { 10.days.ago.to_date }
    let(:open_service_date) { 20.days.ago.to_date }

    before do
      stub_const("#{described_class}::BATCH_SIZE", 1)
      # The days-since-contact filter keeps only clients with an assessment, a service, and a CLS.
      { restricted_destination_client => restricted_service_date, open_destination_client => open_service_date }.each do |client, service_date|
        create_enrollment_record(:hud_assessment, client, AssessmentDate: 30.days.ago.to_date)
        create_enrollment_record(:hud_service, client, DateProvided: service_date)
        create_enrollment_record(:hud_current_living_situation, client, InformationDate: 30.days.ago.to_date)
      end
    end

    it 'runs the days-since-contact query once for the whole export' do
      contact_queries = []
      callback = ->(*, payload) { contact_queries << payload[:sql] if payload[:sql].include?('assessment_dates') }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { generated_sheet }

      expect(contact_queries.size).to eq(1)
    end

    it 'writes each client its own most-recent bed night' do
      sheet = generated_sheet

      expect(sheet_row_by_header(sheet, key: restricted_destination_client.id)['Most-Recent Bed Night'].to_date).to eq(restricted_service_date)
      expect(sheet_row_by_header(sheet, key: open_destination_client.id)['Most-Recent Bed Night'].to_date).to eq(open_service_date)
    end
  end
end
