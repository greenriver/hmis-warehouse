###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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

    def data
      @data ||= [].tap do |d|
        clients.find_each do |client|
          entry = client_homeless_entry_dates[client.id]
          exit_record = client_housed_dates[client.id]
          days = days_homeless_in_recent_stay[client.id]
          d << OpenStruct.new(
            {
              client: client,
              days: days,
              entry_date: entry.entry_date,
              exit_date: exit_record.exit_date,
              destination: exit_record.destination,
              project_name: entry.project_name,
              project_id: entry.project_id,
            },
          )
        end
      end
    end

    def average_days
      average = data.map(&:days).sum.to_f / data.count
      average.round
    rescue ZeroDivisionError
      0
    end

    private def clients
      client_source.where(id: days_homeless_in_recent_stay.keys)
    end

    private def days_homeless_in_recent_stay
      @days_homeless_in_recent_stay ||= client_homeless_entry_dates.map do |client_id, data|
        exit_record = client_housed_dates[client_id]
        [
          client_id,
          (exit_record.exit_date - data.entry_date).to_i,
        ]
      end.to_h
    end

    private def clients_housed_ids
      @clients_housed_ids ||= client_source.
        where(id: clients_with_permanent_exits.select(:id)).
        or(client_source.where(id: clients_with_housed_enrollments.select(:id))).
        pluck(:id)
    end

    private def client_housed_dates
      @client_housed_dates ||= {}.tap do |dates|
        # Find the first date exited to a permanent destination within the range
        clients_with_permanent_exits.order(ex_t[:ExitDate].asc).pluck(:id, ex_t[:ExitDate], ex_t[:Destination]).each do |client_id, date, destination|
          dates[client_id] ||= OpenStruct.new(
            {
              exit_date: date,
              destination: "#{HudUtility2024.destination(destination)} (#{destination})",
            },
          )
        end
        # Layer on the first enrollment in PH if it is earlier
        clients_with_housed_enrollments.order(e_t[:MoveInDate].asc).pluck(:id, e_t[:MoveInDate], p_t[:ProjectName], bool_or(p_t[:confidential], o_t[:confidential])).each do |client_id, date, project_name, confidential|
          next unless dates[client_id].blank? || date < dates[client_id].exit_date

          safe_project_name = GrdaWarehouse::Hud::Project.confidentialize_name(filter.user, project_name, confidential)
          dates[client_id] = OpenStruct.new(
            {
              exit_date: date,
              destination: safe_project_name,
            },
          )
        end
      end
    end

    private def client_homeless_entry_dates
      @client_homeless_entry_dates ||= {}.tap do |dates|
        # Find the latest entry into homelessness for the client occurring before the housed date,
        # if there are overlapping homeless enrollments, go to the beginning of the first in the
        # overlapping bunch
        homeless_entries.order(she_t[:first_date_in_program].desc).
          pluck(:id, she_t[:first_date_in_program], she_t[:last_date_in_program], p_t[:ProjectName], p_t[:id], bool_or(p_t[:confidential], o_t[:confidential])).
          each do |client_id, entry_date, exit_date, project_name, project_id, confidential|
            next if client_housed_dates[client_id].exit_date < entry_date

            safe_project_name = GrdaWarehouse::Hud::Project.confidentialize_name(filter.user, project_name, confidential)
            existing_date = dates[client_id]
            # first-time through
            if existing_date.blank?
              dates[client_id] = OpenStruct.new(
                entry_date: entry_date,
                project_name: safe_project_name,
                project_id: project_id,
              )
              next
            end
            # ongoing enrollment that started earlier
            # earlier enrollment that overlaps with the later one
            next unless exit_date.blank? || existing_date.entry_date.between?(entry_date, exit_date)

            dates[client_id] = OpenStruct.new(
              entry_date: entry_date,
              project_name: safe_project_name,
              project_id: project_id,
            )
          end
      end
    end

    private def homeless_entries
      # Require some recent-ish service to avoid joining in completely empty enrollments
      client_source.joins(service_history_enrollments: [:project, :enrollment, :organization]).
        merge(
          GrdaWarehouse::ServiceHistoryEnrollment.homeless.
          entry.
          with_service_between(start_date: filter.last - 5.years, end_date: filter.last).
          where(she_t[:first_date_in_program].lt(filter.end)).
          where(client_id: clients_housed_ids),
        ).
        where(id: clients_housed_ids)
    end

    private def source_client_ids_with_permanent_exits_in_range
      GrdaWarehouse::Hud::Enrollment.with_permanent_exit(filter.range).joins(:client).pluck(c_t[:id])
    end

    private def source_client_ids_with_move_in_in_range
      GrdaWarehouse::Hud::Enrollment.housed(filter.range).joins(:client).pluck(c_t[:id])
    end

    private def clients_with_permanent_exits
      client_scope.where(wc_t[:source_id].in(source_client_ids_with_permanent_exits_in_range)).
        merge(GrdaWarehouse::Hud::Enrollment.with_permanent_exit(filter.range))
    end

    private def clients_with_housed_enrollments
      client_scope.where(wc_t[:source_id].in(source_client_ids_with_move_in_in_range)).
        merge(GrdaWarehouse::Hud::Enrollment.housed(filter.range))
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    private def client_scope
      scope = client_source.destination_visible_to(filter.user).
        send(filter.sub_population).
        joins(source_enrollments: [:project, :organization]).
        merge(GrdaWarehouse::Hud::Project.viewable_by(filter.user, permission: :can_view_assigned_reports))
      scope = scope.merge(GrdaWarehouse::Hud::Project.where(id: filter.effective_project_ids)) if filter.effective_project_ids.reject(&:zero?).any?
      scope = scope.where(id: cohort_client_scope.select(:client_id)) if filter.cohort_ids.any?
      scope
    end

    private def cohort_client_scope
      GrdaWarehouse::CohortClient.where(cohort_id: filter.cohort_ids)
    end

    def headers_for_export
      headers = ['Warehouse Client ID']
      headers += ['First Name', 'Last Name'] if ::GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
      headers += [
        'Days Homeless',
        'Entry Date',
        'Exit Date/Move-in-Date',
        'Destination/PH Project',
        'Homeless Project',
      ]
      headers
    end

    def rows_for_export
      rows = []
      data.each do |client|
        row = [client.client.id]
        row += [client.client.FirstName, client.client.LastName] if ::GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
        row += [
          client.days,
          client.entry_date,
          client.exit_date,
          client.destination,
          client.project_name,
        ]
        rows << row
      end
      rows
    end
  end
end
