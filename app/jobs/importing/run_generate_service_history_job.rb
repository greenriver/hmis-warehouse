module Importing
  class RunGenerateServiceHistoryJob < ActiveJob::Base
  
    def perform
      GrdaWarehouse::Tasks::ServiceHistory::UpdateAddPatch.new.run!
    end

    def enqueue(job, queue: :low_priority)
    end
  end
end