###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::WarehouseReports
  class OutflowReport
    LOOKBACK_DATE = Date.parse('2018-10-01')

    def initialize(filter)
      @filter = filter
    end

    def clients_to_ph
      @clients_to_ph ||= exits_scope.
        where(destination: HUD.permanent_destinations).
        pluck(:client_id).
        uniq
    end

    def psh_clients_to_stabilization
      @psh_clients_to_stabilization ||= housed_scope.
        psh.entering_stabilization(start_date: @filter.start, end_date: @filter.end).
        pluck(:client_id).
        uniq
    end

    def rrh_clients_to_stabilization
      @rrh_clients_to_stabilization ||= housed_scope.
        rrh.entering_stabilization(start_date: @filter.start, end_date: @filter.end).
        pluck(:client_id).
        uniq
    end

    def clients_to_stabilization
      @clients_to_stabilization ||= (psh_clients_to_stabilization + rrh_clients_to_stabilization).uniq
    end

    def clients_without_recent_service
      @clients_without_recent_service ||= begin
        open_enrollments = entries_scope.
          bed_night
        service_in_period = entries_scope.
          bed_night.
          with_service_between(start_date: @filter.start, end_date: @filter.end)
        open_enrollments_no_service = open_enrollments - service_in_period

        most_recent_service = service_history_service_source.
          where(service_history_enrollment_id: open_enrollments_no_service.map(&:id)).
          where(date: (LOOKBACK_DATE..@filter.end)).
          group(:service_history_enrollment_id).
          maximum(:date)

        open_enrollments_no_service.select do |enrollment|
          most_recent_service[enrollment.id].present?
        end.map(&:id)
      end
    end

    def client_outflow
      @client_outflow ||= (clients_to_ph + clients_to_stabilization + clients_without_recent_service).uniq
    end

    def entries_scope
      GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        open_between(start_date: @filter.start, end_date: @filter.end).
        send(@filter.sub_population)
    end

    def exits_scope
      GrdaWarehouse::ServiceHistoryEnrollment.
        exit.
        open_between(start_date: @filter.start, end_date: @filter.end).
        send(@filter.sub_population)
    end

    def housed_scope
      Reporting::Housed.where(client_id: entries_scope.pluck(:client_id))
    end

    def service_history_service_source
      GrdaWarehouse::ServiceHistoryService
    end
  end
end