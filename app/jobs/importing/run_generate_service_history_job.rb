module Importing
  class RunGenerateServiceHistoryJob < BaseJob
    queue_as :low_priority

    def perform
      GrdaWarehouse::Tasks::ServiceHistory::UpdateAddPatch.new.run!
    end
  end
end