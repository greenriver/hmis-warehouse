###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Custom Files Integration' do
  after(:all) do
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
  end

  before(:all) do
    data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :s3)
    temp_dir = Dir.mktmpdir
    FileUtils.cp_r('drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/custom_files/.', temp_dir)

    # Run import process
    import_hmis_csv_fixture(
      temp_dir,
      version: '2026',
      data_source: data_source,
      run_jobs: true,
    )
    FileUtils.rm_rf(temp_dir)
  end

  describe 'CustomGender.csv processing' do
    it 'directly maps gender columns to client record' do
      # Verify clients were updated based on fixture data
      client1 = GrdaWarehouse::Hud::Client.find_by(PersonalID: '2f4b963171644a8b9902bdfe79a4b403')
      expect(client1.GenderNone).to eq(8)

      client2 = GrdaWarehouse::Hud::Client.find_by(PersonalID: '4c9da990d51b4ed1a2e45b972aeaecee')
      expect(client2.Woman).to eq(1)

      client3 = GrdaWarehouse::Hud::Client.find_by(PersonalID: '7b8c1279001142afac2fd0bde7a8f6bf')
      expect(client3.NonBinary).to eq(1)
    end
  end

  describe 'CustomSexualOrientation.csv processing' do
    it 'directly maps sexual_orientation columns to enrollment record' do
      # Verify enrollments were updated based on fixture data
      enrollment1 = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: '557331')
      expect(enrollment1.SexualOrientation).to eq(1) # Straight

      enrollment2 = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: '557890')
      expect(enrollment2.SexualOrientation).to eq(2) # Gay

      enrollment3 = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: '559123')
      expect(enrollment3.SexualOrientation).to eq(3) # Lesbian

      # Enrollment 3 should not be updated, it falls completely outside of the
      # import date range
      enrollment4 = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: '622377')
      expect(enrollment4.SexualOrientation).to eq(nil)
    end
  end

  describe 'CustomDataElementDefinition.csv processing' do
    it 'creates custom data element definition records' do
      custom_data_element_definition = GrdaWarehouse::Hud::CustomDataElementDefinition.find_by(key: 'reason_for_exit')
      expect(custom_data_element_definition.owner_type).to eq('GrdaWarehouse::Hud::Enrollment')
      expect(custom_data_element_definition.field_type).to eq('string')
    end
  end

  describe 'CustomDataElement.csv processing' do
    it 'creates custom data element records' do
      custom_data_element = GrdaWarehouse::Hud::CustomDataElement.find_by(CustomDataElementID: 'A1001')
      expect(custom_data_element.owner_type).to eq('GrdaWarehouse::Hud::Enrollment')
      expect(custom_data_element.value_string).to eq('No longer interested in participating in program')
      expect(custom_data_element.CustomDataElementDefinitionID).to eq('reason_for_exit')
    end
  end
end
