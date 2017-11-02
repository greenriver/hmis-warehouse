module Importing
  class RunIdentifyDuplicatesJob < ActiveJob::Base
  
    def perform
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    end

    def enqueue(job, queue: :default_priority)
    end
  end
end