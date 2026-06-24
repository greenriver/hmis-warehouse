###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CustomImportsBostonCommunityOfOrigin
  class ProcessLocationDataJob
    def run!
      ImportFile.process_locations
    end
  end
end
