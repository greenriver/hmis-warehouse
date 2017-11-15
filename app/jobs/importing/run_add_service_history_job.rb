module Importing
  class RunAddServiceHistoryJob < ActiveJob::Base
    queue_as :low_priority

    def perform
      GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!
    end
  end
end