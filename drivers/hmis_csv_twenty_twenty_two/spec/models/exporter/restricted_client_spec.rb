###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/export_helper_2022'

RSpec.describe HmisCsvTwentyTwentyTwo::Exporter::Base, type: :model do
  before(:all) do
    cleanup_test_environment
    ExportHelper2022.setup_data
    @restricted_source_client = ExportHelper2022.clients.first
    @restricted_source_client.destination_client.update!(DOB: '1980-05-06')
    Hmis::Hud::Client.find(@restricted_source_client.id).mark_as_restricted!(user: FactoryBot.create(:hmis_user))
  end

  after(:all) do
    # cleanup_test_environment clears the warehouse database only; Hmis::RestrictedRecord lives
    # on the HMIS database and would otherwise survive into later spec files.
    Hmis::RestrictedRecord.with_deleted.where(restrictable_id: @restricted_source_client.id).delete_all
    ExportHelper2022.cleanup
  end

  def run_export(**options)
    exporter = HmisCsvTwentyTwentyTwo::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: ExportHelper2022.projects.map(&:id),
      period_type: 3,
      directive: 3,
      user_id: ExportHelper2022.user.id,
      **options,
    )
    exporter.export!(cleanup: false, zip: false, upload: false)
    exporter
  end

  def client_rows(exporter)
    CSV.read(ExportHelper2022.csv_file_path(ExportHelper2022.client_class, exporter: exporter), headers: true)
  end

  describe 'a plain export' do
    before(:all) { @exporter = run_export }
    after(:all) { @exporter.remove_export_files }

    it "redacts the restricted client's name and SSN" do
      row = client_rows(@exporter).find { |r| r['PersonalID'] == @restricted_source_client.destination_client.id.to_s }
      expect(row.to_h).to include(
        'FirstName' => GrdaWarehouse::PiiProvider::REDACTED,
        'LastName' => GrdaWarehouse::PiiProvider::REDACTED,
        'MiddleName' => GrdaWarehouse::PiiProvider::REDACTED,
        'NameSuffix' => GrdaWarehouse::PiiProvider::REDACTED,
        'SSN' => '',
        'SSNDataQuality' => '99',
      )
    end

    it 'leaves DOB unredacted' do
      row = client_rows(@exporter).find { |r| r['PersonalID'] == @restricted_source_client.destination_client.id.to_s }
      expect(row['DOB']).to eq('1980-05-06')
    end

    it 'leaves an unrestricted client row untouched' do
      unrestricted_source_client = ExportHelper2022.clients.second
      row = client_rows(@exporter).find { |r| r['PersonalID'] == unrestricted_source_client.destination_client.id.to_s }
      expect(row['FirstName']).not_to eq(GrdaWarehouse::PiiProvider::REDACTED)
      expect(row['SSN']).to eq(unrestricted_source_client.SSN)
    end
  end

  describe 'a hashed export (hash_status: 4)' do
    before(:all) { @exporter = run_export(hash_status: 4) }
    after(:all) { @exporter.remove_export_files }

    it "hashes the restricted client's name and SSN instead of redacting them" do
      row = client_rows(@exporter).find { |r| r['PersonalID'] == @restricted_source_client.destination_client.id.to_s }
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
