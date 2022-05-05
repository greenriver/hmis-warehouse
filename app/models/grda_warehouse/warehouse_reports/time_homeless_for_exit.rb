###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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

    private def clients_housed_scope
      client_source.
        where(id: clients_with_permanent_exits.select(:id)).
        or(client_source.where(id: clients_with_housed_enrollments.select(:id)))
    end

    private def client_housed_dates
      @client_housed_dates ||= {}.tap do |dates|
        # Find the first date exited to a permanent destination within the range
        clients_with_permanent_exits.order(ex_t[:ExitDate].asc).pluck(:id, ex_t[:ExitDate], ex_t[:Destination]).each do |client_id, date, destination|
          dates[client_id] ||= OpenStruct.new(
            {
              exit_date: date,
              destination: "#{HUD.destination(destination)} (#{destination})",
            },
          )
        end
        # Layer on the first enrollment in PH if it is earlier
        clients_with_housed_enrollments.order(e_t[:MoveInDate].asc).pluck(:id, e_t[:MoveInDate], p_t[:ProjectName]).each do |client_id, date, project_name|
          next unless dates[client_id].blank? || date < dates[client_id].exit_date

          dates[client_id] = OpenStruct.new(
            {
              exit_date: date,
              destination: project_name,
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
          pluck(:id, she_t[:first_date_in_program], she_t[:last_date_in_program], p_t[:ProjectName], p_t[:id]).
          each do |client_id, entry_date, exit_date, project_name, project_id|
            next if client_housed_dates[client_id].exit_date < entry_date

            existing_date = dates[client_id]
            # first-time through
            if existing_date.blank?
              dates[client_id] = OpenStruct.new(
                entry_date: entry_date,
                project_name: project_name,
                project_id: project_id,
              )
              next
            end
            # ongoing enrollment that started earlier
            # earlier enrollment that overlaps with the later one
            next unless exit_date.blank? || existing_date.entry_date.between?(entry_date, exit_date)

            dates[client_id] = OpenStruct.new(
              entry_date: entry_date,
              project_name: project_name,
              project_id: project_id,
            )
          end
      end
    end

    private def homeless_entries
      # Require some recent-ish service to avoid joining in completely empty enrollments
      client_source.joins(service_history_enrollments: [:project, :enrollment]).
        merge(
          GrdaWarehouse::ServiceHistoryEnrollment.homeless.
          entry.
          with_service_between(start_date: filter.last - 5.years, end_date: filter.last).
          where(she_t[:first_date_in_program].lt(filter.end)).
          where(client_id: clients_housed_scope.select(:id)),
        ).
        where(id: clients_housed_scope.select(:id))
    end

    private def clients_with_permanent_exits
      client_scope.merge(GrdaWarehouse::Hud::Enrollment.with_permanent_exit(filter.range))
    end

    private def clients_with_housed_enrollments
      client_scope.merge(GrdaWarehouse::Hud::Enrollment.housed(filter.range))
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    private def client_scope
      apply_filters(client_source.destination_visible_to(filter.user))
    end

    private def apply_filters(scope)
      scope = scope.send(filter.sub_population).
        joins(source_enrollments: :project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(filter.user))

      scope = scope.merge(GrdaWarehouse::Hud::Project.where(id: filter.effective_project_ids)) if filter.effective_project_ids.reject(&:zero?).any?
      scope = scope.where(id: cohort_client_scope.select(:client_id)) if filter.cohort_ids.any?
      scope
    end

    private def cohort_client_scope
      GrdaWarehouse::CohortClient.where(cohort_id: filter.cohort_ids)
    end
  end
end
