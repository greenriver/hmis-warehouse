###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports
  class TimeHomelessForExit
    include ArelHelper
    attr_reader :filter

    def initialize(filter)
      @filter = filter
    end

    def clients_housed_scope
      GrdaWarehouse::Hud::Client.
        where(id: clients_with_permanent_exits.select(:id)).
        or(GrdaWarehouse::Hud::Client.where(id: clients_with_housed_enrollments.select(:id)))
    end

    def client_housed_dates
      @client_housed_dates ||= begin
        dates = {}
        # Find the first date exited to a permanent destination within the range
        clients_with_permanent_exits.order(ex_t[:ExitDate].asc).pluck(:id, ex_t[:ExitDate]).each do |client_id, date|
          dates[client_id] ||= date
        end
        # Layer on the first enrollment in PH if it is earlier
        clients_with_housed_enrollments.order(e_t[:MoveInDate].asc).pluck(:id, e_t[:MoveInDate]).each do |client_id, date|
          dates[client_id] = date if dates[client_id].blank? || date < dates[client_id]
        end
        dates
      end
    end

    def client_homeless_entry_dates
      @client_homeless_entry_dates ||= begin
        dates = {}
        # Find the latest entry into homelessness for the client occurring before the housed date
        homeless_entries.order(e_t[:EntryDate].desc).pluck(:id, e_t[:EntryDate]).each do |client_id, date|
          next if client_housed_dates[client_id] < date

          dates[client_id] ||= date
        end
      end
    end

    def homeless_entries
      GrdaWarehouse::Hud::Client.destination.joins(:source_enrollments).
        merge(GrdaWarehouse::Hud::Enrollment.homeless.where(e_t[:EntryDate].lt(filter.end))).
        where(id: clients_housed_scope.select(:id))
    end

    private def clients_with_permanent_exits
      GrdaWarehouse::Hud::Client.destination.joins(:source_enrollments).
        merge(GrdaWarehouse::Hud::Enrollment.with_permanent_exit(filter.range))
    end

    private def clients_with_housed_enrollments
      GrdaWarehouse::Hud::Client.destination.joins(:source_enrollments).
        merge(GrdaWarehouse::Hud::Enrollment.housed(filter.range))
    end
  end
end
