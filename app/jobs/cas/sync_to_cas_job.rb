module Cas
  class SyncToCasJob < ActiveJob::Base
  
    def perform
      GrdaWarehouse::Tasks::PushClientsToCas.new.sync!
    end

    def enqueue(job, queue: :default_priority)
    end
  end
end