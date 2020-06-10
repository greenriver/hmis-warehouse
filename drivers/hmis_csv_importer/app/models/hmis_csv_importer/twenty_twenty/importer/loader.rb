###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# Assumptions:
# The import is authoritative for the date range specified in the Export.csv file
# The import is authoritative for the projects specified in the Project.csv file
# There's no reason to have client records with no enrollments
# All tables that hang off a client also hang off enrollments
module HmisCsvImporter::TwentyTwenty::Importer
  class Loader < HmisCsvImporter::Loader
    include TsqlImport
    include NotifierConfig
    include Shared

    attr_accessor :logger, :notifier_config, :import, :range

    def initialize(
      file_path: File.join('tmp', 'hmis_import'),
      data_source_id: ,
      logger: Rails.logger,
      debug: true,
      remove_files: true,
      deidentified: false,
      project_whitelist: false
    )
      setup_notifier('HMIS CSV Loader 2020')
      @data_source = GrdaWarehouse::DataSource.find(data_source_id.to_i)
      @file_path = file_path
      @logger = logger
      @debug = debug
      @soft_delete_time = Time.now.change(usec: 0) # Active Record milliseconds and Rails don't always agree, so zero those out so future comparisons work.
      @remove_files = remove_files
      @deidentified = deidentified
      @project_whitelist = project_whitelist
      setup_import(data_source: @data_source)
      log("De-identifying clients") if @deidentified
      log("Limiting to white-listed projects") if @project_whitelist
    end
  end
end