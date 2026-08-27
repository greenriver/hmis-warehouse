###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::HmisCsv do
  # Test design: Tier 1 -- these two files back the tables the HMIS app itself
  # owns for an HMIS-backed data source (see GrdaWarehouse::DataSource#hmis?).
  # If the pipeline stops excluding them here, the importer's "guilty until
  # proven innocent" deletion pass would purge HMIS-app-owned rows on the next
  # CSV import. Real Loader/Importer instances (not stubs) prove the exclusion
  # holds for both classes, and the vendor case proves normal imports still see
  # every file -- so a guard that accidentally excludes everyone, or excludes
  # no one, turns both halves of each pair red.
  let(:hmis_data_source) { create(:hmis_primary_data_source) }
  let(:vendor_data_source) { create(:grda_warehouse_data_source) }

  describe HmisCsvImporter::Importer::Importer do
    def importable_files_for(data_source)
      loader_log = HmisCsvImporter::Loader::LoaderLog.create!(data_source_id: data_source.id, status: :loaded, version: '2026')
      described_class.new(loader_id: loader_log.id, data_source_id: data_source.id).importable_files
    end

    it 'excludes CustomDataElement files for an HMIS-backed data source' do
      files = importable_files_for(hmis_data_source)

      expect(files.keys).not_to include('CustomDataElement.csv', 'CustomDataElementDefinition.csv')
    end

    it 'includes CustomDataElement files for a non-HMIS data source' do
      files = importable_files_for(vendor_data_source)

      expect(files.keys).to include('CustomDataElement.csv', 'CustomDataElementDefinition.csv')
    end
  end

  describe HmisCsvImporter::Loader::Loader do
    EXPORT_CSV_HEADER = 'ExportID,SourceType,SourceID,SourceName,SourceContactFirst,SourceContactLast,SourceContactPhone,SourceContactExtension,SourceContactEmail,ExportDate,ExportStartDate,ExportEndDate,SoftwareName,SoftwareVersion,CSVVersion,ExportPeriodType,ExportDirective,HashStatus,ImplementationID'
    EXPORT_CSV_ROW = 'export1,3,,Test Source,,,,,,2024-01-01 00:00:00,2024-01-01,2024-01-02,Test Software,1,2026 v1.0,3,3,1,Test Source'

    def loadable_files_for(data_source)
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'Export.csv'), "#{EXPORT_CSV_HEADER}\n#{EXPORT_CSV_ROW}\n")
        described_class.new(data_source_id: data_source.id, file_path: dir, remove_files: false).loadable_files
      end
    end

    it 'excludes CustomDataElement files for an HMIS-backed data source' do
      files = loadable_files_for(hmis_data_source)

      expect(files.keys).not_to include('CustomDataElement.csv', 'CustomDataElementDefinition.csv')
    end

    it 'includes CustomDataElement files for a non-HMIS data source' do
      files = loadable_files_for(vendor_data_source)

      expect(files.keys).to include('CustomDataElement.csv', 'CustomDataElementDefinition.csv')
    end
  end
end
