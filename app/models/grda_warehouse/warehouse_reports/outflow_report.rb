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

    # Clients with an open enrollment in the reporting period and service between the LOOKBACK date
    # and the start date, but no service in the reporting period.
    def clients_without_recent_service
      @clients_without_recent_service ||= begin
        open_enrollments_no_service = entries_scope.
          bed_night.
          merge(GrdaWarehouse::Hud::Project.es).
          where.not(id:  entries_scope.
            bed_night.
            with_service_between(start_date: @filter.start, end_date: @filter.end).select(:id))

        most_recent_service = service_history_service_source.
          where(service_history_enrollment_id: open_enrollments_no_service.select(:id)).
          where(date: (LOOKBACK_DATE..@filter.start)).
          group(:service_history_enrollment_id).
          maximum(:date)

        open_enrollments_no_service.pluck(:id, :client_id).select do |enrollment_id, client_id|
          most_recent_service[enrollment_id].present?
        end.map(&:last).uniq
      end
    end

    def client_outflow
      @client_outflow ||= (clients_to_ph + clients_to_stabilization + clients_without_recent_service).uniq
    end

    def entries_scope
      GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        open_between(start_date: @filter.start, end_date: @filter.end).
        send(@filter.sub_population).
        joins(:project)
    end

    def exits_scope
      GrdaWarehouse::ServiceHistoryEnrollment.
        exit_within_date_range(start_date: @filter.start, end_date: @filter.end).
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