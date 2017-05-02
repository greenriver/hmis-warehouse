module Importing
  class RunGenerateServiceHistoryJob < ActiveJob::Base
  
    def perform
      GrdaWarehouse::Tasks::GenerateServiceHistory.new.run!
    end
  end
end