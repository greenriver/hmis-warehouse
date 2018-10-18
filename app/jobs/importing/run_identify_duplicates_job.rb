module Importing
  class RunIdentifyDuplicatesJob < BaseJob
    queue_as :low_priority

    def perform
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    end
  end
end