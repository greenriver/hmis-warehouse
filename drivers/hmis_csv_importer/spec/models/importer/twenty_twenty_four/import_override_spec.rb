###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Applies overrides as expected', type: :model do
  describe 'without cleanup' do
    before(:all) do
      setup(with_overrides: false)
    end

    it 'Has 9 enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(9)
    end

    it 'Has 5 exits' do
      expect(GrdaWarehouse::Hud::Exit.count).to eq(5)
    end

    it 'Client does not have a DOB' do
      expect(GrdaWarehouse::Hud::Client.find_by(PersonalID: 'C-1').DOB).to be_nil
    end

    it 'Client does not have a DOB' do
      expect(GrdaWarehouse::Hud::Client.find_by(PersonalID: 'C-2').DOB).to be_nil
    end

    it 'Client has DOBDataQuality 99' do
      expect(GrdaWarehouse::Hud::Client.find_by(PersonalID: 'C-1').DOBDataQuality).to eq(99)
    end

    it 'Client has DOBDataQuality 99' do
      expect(GrdaWarehouse::Hud::Client.find_by(PersonalID: 'C-2').DOBDataQuality).to eq(99)
    end

    it 'Project has ProjectType 3' do
      expect(GrdaWarehouse::Hud::Project.find_by(ProjectID: 'PROJECT').ProjectType).to eq(3)
    end

    it 'Project has ProjectType 3' do
      expect(GrdaWarehouse::Hud::Project.pluck(:ProjectCommonName).uniq).to eq([nil])
    end

    it 'ProjectCoC have CoCCode KY-500' do
      expect(GrdaWarehouse::Hud::ProjectCoc.pluck(:CoCCode).uniq).to eq(['KY-500'])
    end

    it 'Funder have Funder 2' do
      expect(GrdaWarehouse::Hud::Funder.find_by(FunderID: 29).Funder).to eq('2')
      expect(GrdaWarehouse::Hud::Funder.pluck(:Funder).uniq.sort).to eq(['2', '9', '34'].sort)
    end
  end

  describe 'with cleanup' do
    before(:all) do
      setup(with_overrides: true)
    end

    it 'Has 9 enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(9)
    end

    it 'Has 5 exits' do
      expect(GrdaWarehouse::Hud::Exit.count).to eq(5)
    end

    it 'Client does not have a DOB' do
      expect(GrdaWarehouse::Hud::Client.find_by(PersonalID: 'C-1').DOB).to eq('2000-01-01'.to_date)
    end

    it 'Client has DOBDataQuality 1' do
      expect(GrdaWarehouse::Hud::Client.find_by(PersonalID: 'C-1').DOBDataQuality).to eq(1)
    end

    it 'Client still does not have a DOB' do
      expect(GrdaWarehouse::Hud::Client.find_by(PersonalID: 'C-2').DOB).to be_nil
    end

    it 'Client still has DOBDataQuality 99' do
      expect(GrdaWarehouse::Hud::Client.find_by(PersonalID: 'C-2').DOBDataQuality).to eq(99)
    end

    it 'Project has ProjectType 2' do
      expect(GrdaWarehouse::Hud::Project.find_by(ProjectID: 'PROJECT').ProjectType).to eq(2)
    end

    it 'Project has ProjectType 3' do
      names = GrdaWarehouse::Hud::Project.pluck(:ProjectCommonName)
      expect(names.uniq).to eq(['Project Common Name'])
      expect(names.count).to eq(5)
    end

    it 'ProjectCoC have CoCCode XX-500' do
      expect(GrdaWarehouse::Hud::ProjectCoc.pluck(:CoCCode).uniq).to eq(['XX-500'])
    end

    it 'Funder have Funder 4' do
      expect(GrdaWarehouse::Hud::Funder.find_by(FunderID: 29).Funder).to eq('4')
      expect(GrdaWarehouse::Hud::Funder.pluck(:Funder).uniq.sort).to eq(['2', '4', '9', '34'].sort)
    end

    it 'Applies? and apply method works even with an instance' do
      funder = GrdaWarehouse::Hud::Funder.find_by(FunderID: 29)
      # reset funder record since the previous run update the db as part of the import process
      funder.update(Funder: '2')
      override = HmisCsvImporter::ImportOverride.find_by(file_name: 'Funder.csv', matched_hud_key: '29')
      expect(override.applies?(funder)).to eq(true)
      expect(override.applies?(funder.attributes)).to eq(true)
      # Change applied even though we passed an active-record based object
      expect(override.apply(funder).Funder).to eq('4')

      funder = GrdaWarehouse::Hud::Funder.find_by(FunderID: 29)
      override = HmisCsvImporter::ImportOverride.find_by(file_name: 'Project.csv', matched_hud_key: 'PROJECT')
      expect(override.applies?(funder)).to eq(false)
      expect(override.applies?(funder.attributes)).to eq(false)
      # No change
      expect(override.apply(funder).Funder).to eq('2')
    end
  end

  def setup(with_overrides:)
    GrdaWarehouse::Utility.clear!
    HmisCsvImporter::Utility.clear!

    @data_source = create(:importer_dont_cleanup_ds)
    if with_overrides
      # Blanket replace
      create(:import_override, data_source: @data_source, file_name: 'Client.csv', matched_hud_key: 'C-1', replaces_column: 'DOB', replacement_value: '2000-01-01')
      create(:import_override, data_source: @data_source, file_name: 'Client.csv', matched_hud_key: 'C-1', replaces_column: 'DOBDataQuality', replacement_value: '1')

      # Specific replace (fails)
      create(:import_override, data_source: @data_source, file_name: 'Client.csv', matched_hud_key: 'C-2', replaces_column: 'DOB', replaces_value: '5', replacement_value: '2000-01-01')
      create(:import_override, data_source: @data_source, file_name: 'Client.csv', matched_hud_key: 'C-2', replaces_column: 'DOBDataQuality', replaces_value: '5', replacement_value: '1')

      # Specific replacement by hud_key
      create(:import_override, data_source: @data_source, file_name: 'Project.csv', matched_hud_key: 'PROJECT', replaces_column: 'ProjectType', replacement_value: '2')

      # blanket replacement
      create(:import_override, data_source: @data_source, file_name: 'Project.csv', replaces_column: 'ProjectCommonName', replacement_value: 'Project Common Name')

      # Specific replacement by value
      create(:import_override, data_source: @data_source, file_name: 'ProjectCoC.csv', replaces_value: 'KY-500', replaces_column: 'CoCCode', replacement_value: 'XX-500')

      # Single Funder replacement
      create(:import_override, data_source: @data_source, file_name: 'Funder.csv', matched_hud_key: '29', replaces_column: 'Funder', replacement_value: '4')

      # Changed to PH, for checking move-in date translator
      create(:import_override, data_source: @data_source, file_name: 'Project.csv', matched_hud_key: '506', replaces_column: 'ProjectType', replacement_value: '3')
    end
    import_hmis_csv_fixture(
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/import_overrides_test_files',
      data_source: @data_source,
      version: 'AutoMigrate',
      run_jobs: false,
    )
  end
end
