###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::HmisCsvCleanup
  class Base
    include HmisCsvImporter::HmisCsv

    attr_accessor :importer_log, :date_range

    def initialize(importer_log:, date_range:)
      @importer_log = importer_log
      @date_range = date_range
    end

    def cleanup!
      raise 'cleanup! must be implemented'
    end

    def importable_file_class(name)
      self.class.importable_file_class(name)
    end

    def self.description
      name.split('::').last.underscore.humanize
    end

    def self.associated_model
      # NOTE: This assumes an enable contains a single element
      enable[:import_cleanups].keys.first
    end

    def self.checked?(data_source)
      # NOTE: This assumes an enable contains a single element
      enabled_key = enable[:import_cleanups].keys.first
      data_source[:import_cleanups][enabled_key.to_s]&.include?(enable[:import_cleanups][enabled_key].first) || false
    end
  end
end
