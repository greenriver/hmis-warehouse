module Importing
  class RunAddServiceHistoryJob < ActiveJob::Base

    def perform
      GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!
    end

    def enqueue(job, queue: :low_priority)
    end
  end
end