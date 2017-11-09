module GrdaWarehouse::Tasks
  class HudChronicallyHomeless

    attr_accessor :date, :client_ids

    BATCH = 25

    def initialize date: Date.today, client_ids: []
      @date = date
      @client_ids = client_ids
    end

    # Break up the list of clients into groups of BATCH
    # and run calculations in background jobs.
    def run!
      GrdaWarehouse::HudChronic.where(date: date).delete_all
      client_ids.in_groups_of( BATCH ).each do |ids|
        Reporting::RunHudChronicJob.perform_later(ids, date.to_s)
      end
    end

    def client_ids
      return @client_ids.sort if @client_ids&.any?
      GrdaWarehouse::ServiceHistory.hud_currently_homeless(date: @date).distinct.pluck(:client_id).sort
    end
    
  end
end