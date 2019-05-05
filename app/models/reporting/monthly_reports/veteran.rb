module Reporting::MonthlyReports
  class Veteran < Base

    def _populate!
      build_records
    end

    # Group clients by month and client_id
    # Loop over all of the open enrollments,

    def build_records
      @date_range = '2015-01-01'.to_date..Date.yesterday
      @start_date = @date_range.first
      @end_date = @date_range.last

      @clients = {}
      @date_range.map{|d| [d.year, d.month]}.uniq.each do |year, month|
        first_entries_in_month = {}
        last_exits_in_month = {}
        # fetch open enrollments for the given month
        enrollment_scope(start_date: Date.new(year, month, 1), end_date: Date.new(year, month, -1)).find_each do |enrollment|
          entry_month = enrollment.first_date_in_program.month
          entry_year = enrollment.first_date_in_program.year
          exit_month = enrollment.last_date_in_program&.month
          exit_year = enrollment.last_date_in_program&.year
          client_id = enrollment.client_id

          entered_in_month = entry_month == month && entry_year == year
          exited_in_month = exit_month.present? && exit_month == month && exit_year == year

          # FIXME: needs to take into account only enrollment starting this month
          first_entries_in_month[client_id] ||= enrollment.first_date_in_program
          if enrollment.first_date_in_program < first_entries_in_month[client_id]
            first_entries_in_month[client_id] = enrollment.first_date_in_program
          end

          # FIXME: needs to take into account only enrollment ending this month
          last_exits_in_month[client_id] ||= enrollment.last_date_in_program
          if enrollment.last_date_in_program.present? && enrollment.last_date_in_program > last_exits_in_month[client_id]
            last_exits_in_month[client_id] ||= enrollment.last_date_in_program
          end
          k = [year, month, client_id]
          client_enrollment = self.class.new(
            month: month,
            year: year,
            client_id: client_id,
            head_of_household: @clients[k]&.head_of_household || enrollment[:head_of_household],
            household_id: @clients[k]&.household_id || enrollment.household_id.presence || "c_#{client_id}",
            destination_id: @clients[k]&.destination || enrollment.destination,
            enrolled: true, # everyone will be enrolled
            active: @clients[k]&.active || active_in_month?(client_id: client_id, month: month, year: year),
            entered: @clients[k]&.entered || entered_in_month,
            exited: @clients[k]&.exited || exited_in_month,
            project_type: enrollment.computed_project_type,
            first_entry_in_month: 'TODO: needs to get populated on all ',
            last_exit_in_month: 'TODO',
            days_since_last_exit: nil,
            prior_exit_project_type: nil,

            calculated_at: Time.zone.now,
          )
          @clients[k] ||= client_enrollment
          # Use the last entry record from any given month as a representation
          # of the client enrollment in the month
          if client_enrollment.

          @clients[client_id] << client_enrollment
        end
      end
      @clients
    end

    def enrollment_scope start_date:, end_date:
      enrollment_source.veteran.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def active_scope
      enrollment_scope(start_date: @start_date, end_date: @end_date).
        with_service_between(start_date: @start_date, end_date: @end_date)
    end

    def active_in_month? client_id:, month:, year:
      @active_in_month ||= active_scope.joins(:service_history_services).distinct.reorder('').
        pluck(
          :client_id,
          cast(datepart(shs_t.engine, 'month', shs_t[:date]), 'INTEGER').to_sql,
          cast(datepart(shs_t.engine, 'year', shs_t[:date]), 'INTEGER').to_sql
        )
      k = [client_id, month, year]
      @active_in_month.include?(k)
    end
    # def exit_scope
    #   enrollment_source.veteran.
    #     exit_within_date_range(start_date: @start_date, end_date: @end_date)
    # end

  end
end