###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HMIS CSV Twenty Twenty Six Importer Version Dispatch' do
  let(:data_source) { create(:source_data_source) }

  describe 'version detection and importer selection' do
    it 'routes FY2026 files to the correct importer and loader classes' do
      # Test version-to-importer mapping
      expect(HmisCsvImporter::Loader::Loader.importer_class_for_version('2026')).to eq(HmisCsvTwentyTwentySix::Importer::Importer)
      expect(HmisCsvImporter::Loader::Loader.importer_class_for_version('2024')).to eq(HmisCsvImporter::Importer::Importer)
      expect(HmisCsvImporter::Loader::Loader.importer_class_for_version('2022')).to eq(HmisCsvImporter::Importer::Importer)

      # Test version-to-loader mapping
      expect(HmisCsvImporter::Loader::Loader.loader_class_for_version('2026')).to eq(HmisCsvTwentyTwentySix::Loader::Loader)
      expect(HmisCsvImporter::Loader::Loader.loader_class_for_version('2024')).to eq(HmisCsvImporter::Loader::Loader)
      expect(HmisCsvImporter::Loader::Loader.loader_class_for_version('2022')).to eq(HmisCsvImporter::Loader::Loader)
    end

    it 'detects FY2026 version from CSV files' do
      # Create a temporary directory with a FY2026 Export.csv
      Dir.mktmpdir do |temp_dir|
        export_csv_content = <<~CSV
          ExportID,SourceID,SourceName,SourceContactFirst,SourceContactLast,SourceContactPhone,SourceContactExtension,SourceContactEmail,ExportDate,ExportStartDate,ExportEndDate,SoftwareName,SoftwareVersion,CSVVersion,ExportPeriodType,ExportDirective,HashStatus
          export123,source123,Test Source,John,Doe,555-1234,,test@example.com,2023-01-01,2023-01-01,2023-12-31,TestSoft,1.0,2026,1,1,1
        CSV

        File.write(File.join(temp_dir, 'Export.csv'), export_csv_content)

        # Test version detection
        detected_version = Importers::HmisAutoMigrate.calculate_current_version(temp_dir)
        expect(detected_version).to eq('2026')

        # Test auto-migrate uses correct loader and importer
        detected_loader_class = HmisCsvImporter::Loader::Loader.loader_class_for_version(detected_version)
        expect(detected_loader_class).to eq(HmisCsvTwentyTwentySix::Loader::Loader)

        detected_importer_class = HmisCsvImporter::Loader::Loader.importer_class_for_version(detected_version)
        expect(detected_importer_class).to eq(HmisCsvTwentyTwentySix::Importer::Importer)
      end
    end
  end
end
