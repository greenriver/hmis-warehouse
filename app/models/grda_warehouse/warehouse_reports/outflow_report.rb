###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports
  class OutflowReport
    include ArelHelper
    include Filter::FilterScopes

    def initialize(filter, user)
      @filter = filter
      @user = user
    end

    def enrollments_for(key)
      entries_scope.
        residential.
        joins(:client).
        preload(:client, :project).
        order(c_t[:LastName], c_t[:FirstName]).
        where(client_id: send(key)).
        group_by(&:client_id)
    end

    def clients_to_ph
      @clients_to_ph ||= exits_scope.
        where(destination: HUD.permanent_destinations).
        distinct.
        pluck(:client_id)
    end

    private def neutral_destinations
      [2, 4, 5, 6, 12, 13, 14, 15, 18, 25, 27, 29]
    end

    private def jail_destinations
      [7]
    end

    private def deceased_destinations
      [24]
    end

    # NOTE: this does not match temporary destinations exactly
    def clients_to_neutral
      @clients_to_neutral ||= exits_scope.
        where(destination: neutral_destinations).
        distinct.
        pluck(:client_id)
    end

    def clients_to_jail
      @clients_to_jail ||= exits_scope.
        where(destination: 7).
        distinct.
        pluck(:client_id)
    end

    def clients_to_deceased
      @clients_to_deceased ||= exits_scope.
        where(destination: 24).
        distinct.
        pluck(:client_id)
    end

    def clients_to_permanent_or_neutral
      @clients_to_permanent_or_neutral ||= (exits_scope.
        where(destination: HUD.permanent_destinations + neutral_destinations).
        distinct.
        pluck(:client_id) + clients_to_stabilization).uniq
    end

    def clients_to_destinations
      @clients_to_destinations ||= (exits_scope.
        where(destination: HUD.permanent_destinations + neutral_destinations + jail_destinations + deceased_destinations).
        distinct.
        pluck(:client_id) + clients_to_stabilization).uniq
    end

    def hoh_to_ph
      @hoh_to_ph ||= exits_scope.
        heads_of_households.
        where(destination: HUD.permanent_destinations).
        distinct.
        pluck(:client_id)
    end

    def hoh_to_neutral
      @hoh_to_neutral ||= exits_scope.
        heads_of_households.
        where(destination: neutral_destinations).
        distinct.
        pluck(:client_id)
    end

    def hoh_to_jail
      @hoh_to_jail ||= exits_scope.
        heads_of_households.
        where(destination: 7).
        distinct.
        pluck(:client_id)
    end

    def hoh_to_deceased
      @hoh_to_deceased ||= exits_scope.
        heads_of_households.
        where(destination: 24).
        distinct.
        pluck(:client_id)
    end

    def hoh_to_permanent_or_neutral
      @hoh_to_permanent_or_neutral ||= (exits_scope.
        heads_of_households.
        where(destination: HUD.permanent_destinations + neutral_destinations).
        distinct.
        pluck(:client_id) + hoh_to_stabilization).uniq
    end

    def hoh_to_destinations
      @hoh_to_destinations ||= (exits_scope.
        heads_of_households.
        where(destination: HUD.permanent_destinations + neutral_destinations + jail_destinations + deceased_destinations).
        distinct.
        pluck(:client_id) + hoh_to_stabilization).uniq
    end

    def psh_clients_to_stabilization
      @psh_clients_to_stabilization ||= housed_scope.
        psh.entering_stabilization(start_date: @filter.start, end_date: @filter.end).
        distinct.
        pluck(:client_id)
    end

    def psh_hoh_to_stabilization
      @psh_hoh_to_stabilization ||= housed_scope.
        heads_of_households.
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

    def rrh_hoh_to_stabilization
      @rrh_hoh_to_stabilization ||= housed_scope.
        heads_of_households.
        rrh.entering_stabilization(start_date: @filter.start, end_date: @filter.end).
        distinct.
        pluck(:client_id)
    end

    def clients_to_stabilization
      @clients_to_stabilization ||= (psh_clients_to_stabilization + rrh_clients_to_stabilization).uniq
    end

    def hoh_to_stabilization
      @hoh_to_stabilization ||= (psh_hoh_to_stabilization + rrh_hoh_to_stabilization).uniq
    end

    # Clients with an open enrollment and service within the reporting period,
    # but no service after the cutoff date.
    def clients_without_recent_service
      @clients_without_recent_service ||= clients_without_recent_service_internal(entries_scope)
    end

    def hoh_without_recent_service
      @hoh_without_recent_service ||= clients_without_recent_service_internal(entries_scope.heads_of_households)
    end

    def outflow_to_housing
      chart_start_date = (@filter.end - 6.months).beginning_of_month
      chart_end_date = @filter.end.end_of_month
      months = (chart_start_date.to_date..chart_end_date.to_date).map { |m| m.strftime('%b %Y') }.uniq

      hoh_to_ph = exits_scope(start_date: chart_start_date, end_date: chart_end_date).
        heads_of_households.
        where(destination: HUD.permanent_destinations).
        distinct.
        select(:client_id, :last_date_in_program).
        index_by(&:client_id).values.
        group_by { |x| x.last_date_in_program.end_of_month }

      hoh_to_ph_count = {}
      months.each { |month| hoh_to_ph_count[month] = 0 }
      hoh_to_ph_count.merge!(hoh_to_ph.map { |k, v| [k.strftime('%b %Y'), v.size] }.to_h)

      hoh_to_stabilization = housed_scope.
        heads_of_households.
        where(project_type: [3, 9, 10, 13]). # PSH or RRH
        entering_stabilization(start_date: chart_start_date, end_date: chart_end_date).
        distinct.
        select(:client_id, :housed_date).
        index_by(&:client_id).values.
        group_by { |x| x.housed_date.end_of_month }

      hoh_to_stabilization_count = {}
      months.each { |month| hoh_to_stabilization_count[month] = 0 }
      hoh_to_stabilization_count.merge!(hoh_to_stabilization.map { |k, v| [k.strftime('%b %Y'), v.size] }.to_h)

      hoh_exits_to_ph = (hoh_to_ph.keys | hoh_to_stabilization.keys).map do |month|
        [month, (Array.wrap(hoh_to_ph[month]).compact + Array.wrap(hoh_to_stabilization[month]).compact).uniq(&:client_id)]
      end.to_h

      hoh_exits_to_ph_count = {}
      months.each { |month| hoh_exits_to_ph_count[month] = 0 }
      hoh_exits_to_ph_count.merge!(hoh_exits_to_ph.map { |k, v| [k.strftime('%b %Y'), v.size] }.to_h)

      {
        labels: [:x] + months,
        data: [
          [:x] + months,
          [metrics[:hoh_to_ph]] + hoh_to_ph_count.values,
          [metrics[:hoh_to_stabilization]] + hoh_to_stabilization_count.values,
          [metrics[:hoh_exits_to_ph]] + hoh_exits_to_ph_count.values,
        ],
      }
    end

    private def clients_without_recent_service_internal(scope)
      without_recent_service = scope.
        homeless.
        with_service_between(start_date: @filter.start, end_date: @filter.end, service_scope: :homeless).
        where.not(
          client_id: scope.homeless.
            with_service_between(start_date: @filter.no_service_after_date, end_date: Date.current, service_scope: :homeless).
            select(:client_id),
        ).
        distinct.
        pluck(:client_id)
      if @filter.no_recent_service_project_ids.any?
        # Remove anyone with service after the cut-off in any of the selected projects
        with_recent_service = scope.in_project(@filter.no_recent_service_project_ids).
          with_service_between(start_date: @filter.no_service_after_date, end_date: Date.current).
          distinct.
          pluck(:client_id)
        without_recent_service -= with_recent_service
      end
      without_recent_service.uniq
    end

    def exits_to_ph
      @exits_to_ph ||= (clients_to_ph + clients_to_stabilization).uniq
    end

    def hoh_exits_to_ph
      @hoh_exits_to_ph ||= (hoh_to_ph + hoh_to_stabilization).uniq
    end

    def client_outflow
      @client_outflow ||= (clients_to_ph + clients_to_stabilization + clients_without_recent_service).uniq
    end

    def hoh_outflow
      @hoh_outflow ||= (hoh_to_ph + hoh_to_stabilization + hoh_without_recent_service).uniq
    end

    def metrics
      {
        clients_to_ph: 'Clients exiting to Permanent Destinations',
        hoh_to_ph: 'Heads of Households exiting to Permanent Destinations',
        psh_clients_to_stabilization: "PSH Clients entering #{_('Housing')}",
        psh_hoh_to_stabilization: "PSH Heads of Households entering #{_('Housing')}",
        rrh_clients_to_stabilization: "RRH Clients entering #{_('Stabilization')}",
        rrh_hoh_to_stabilization: "RRH Heads of Households entering #{_('Stabilization')}",
        clients_to_stabilization: "All Clients entering #{_('Stabilization')}",
        hoh_to_stabilization: "All Heads of Households entering #{_('Stabilization')}",
        exits_to_ph: "Unique Clients exiting to Permanent Destinations or entering #{_('Stabilization')}",
        hoh_exits_to_ph: "Unique Heads of Households exiting to Permanent Destinations or entering #{_('Stabilization')}",
        clients_to_neutral: 'Unique Clients exiting to a neutral destination',
        hoh_to_neutral: 'Unique Heads of Households exiting to a neutral destination',
        clients_to_jail: 'Unique Clients exiting to Jail',
        hoh_to_jail: 'Unique Heads of Households exiting to Jail',
        clients_to_deceased: 'Deceased Clients',
        hoh_to_deceased: 'Deceased Heads of Households',
        clients_to_permanent_or_neutral: 'Unique Clients Entering Housing or exiting to Permanent, Neutral Destinations',
        hoh_to_permanent_or_neutral: 'Unique Heads of Households Entering Housing or exiting to Permanent, Neutral Destinations',
        clients_to_destinations: 'Unique Clients Entering Housing or exiting to Permanent, Neutral, Jail, or Deceased Destinations',
        hoh_to_destinations: 'Unique Heads of Households Entering Housing or exiting to Permanent, Neutral, Jail, or Deceased Destinations',
        clients_without_recent_service: 'Clients without recent service',
        hoh_without_recent_service: 'Heads of Households without recent service',
        client_outflow: 'Total Outflow',
        hoh_outflow: 'Total Outflow of Heads of Household',
      }
    end

    def entries_scope
      service_history_enrollment_scope.
        entry.
        open_between(start_date: @filter.start, end_date: @filter.end)
    end

    def exits_scope(start_date: @filter.start, end_date: @filter.end)
      service_history_enrollment_scope.
        homeless.
        exit_within_date_range(start_date: start_date, end_date: end_date)
    end

    def housed_scope
      housed = housed_source.
        where(client_id: entries_scope.residential.pluck(:client_id)).
        viewable_by(@user)
      housed = housed.send(@filter.sub_population) if @filter.sub_population.to_s.starts_with?('youth')

      housed
    end

    def housed_source
      Reporting::Housed
    end

    def service_history_enrollment_scope(start_date: @filter.start, end_date: @filter.end)
      sub_population = @filter.sub_population
      sub_population = :youth if sub_population.to_s.starts_with?('youth')

      scope = report_scope_source.
        send(sub_population).
        joins(:organization)

      scope = filter_for_user_access(scope)
      scope = filter_for_race(scope)
      scope = filter_for_gender(scope)
      scope = filter_for_ethnicity(scope)
      # NOTE: this is not exposed on the page, but is potentially called from the Performance Metrics report
      scope = filter_for_ca_homeless(scope)
      scope = filter_for_ce_cls_homeless(scope)
      scope = filter_for_head_of_household(scope)
      scope = filter_for_age(scope)
      scope = filter_for_veteran_status(scope)
      scope = filter_for_projects(scope)
      scope = filter_for_data_sources(scope)
      scope = filter_for_organizations(scope)
      # scope = filter_for_sub_population(scope) # note, non-standard, handled above

      scope = scope.where(client_id: hmis_vispdat_client_ids + warehouse_vispdat_client_ids) if @filter.limit_to_vispdats

      if @filter.require_homeless_enrollment
        homeless_clients = report_scope_source.
          entry.
          with_service_between(start_date: start_date, end_date: end_date).
          homeless.
          select(:client_id)
        scope = scope.where(client_id: homeless_clients)
      end

      scope
    end

    private def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    private def warehouse_vispdat_client_ids
      GrdaWarehouse::Hud::Client.destination.joins(:vispdats).merge(GrdaWarehouse::Vispdat::Base.completed).distinct.pluck(:id)
    end

    private def hmis_vispdat_client_ids
      GrdaWarehouse::Hud::Client.destination.
        joins(:source_hmis_forms).
        merge(GrdaWarehouse::HmisForm.vispdat).
        distinct.
        pluck(:id)
    end

    def service_history_service_source
      GrdaWarehouse::ServiceHistoryService
    end
  end
end
