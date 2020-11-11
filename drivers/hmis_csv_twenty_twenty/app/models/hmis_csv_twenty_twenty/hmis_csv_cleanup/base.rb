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
  end
end
