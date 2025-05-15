###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Assumptions:
# The import is authoritative for the date range specified in the Export.csv file
# The import is authoritative for the projects specified in the Project.csv file
# There's no reason to have client records with no enrollments
# All tables that hang off a client also hang off enrollments

# reload!; importer = HmisCsvImporter::Importer::Importer.new(loader_id: 2, data_source_id: 14, debug: true); importer.import!

# Some notes on how to manually run imports where the delayed job expires or fails for non-data related issue
# il = GrdaWarehouse::ImportLog.last
# loader = HmisCsvImporter::Loader::LoaderLog.last
# imp_log = HmisCsvImporter::Importer::ImporterLog.last
# # NOTE: newing up an importer currently creates an ImporterLog, this should be deleted
# imp = HmisCsvImporter::Importer::Importer.new(loader_id: loader.id, data_source_id: loader.data_source_id)
# imp.importer_log = imp_log
# il.update(import_errors: nil)
# # at this point, you can call any of the various import methods, usually, the last one that was attempted
# imp.log_timing(:process_existing)

require 'memery'
require 'zlib'
require 'base64'

module HmisCsvTwentyTwentySix::Importer
  class Importer < HmisCsvImporter::Importer::Importer
    def initialize(
      loader_id:,
      data_source_id:,
      debug: true,
      deidentified: false,
      project_cleanup: true
    )
      TodoOrDie('Remove this class', by: '2025-10-01')
      setup_notifier('HMIS Local FY2026 Importer')
      @loader_log = HmisCsvImporter::Loader::LoaderLog.find(loader_id.to_i)
      @data_source = GrdaWarehouse::DataSource.find(data_source_id.to_i)
      @debug = debug # no longer used for anything. instead we use logger.levels.
      @updated_source_client_ids = []

      @deidentified = deidentified
      @project_cleanup = project_cleanup
      self.importer_log = setup_import
      importable_files.each_key do |file_name|
        setup_summary(file_name)
      end
      log('De-identifying clients') if @deidentified
      log('Limiting to pre-approved projects') if @project_whitelist
    end

    private def loader_class
      HmisCsvTwentyTwentySix::Loader::Loader
    end

    private def importer_class
      HmisCsvTwentyTwentySix::Importer::Importer
    end

    def self.data_lake_module
      'HmisCsvTwentyTwentySix'
    end
  end
end
