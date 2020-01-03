###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Cas
  class SyncToCasJob < BaseJob
    def perform
      GrdaWarehouse::Tasks::PushClientsToCas.new.sync!
    end
  end
end
