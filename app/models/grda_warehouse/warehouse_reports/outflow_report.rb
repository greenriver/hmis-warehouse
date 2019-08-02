###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::WarehouseReports
  class OutflowReport
    include ArelHelper

    def initialize(filter, user)
      @filter = filter
      @user = user
    end

    def clients_to_ph
      @clients_to_ph ||= exits_scope.
        where(destination: HUD.permanent_destinations).
        distinct.
        pluck(:client_id)
    end

    def psh_clients_to_stabilization
      @psh_clients_to_stabilization ||= housed_scope.
        psh.entering_stabilization(start_date: @filter.start, end_date: @filter.end).
        distinct.
        pluck(:client_id)
    end

    def rrh_clients_to_stabilization
      @rrh_clients_to_stabilization ||= housed_scope.
        rrh.entering_stabilization(start_date: @filter.start, end_date: @filter.end).
        distinct.
        pluck(:client_id)
    end

    def clients_to_stabilization
      @clients_to_stabilization ||= (psh_clients_to_stabilization + rrh_clients_to_stabilization).uniq
    end

    # Clients with an open enrollment and service within the reporting period,
    # but no service after the cutoff date.
    def clients_without_recent_service
      @clients_without_recent_service ||= begin
        without_recent_service = entries_scope.
          homeless.
          with_service_between(start_date: @filter.start, end_date: @filter.end, service_scope: :homeless).
          where.not(client_id:  entries_scope.
            homeless.
            with_service_between(start_date: @filter.no_service_after_date, end_date: Date.today, service_scope: :homeless).
            select(:client_id)
          ).
          distinct.
          pluck(:client_id)
        if @filter.no_recent_service_project_ids.any?
          without_recent_service += entries_scope.in_project(@filter.no_recent_service_project_ids).
            with_service_between(start_date: @filter.start, end_date: @filter.end, service_scope: :homeless).
            where.not(client_id:  entries_scope.
              in_project(@filter.no_recent_service_project_ids).
              with_service_between(start_date: @filter.no_service_after_date, end_date: Date.today, service_scope: :homeless).
              select(:client_id)
            ).
            distinct.
            pluck(:client_id)
        end
        without_recent_service
      end
      return @clients_without_recent_service.uniq
    end

    def client_outflow
      @client_outflow ||= (clients_to_ph + clients_to_stabilization + clients_without_recent_service).uniq
    end

    def entries_scope
      service_history_enrollment_scope.
        entry.
        open_between(start_date: @filter.start, end_date: @filter.end)
    end

    def exits_scope
      service_history_enrollment_scope.
        homeless.
        exit_within_date_range(start_date: @filter.start, end_date: @filter.end)
    end

    def housed_scope
      Reporting::Housed.
      where(client_id: entries_scope.pluck(:client_id)).
      viewable_by(@user)
    end

    def service_history_enrollment_scope
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        send(@filter.sub_population).
        joins(:project).
        joins(:organization).
        merge(GrdaWarehouse::Hud::Project.viewable_by(@user))

      scope = scope.where(p_t[:id].in @filter.project_ids) unless @filter.project_ids.empty?
      scope = scope.where(o_t[:id].in @filter.organization_ids) unless @filter.organization_ids.empty?

      return scope
    end

    def service_history_service_source
      GrdaWarehouse::ServiceHistoryService
    end
  end
end