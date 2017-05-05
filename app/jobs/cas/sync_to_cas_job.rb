module Cas
  class SyncToCasJob < ActiveJob::Base
  
    def perform
      GrdaWarehouse::Tasks::PushClientsToCas.new.sync!
    end
  end
end