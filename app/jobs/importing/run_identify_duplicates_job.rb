###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Importing
  class RunIdentifyDuplicatesJob < BaseJob
    queue_as :long_running

    def perform
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    end
  end
end
