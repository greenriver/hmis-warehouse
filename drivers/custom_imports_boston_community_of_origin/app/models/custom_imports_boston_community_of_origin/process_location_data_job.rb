###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CustomImportsBostonCommunityOfOrigin
  class ProcessLocationDataJob
    def run!
      ImportFile.process_locations
    end
  end
end
