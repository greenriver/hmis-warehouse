###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks
  class ProcessLocationData
    def run!
      # If this is already running, don't run again
      GrdaWarehouse::Place.with_advisory_lock('process_location__data', timeout_seconds: 0) do
        Rails.application.config.location_processors.each do |processor|
          processor.constantize.new.run!
        end
      end
    end
  end
end
