module Importing
  class RunAddServiceHistoryJob < ActiveJob::Base
  
    def perform
      GrdaWarehouse::Tasks::AddServiceHistory.new.run!
    end
  end
end