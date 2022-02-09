###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks
  class HudChronicallyHomeless

    attr_accessor :date, :client_ids

    def initialize date: Date.current, client_ids: [], batch_size: 200
      @date = date
      @client_ids = client_ids
      @batch_size = batch_size
    end

    # Break up the list of clients into groups of BATCH
    # and run calculations in background jobs.
    def run!
      GrdaWarehouse::HudChronic.where(date: date).delete_all
      client_ids.each_slice( @batch_size ).each do |ids|
        Reporting::RunHudChronicJob.perform_later(ids, date.to_s)
      end
    end

    def client_ids
      return @client_ids.sort if @client_ids&.any?
      GrdaWarehouse::ServiceHistoryEnrollment.
        hud_currently_homeless(date: @date, chronic_types_only: true).
        distinct.
        pluck(:client_id).
        sort
    end

  end
end
