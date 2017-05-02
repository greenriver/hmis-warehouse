module Importing
  class RunIdentifyDuplicatesJob < ActiveJob::Base
  
    def perform
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    end
  end
end