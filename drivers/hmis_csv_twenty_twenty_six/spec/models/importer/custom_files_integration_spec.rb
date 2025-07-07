###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Custom Files Integration' do
  let(:data_source) { create(:data_source) }
  let(:project) { create(:project, data_source: data_source) }
  let(:client) { create(:client, data_source: data_source, PersonalID: '2f4b963171644a8b9902bdfe79a4b403') }
  let(:enrollment) { create(:enrollment, data_source: data_source, client: client, project: project, EnrollmentID: '622377') }

  before do
    # Clear any cached config to ensure we're reading fresh YAML files
    HmisCsvTwentyTwentySix.instance_variable_set(:@custom_files_config, nil)

    HmisCsvTwentyTwentySix::CustomFileManager.generate_custom_models!
  end

  describe 'CustomGender.csv processing' do
    it 'directly maps gender columns to client record' do
      temp_dir = Dir.mktmpdir
      csv_content = File.read('drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/custom_files/source/CustomGender.csv')
      File.write(File.join(temp_dir, 'CustomGender.csv'), csv_content)

      # Run import process
      loader = HmisCsvImporter::Loader::Loader.new(
        file_path: temp_dir,
        data_source_id: data_source.id,
      )
      loader.load!

      importer = HmisCsvTwentyTwentySix::Importer::Importer.new(
        loader_id: loader.id,
        data_source_id: data_source.id,
      )
      importer.import!

      # Verify client was updated based on fixture data
      client.reload
      expect(client.Woman).to eq(1) # From updated fixture
      expect(client.Man).to eq(0)
      expect(client.NonBinary).to eq(1) # From updated fixture
      expect(client.GenderNone).to eq(8) # From updated fixture

      FileUtils.rm_rf(temp_dir)
    end
  end

  describe 'CustomDataElement.csv processing' do
    it 'creates custom data element records' do
      temp_dir = Dir.mktmpdir

      # Copy both definition and data files
      def_content = File.read('drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/custom_files/source/CustomDataElementDefinition.csv')
      data_content = File.read('drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/custom_files/source/CustomDataElement.csv')

      File.write(File.join(temp_dir, 'CustomDataElementDefinition.csv'), def_content)
      File.write(File.join(temp_dir, 'CustomDataElement.csv'), data_content)

      # Run import process
      loader = HmisCsvImporter::Loader::Loader.new(
        file_path: temp_dir,
        data_source_id: data_source.id,
      )
      loader.load!

      importer = HmisCsvTwentyTwentySix::Importer::Importer.new(
        loader_id: loader.id,
        data_source_id: data_source.id,
      )
      importer.import!

      # Verify custom data element was created
      custom_element = GrdaWarehouse::Hud::CustomDataElement.find_by(
        data_source_id: data_source.id,
        CustomDataElementID: 'A1001',
      )

      expect(custom_element).to be_present
      expect(custom_element.CustomDataElementDefinitionID).to eq('reason_for_exit')
      expect(custom_element.RecordType).to eq('Enrollment')
      expect(custom_element.RecordID).to eq('622377')
      expect(custom_element.Value).to eq('No longer interested in participating in program')

      FileUtils.rm_rf(temp_dir)
    end
  end
end
