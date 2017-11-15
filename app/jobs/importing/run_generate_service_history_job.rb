module Importing
  class RunGenerateServiceHistoryJob < ActiveJob::Base
    queue_as :low_priority

    def perform
      GrdaWarehouse::Tasks::ServiceHistory::UpdateAddPatch.new.run!
    end
  end
end