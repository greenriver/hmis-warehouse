module Importing
  class RunAddServiceHistoryJob < ActiveJob::Base
  
    def perform
      GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!
    end
  end
end