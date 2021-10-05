###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisCsvImporter, type: :model do
  include HmisCsvImporter::HmisCsv

  describe 'When importing data with duplicate primary keys' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
      import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty/duplicate_primary_keys',
        version: 'AutoMigrate',
        run_jobs: false,
      )
    end

    it 'the loader tables contain appropriate numbers of rows matching the CSVs' do
      aggregate_failures do
        expect(loadable_file_class('Assessment').count).to eq(3)
        expect(loadable_file_class('Client').count).to eq(5)
        expect(loadable_file_class('Enrollment').count).to eq(5)
        expect(loadable_file_class('Funder').count).to eq(3)
      end
    end

    it 'the importer tables contain appropriate numbers of rows matching the CSVs' do
      aggregate_failures do
        expect(importable_file_class('Assessment').count).to eq(3)
        expect(importable_file_class('Client').count).to eq(5)
        expect(importable_file_class('Enrollment').count).to eq(5)
        expect(importable_file_class('Funder').count).to eq(3)
      end
    end

    it 'the importer tables contain appropriate numbers of rows matching the CSVs which are ready to import' do
      aggregate_failures do
        expect(importable_file_class('Assessment').should_import.count).to eq(2)
        expect(importable_file_class('Client').should_import.count).to eq(3)
        expect(importable_file_class('Enrollment').should_import.count).to eq(4)
        expect(importable_file_class('Funder').should_import.count).to eq(1)
      end
    end

    it 'the warehouse tables contain appropriate numbers of rows' do
      aggregate_failures do
        expect(GrdaWarehouse::Hud::Assessment.count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.source.count).to eq(3)
        expect(GrdaWarehouse::Hud::Enrollment.count).to eq(4)
        expect(GrdaWarehouse::Hud::Funder.count).to eq(1)
      end
    end

    it 'Appropriate error rows are generated' do
      expect(HmisCsvImporter::HmisCsvValidation::UniqueHudKey.count).to eq(6)
    end
  end

  def loadable_file_class(name)
    HmisCsvImporter::Loader::Loader.loadable_file_class(name)
  end

  def importable_file_class(name)
    HmisCsvImporter::Importer::Importer.importable_file_class(name)
  end
end
