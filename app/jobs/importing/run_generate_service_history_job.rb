###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Importing
  class RunGenerateServiceHistoryJob < BaseJob
    queue_as :long_running

    def perform
      GrdaWarehouse::Tasks::ServiceHistory::UpdateAddPatch.new.run!
    end
  end
end
