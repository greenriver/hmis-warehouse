###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Shared by the FY2022/2024/2026 exporter specs. `described_class` is the driver's
# Exporter::Base; `helper` is that driver's ExportHelperYYYY module (auto-required by
# rails_helper from drivers/*/spec/support).
RSpec.shared_examples 'an HMIS CSV export that redacts restricted clients' do |helper:|
  before(:all) do
    cleanup_test_environment
    helper.setup_data
    @restricted_source_client = helper.clients.first
    @restricted_source_client.destination_client.update!(DOB: '1980-05-06')
    Hmis::Hud::Client.find(@restricted_source_client.id).mark_as_restricted!(user: FactoryBot.create(:hmis_user))
  end

  after(:all) do
    # cleanup_test_environment clears the warehouse database only; Hmis::RestrictedRecord lives
    # on the HMIS database and would otherwise survive into later spec files.
    Hmis::RestrictedRecord.with_deleted.where(restrictable_id: @restricted_source_client.id).delete_all
    helper.cleanup
  end

  # define_method (not def) so the `helper` block argument is visible inside.
  define_method(:run_export) do |**options|
    exporter = described_class.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: helper.projects.map(&:id),
      period_type: 3,
      directive: 3,
      user_id: helper.user.id,
      **options,
    )
    exporter.export!(cleanup: false, zip: false, upload: false)
    exporter
  end

  define_method(:client_rows) do |exporter|
    CSV.read(helper.csv_file_path(helper.client_class, exporter: exporter), headers: true)
  end

  define_method(:restricted_row) do |exporter|
    client_rows(exporter).find { |r| r['PersonalID'] == @restricted_source_client.destination_client.id.to_s }
  end

  describe 'a plain export' do
    before(:all) { @exporter = run_export }
    after(:all) { @exporter.remove_export_files }

    it "redacts the restricted client's name and SSN" do
      expect(restricted_row(@exporter).to_h).to include(
        'FirstName' => GrdaWarehouse::PiiProvider::REDACTED,
        'LastName' => GrdaWarehouse::PiiProvider::REDACTED,
        'MiddleName' => GrdaWarehouse::PiiProvider::REDACTED,
        'NameSuffix' => GrdaWarehouse::PiiProvider::REDACTED,
        'SSN' => '',
        'SSNDataQuality' => '99',
      )
    end

    it 'leaves DOB unredacted' do
      expect(restricted_row(@exporter)['DOB']).to eq('1980-05-06')
    end

    it 'leaves an unrestricted client row untouched' do
      unrestricted_source_client = helper.clients.second
      row = client_rows(@exporter).find { |r| r['PersonalID'] == unrestricted_source_client.destination_client.id.to_s }
      expect(row['FirstName']).not_to eq(GrdaWarehouse::PiiProvider::REDACTED)
      expect(row['SSN']).to eq(unrestricted_source_client.SSN)
    end
  end

  describe 'a hashed export (hash_status: 4)' do
    before(:all) { @exporter = run_export(hash_status: 4) }
    after(:all) { @exporter.remove_export_files }

    it "hashes the restricted client's name and SSN instead of redacting them" do
      row = restricted_row(@exporter)
      expect(row['FirstName']).to eq(Digest::SHA256.hexdigest(Soundex.new(@restricted_source_client.FirstName).soundex))
      expect(row['FirstName']).not_to eq(GrdaWarehouse::PiiProvider::REDACTED)
      expect(row['SSN']).not_to be_nil
      expect(row['SSN']).not_to eq(GrdaWarehouse::PiiProvider::REDACTED)
    end
  end

  describe 'a faked export (faked_pii: true)' do
    before(:all) { @exporter = run_export(faked_pii: true) }
    after(:all) { @exporter.remove_export_files }

    it "fakes the restricted client's name instead of redacting it" do
      # Faking replaces PersonalID with a hash of the real id, so the restricted row can no
      # longer be matched by PersonalID -- assert redaction never ran on any row instead.
      expect(client_rows(@exporter).map { |r| r['FirstName'] }).not_to include(GrdaWarehouse::PiiProvider::REDACTED)
    end
  end
end
