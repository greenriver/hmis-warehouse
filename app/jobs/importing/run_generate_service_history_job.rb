module Importing
  class RunGenerateServiceHistoryJob < ActiveJob::Base
  
    def perform
      GrdaWarehouse::Tasks::ServiceHistory::UpdateAddPatch.new.run!
    end
  end
end