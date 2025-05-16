###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'zip'
require 'csv'
require 'charlock_holmes'

# Assumptions:
# The import is authoritative for the date range specified in the Export.csv file
# The import is authoritative for the projects specified in the Project.csv file
# There's no reason to have client records with no enrollments
# All tables that hang off a client also hang off enrollments

# reload!; HmisCsvImporter::Loader::Loader.new(data_source_id: 90, debug: true, remove_files: false).load!

# This is a copy of HmisCsvImporter::Loader::Loader for use during the transition to
# FY2026.  Once we're running auto-migrate with FY2026, this should be removed.
module HmisCsvTwentyTwentySix::Loader
  class Loader < HmisCsvImporter::Loader::Loader
    # Override some methods to force the use of the FY2026 importer and prevent auto-migration
    def self.data_lake_module
      'HmisCsvTwentyTwentySix'
    end

    private def importer_class
      TodoOrDie('Remove this class', by: '2025-10-01')
      HmisCsvTwentyTwentySix::Importer::Importer
    end

    private def load_source_files!
      @loader_log.update(status: :loading)

      HmisCsvImporter::Loader::ProjectFilter.filter(@file_path, @data_source.id, @post_processor) if @limit_projects

      loadable_files.each do |file_name, klass|
        source_file_path = File.join(@file_path, file_name)
        next unless File.file?(source_file_path)

        encoding = AutoEncodingCsv.detect_encoding(source_file_path)
        self.class.fix_bad_line_endings(source_file_path, encoding)
        File.open(source_file_path, 'r', encoding: encoding) do |file|
          load_source_file_pg(read_from: file, klass: klass, original_file_path: source_file_path)
        end
      end
    end
  end
end
