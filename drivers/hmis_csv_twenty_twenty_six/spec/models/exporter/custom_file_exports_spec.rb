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

      # Create some custom sexual orientation data for testing
      @enrollment = ExportHelper2026.projects.first.enrollments.first
      @enrollment.update(
        SexualOrientation: 1,
        SexualOrientationOther: nil,
      )

      # Get custom data element test data from ExportHelper2026
      @custom_data_element_definition = ExportHelper2026.custom_data_element_definitions.first
      @custom_data_element_definition.update(data_source_id: @client.data_source_id)
      @custom_data_element = ExportHelper2026.custom_data_elements.first
      @custom_data_element.update(
        data_source_id: @client.data_source_id,
        owner_id: @client.id,
        owner_type: @client.class.name,
        custom_data_element_definition_id: @custom_data_element_definition.CustomDataElementDefinitionID,
      )
    end

    it 'does not perform N+1 queries for CustomDataElement export' do
      # Build a dedicated exporter focusing only on CustomDataElement to isolate query counting
      exporter_cde_only = HmisCsvTwentyTwentySix::Exporter::Base.new(
        start_date: 3.weeks.ago.to_date,
        end_date: Date.current,
        projects: [ExportHelper2026.projects.first.id],
        period_type: 3,
        directive: 3,
        user_id: ExportHelper2026.user.id,
        custom_file_types: ['CustomDataElement.csv'],
      )

      count_definition_queries = lambda do |&blk|
        queries = 0
        subscriber = lambda do |_name, _start, _finish, _id, payload|
          sql = payload[:sql]
          return if payload[:name] == 'SCHEMA' || payload[:cached]

          queries += 1 if sql&.match?(/\b"?CustomDataElementDefinitions"?\b/i)
        end
        ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') do
          blk.call
        end
        queries
      end

      # Baseline: export with the original single CustomDataElement
      baseline_queries = count_definition_queries.call do
        exporter_cde_only.export!(cleanup: false, zip: false, upload: false)
      end
      baseline_file = File.join(exporter_cde_only.file_path, 'CustomDataElement.csv')
      baseline_rows = CSV.read(baseline_file, headers: true).length

      # Create additional CustomDataElements for the same owner/definition to simulate volume
      25.times do |i|
        new_el = @custom_data_element.dup
        new_el.value_string = "extra-#{i}"
        new_el.CustomDataElementID = nil
        new_el.save!
      end

      # Re-run export and ensure queries against CustomDataElementDefinitions do not scale with rows
      with_many_queries = count_definition_queries.call do
        exporter_cde_only.export!(cleanup: false, zip: false, upload: false)
      end
      with_many_file = File.join(exporter_cde_only.file_path, 'CustomDataElement.csv')
      with_many_rows = CSV.read(with_many_file, headers: true).length

      # We expect at most a small constant number of definition table queries regardless of row count
      expect(with_many_queries).to be <= (baseline_queries + 2)
      # Confirm row counts scale as expected
      puts "Baseline CustomDataElement.csv rows: #{baseline_rows}"
      puts "With-many CustomDataElement.csv rows: #{with_many_rows}"
      expect(with_many_rows).to eq(baseline_rows + 25)
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
          custom_file_types: ['CustomGender.csv', 'CustomSexualOrientation.csv', 'CustomDataElementDefinition.csv', 'CustomDataElement.csv'],
        )
        @export = @exporter.export!(cleanup: false, zip: false, upload: false)
      end

      it 'includes custom files in exportable_files' do
        expect(@exporter.exportable_files.keys.map(&:name)).to include('HmisCsvTwentyTwentySix::Exporter::Custom::CustomGender')
        expect(@exporter.exportable_files.keys.map(&:name)).to include('HmisCsvTwentyTwentySix::Exporter::Custom::CustomSexualOrientation')
        expect(@exporter.exportable_files.keys.map(&:name)).to include('HmisCsvTwentyTwentySix::Exporter::Custom::CustomDataElementDefinition')
        expect(@exporter.exportable_files.keys.map(&:name)).to include('HmisCsvTwentyTwentySix::Exporter::Custom::CustomDataElement')
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

      it 'generates CustomSexualOrientation.csv file' do
        custom_sexual_orientation_file = File.join(@exporter.file_path, 'CustomSexualOrientation.csv')
        expect(File.exist?(custom_sexual_orientation_file)).to be_truthy
      end

      it 'includes custom sexual orientation data in export' do
        custom_sexual_orientation_file = File.join(@exporter.file_path, 'CustomSexualOrientation.csv')
        csv_content = CSV.read(custom_sexual_orientation_file, headers: true)

        expect(csv_content.length).to be > 0
        # Check that our test data is included
        enrollment_row = csv_content.find { |row| row['EnrollmentID'] == @enrollment.id.to_s }
        expect(enrollment_row).to be_present
        expect(enrollment_row['SexualOrientation']).to eq('1')
        expect(enrollment_row['SexualOrientationOther']).to eq('')
      end

      it 'sets correct ExportID on custom sexual orientation records' do
        custom_sexual_orientation_file = File.join(@exporter.file_path, 'CustomSexualOrientation.csv')
        csv_content = CSV.read(custom_sexual_orientation_file, headers: true)

        csv_content.each do |row|
          expect(row['ExportID']).to eq(@export.export_id)
        end
      end

      it 'returns correct CSV headers for CustomSexualOrientation' do
        expected_headers = [
          'EnrollmentID', 'PersonalID', 'SexualOrientation', 'SexualOrientationOther', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'
        ]
        expect(HmisCsvTwentyTwentySix::Exporter::Custom::CustomSexualOrientation.hmis_csv_headers).to eq(expected_headers)
      end

      it 'generates CustomDataElementDefinition.csv file' do
        custom_data_element_definition_file = File.join(@exporter.file_path, 'CustomDataElementDefinition.csv')
        expect(File.exist?(custom_data_element_definition_file)).to be_truthy
      end

      it 'includes custom data element definition data in export' do
        custom_data_element_definition_file = File.join(@exporter.file_path, 'CustomDataElementDefinition.csv')
        csv_content = CSV.read(custom_data_element_definition_file, headers: true)

        expect(csv_content.length).to be > 0
        # Check that our test data is included (use database ID, not HUD key)
        definition_row = csv_content.find { |row| row['CustomDataElementDefinitionID'] == @custom_data_element_definition.id.to_s }
        expect(definition_row).to be_present
        expect(definition_row['Key']).to eq(@custom_data_element_definition.key)
        expect(definition_row['Label']).to eq(@custom_data_element_definition.label)
        expect(definition_row['RecordType']).to eq('Client')
        expect(definition_row['FieldType']).to eq('string')
        expect(definition_row['Repeats']).to eq('false')
      end

      it 'sets correct ExportID on custom data element definition records' do
        custom_data_element_definition_file = File.join(@exporter.file_path, 'CustomDataElementDefinition.csv')
        csv_content = CSV.read(custom_data_element_definition_file, headers: true)

        csv_content.each do |row|
          expect(row['ExportID']).to eq(@export.export_id)
        end
      end

      it 'returns correct CSV headers for CustomDataElementDefinition' do
        expected_headers = [
          'CustomDataElementDefinitionID', 'Key', 'RecordType', 'FieldType', 'Label', 'Repeats', 'DateCreated', 'DateUpdated', 'UserID', 'DateDeleted', 'ExportID'
        ]
        expect(HmisCsvTwentyTwentySix::Exporter::Custom::CustomDataElementDefinition.hmis_csv_headers).to eq(expected_headers)
      end

      it 'generates CustomDataElement.csv file' do
        custom_data_element_file = File.join(@exporter.file_path, 'CustomDataElement.csv')
        expect(File.exist?(custom_data_element_file)).to be_truthy
      end

      it 'includes custom data element data in export' do
        custom_data_element_file = File.join(@exporter.file_path, 'CustomDataElement.csv')
        csv_content = CSV.read(custom_data_element_file, headers: true)
        expect(csv_content.length).to be > 0
        # Check that our test data is included
        element_row = csv_content.find { |row| row['CustomDataElementID'] == @custom_data_element.id.to_s }
        expect(element_row).to be_present
        expect(element_row['CustomDataElementDefinitionID']).to eq(@custom_data_element_definition.id.to_s)
        expect(element_row['RecordType']).to eq('Client')
        expect(element_row['RecordID']).to eq(@custom_data_element.owner_id.to_s)
        expect(element_row['Value']).to eq(@custom_data_element.value_string)
      end

      it 'sets correct ExportID on custom data element records' do
        custom_data_element_file = File.join(@exporter.file_path, 'CustomDataElement.csv')
        csv_content = CSV.read(custom_data_element_file, headers: true)

        csv_content.each do |row|
          expect(row['ExportID']).to eq(@export.export_id)
        end
      end

      it 'returns correct CSV headers for CustomDataElement' do
        expected_headers = [
          'CustomDataElementID', 'CustomDataElementDefinitionID', 'RecordType', 'RecordID', 'Value', 'DataCollectionStage', 'InformationDate', 'UserID', 'DateCreated', 'DateUpdated', 'DateDeleted', 'ExportID'
        ]
        expect(HmisCsvTwentyTwentySix::Exporter::Custom::CustomDataElement.hmis_csv_headers).to eq(expected_headers)
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
        expect(@exporter_no_custom.exportable_files.keys.map(&:name)).not_to include('HmisCsvTwentyTwentySix::Exporter::Custom::CustomSexualOrientation')
        expect(@exporter_no_custom.exportable_files.keys.map(&:name)).not_to include('HmisCsvTwentyTwentySix::Exporter::Custom::CustomDataElementDefinition')
        expect(@exporter_no_custom.exportable_files.keys.map(&:name)).not_to include('HmisCsvTwentyTwentySix::Exporter::Custom::CustomDataElement')
      end

      it 'does not generate CustomGender.csv file' do
        custom_gender_file = File.join(@exporter_no_custom.file_path, 'CustomGender.csv')
        expect(File.exist?(custom_gender_file)).to be_falsy
      end

      it 'does not generate CustomSexualOrientation.csv file' do
        custom_sexual_orientation_file = File.join(@exporter_no_custom.file_path, 'CustomSexualOrientation.csv')
        expect(File.exist?(custom_sexual_orientation_file)).to be_falsy
      end

      it 'does not generate CustomDataElementDefinition.csv file' do
        custom_data_element_definition_file = File.join(@exporter_no_custom.file_path, 'CustomDataElementDefinition.csv')
        expect(File.exist?(custom_data_element_definition_file)).to be_falsy
      end

      it 'does not generate CustomDataElement.csv file' do
        custom_data_element_file = File.join(@exporter_no_custom.file_path, 'CustomDataElement.csv')
        expect(File.exist?(custom_data_element_file)).to be_falsy
      end
    end
  end
end
