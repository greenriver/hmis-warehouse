###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::HmisCsvCleanup
  class Base
    def initialize(importer_log:, date_range:)
      @importer_log = importer_log
      @date_range = date_range
    end

    def cleanup!
      raise 'cleanup! must be implemented'
    end

    def self.description
      name.split('::').last.underscore.humanize
    end

    def self.checked?(data_source)
      # FIXME: This assumes an enable contains a single element
      enabled_key = enable[:import_cleanups].keys.first
      data_source[:import_cleanups][enabled_key.to_s]&.include?(enable[:import_cleanups][enabled_key].first) || false
    end
  end
end
