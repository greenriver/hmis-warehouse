module Cas
  class SyncToCasJob < BaseJob

    def perform
      GrdaWarehouse::Tasks::PushClientsToCas.new.sync!
    end
  end
end