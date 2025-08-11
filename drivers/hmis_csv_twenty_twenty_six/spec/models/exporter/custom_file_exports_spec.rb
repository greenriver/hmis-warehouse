###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/export_helper_2026'

RSpec.describe HmisCsvTwentyTwentySix::Exporter::Base, type: :model do
  describe 'custom file exports' do
    before(:all) do
      cleanup_test_environment
      ExportHelper2026.setup_data

      # Create some custom gender data for testing using the data from the project we'll include in the export
      @client = ExportHelper2026.projects.first.clients.first
      @client.destination_client.update(
        Woman: 1,
        Man: 0,
        NonBinary: 0,
        CulturallySpecific: 0,
        Transgender: 0,
        Questioning: 0,
        DifferentIdentity: 0,
        GenderNone: 0,
        DifferentIdentityText: nil,
      )
    end

    after(:all) do
      ExportHelper2026.cleanup
    end

    describe 'with custom file types selected' do
      before(:all) do
        @exporter = HmisCsvTwentyTwentySix::Exporter::Base.new(
          start_date: 3.week.ago.to_date,
          end_date: Date.current,
          projects: [ExportHelper2026.projects.first.id],
          period_type: 3,
          directive: 3,
          user_id: ExportHelper2026.user.id,
          custom_file_types: ['CustomGender.csv'],
        )
        @export = @exporter.export!(cleanup: false, zip: false, upload: false)
      end

      it 'includes custom files in exportable_files' do
        expect(@exporter.exportable_files.keys.map(&:name)).to include('HmisCsvTwentyTwentySix::Exporter::Custom::CustomGender')
      end

      it 'generates CustomGender.csv file' do
        custom_gender_file = File.join(@exporter.file_path, 'CustomGender.csv')
        expect(File.exist?(custom_gender_file)).to be_truthy
      end

      it 'includes custom gender data in export' do
        custom_gender_file = File.join(@exporter.file_path, 'CustomGender.csv')
        csv_content = CSV.read(custom_gender_file, headers: true)

        expect(csv_content.length).to be > 0
        # Check that our test data is included
        client_row = csv_content.find { |row| row['PersonalID'] == @client.destination_client.id.to_s }
        expect(client_row).to be_present
        expect(client_row['Woman']).to eq('1')
        expect(client_row['Man']).to eq('0')
      end

      it 'sets correct ExportID on custom file records' do
        custom_gender_file = File.join(@exporter.file_path, 'CustomGender.csv')
        csv_content = CSV.read(custom_gender_file, headers: true)

        csv_content.each do |row|
          expect(row['ExportID']).to eq(@export.export_id)
        end
      end

      it 'returns correct CSV headers' do
        expected_headers = [
          'PersonalID', 'Woman', 'Man', 'NonBinary', 'CulturallySpecific', 'Transgender', 'Questioning', 'DifferentIdentity', 'GenderNone', 'DifferentIdentityText', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'
        ]
        expect(HmisCsvTwentyTwentySix::Exporter::Custom::CustomGender.hmis_csv_headers).to eq(expected_headers)
      end
    end

    describe 'without custom file types selected' do
      before(:all) do
        @exporter_no_custom = HmisCsvTwentyTwentySix::Exporter::Base.new(
          start_date: 1.week.ago.to_date,
          end_date: Date.current,
          projects: [ExportHelper2026.projects.first.id],
          period_type: 3,
          directive: 3,
          user_id: ExportHelper2026.user.id,
          custom_file_types: [],
        )
        @exporter_no_custom.export!(cleanup: false, zip: false, upload: false)
      end

      it 'does not include custom files in exportable_files' do
        expect(@exporter_no_custom.exportable_files.keys.map(&:name)).not_to include('HmisCsvTwentyTwentySix::Exporter::Custom::CustomGender')
      end

      it 'does not generate CustomGender.csv file' do
        custom_gender_file = File.join(@exporter_no_custom.file_path, 'CustomGender.csv')
        expect(File.exist?(custom_gender_file)).to be_falsy
      end
    end
  end
end
