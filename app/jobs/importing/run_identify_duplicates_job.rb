module Importing
  class RunIdentifyDuplicatesJob < ActiveJob::Base
    queue_as :low_priority

    def perform
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    end
  end
end