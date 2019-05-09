# A reporting table to power the population dash boards.
# One row per client per sub-population per month.

module Reporting::MonthlyReports
  class Base < ReportingBase
    include ArelHelper
    include ::Reporting::MonthlyReports::MonthlyReportCharts

    self.table_name = :warehouse_monthly_reports

    after_initialize :set_dates
    attr_accessor :date_range

    def self.class_for sub_population
      {
        veteran: Reporting::MonthlyReports::Veteran
      }[sub_population.to_sym]
    end

    def set_dates
      @date_range ||= '2015-01-01'.to_date..Date.yesterday
      @start_date = @date_range.first
      @end_date = @date_range.last
    end

    def populate!
      set_enrollments_by_client
      set_prior_enrollments
      self.class.transaction do
        _clear!
        self.class.import @enrollments_by_client.values.flatten
      end
    end

    def _clear!
      self.class.delete_all
    end

    # Group clients by month and client_id
    # Loop over all of the open enrollments,
    def set_enrollments_by_client
      @enrollments_by_client = {}
      @date_range.map{|d| [d.year, d.month]}.uniq.each do |year, month|
        # fetch open enrollments for the given month
        enrollment_scope(start_date: Date.new(year, month, 1), end_date: Date.new(year, month, -1)).
          find_each do |enrollment|
          entry_month = enrollment.first_date_in_program.month
          entry_year = enrollment.first_date_in_program.year
          exit_month = enrollment.last_date_in_program&.month
          exit_year = enrollment.last_date_in_program&.year
          client_id = enrollment.client_id

          entered_in_month = entry_month == month && entry_year == year
          exited_in_month = exit_month.present? && exit_month == month && exit_year == year

          client_enrollment = self.class.new(
            month: month,
            year: year,
            client_id: client_id,
            enrollment_id: enrollment.id,
            head_of_household: enrollment[:head_of_household],
            household_id: enrollment.household_id.presence || "c_#{client_id}",
            destination_id: enrollment.destination,
            enrolled: true, # everyone will be enrolled
            active: active_in_month?(client_id: client_id, month: month, year: year),
            entered: entered_in_month,
            exited: exited_in_month,
            project_id: enrollment.project.id,
            organization_id: enrollment.organization.id,
            project_type: enrollment.computed_project_type,
            entry_date: enrollment.first_date_in_program,
            exit_date: enrollment.last_date_in_program,
            first_enrollment: first_record?(enrollment),
            days_since_last_exit: nil,
            prior_exit_project_type: nil,
            prior_exit_destination_id: nil,

            calculated_at: Time.zone.now,
          )
          @enrollments_by_client[client_id] ||= []
          @enrollments_by_client[client_id] << client_enrollment
        end
      end
      @enrollments_by_client
    end

    # By client, for each enrollment that is an entry in the month,
    # figure out the most recent exit (where there wasn't an ongoing enrollment)
    # and populate the days_since_last_exit and prior_exit_project_type as appropriate
    def set_prior_enrollments
      @enrollments_by_client.each do |client_id, enrollments|
        # find the next enrollment where entered == true
        # If all other enrollments in the current month are exits and the max exit date is
        # before the entry date, make note.
        # If the prior month is empty, or only contains exits,
        # Go back in time through the enrollments looking for a month where all enrollments
        # exited == true
        # get the latest exit date
        first_month = enrollments.first.month
        first_year = enrollments.first.year
        grouped_enrollments = enrollments.group_by{|m| [m.year, m.month]}
        grouped_enrollments.each do |(year, month), ens|
          ens.each do |en|
            if en.entered
              entry_date = en.entry_date
              current_year = en.year
              current_month = en.month

              # check current month for exits
              other_enrollments_in_current_month = ens - [en]
              if other_enrollments_in_current_month.present? && other_enrollments_in_current_month.all?(&:exited)
                max_exit_enrollment = other_enrollments_in_current_month.sort_by(&:exit_date).last
                if max_exit_enrollment.exit_date < entry_date
                  en.days_since_last_exit = (en.entry_date - max_exit_enrollment.exit_date).to_i
                  en.prior_exit_project_type = max_exit_enrollment.project_type
                  en.prior_exit_destination_id = max_exit_enrollment.destination_id
                end
              end
              next if en.days_since_last_exit.present?

              # short circuit if prior month contains ongoing enrollments
              prev = previous_month(current_year, current_month)
              previous_enrollments = grouped_enrollments[[prev.year, prev.month]]
              next unless previous_enrollments.blank? || previous_enrollments.all?(&:exited)

              # Check back through time
              while(current_year >= first_year && current_month >= first_month) do
                prev = previous_month(current_year, current_month)
                current_month = prev.month
                current_year = prev.year

                current_enrollments = grouped_enrollments[[current_year, current_month]]
                if current_enrollments.present? && current_enrollments.all?(&:exited)
                  previous_exit = current_enrollments.sort_by(&:exit_date).last
                  en.days_since_last_exit = (en.entry_date - previous_exit.exit_date).to_i
                  en.prior_exit_project_type = previous_exit.project_type
                  en.prior_exit_destination_id = previous_exit.destination_id
                  break
                end
              end
            end
          end
        end
      end
    end

    def previous_month year, month
      Date.new(year, month, 1) - 1.month
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

    def first_record? enrollment
      @first_records ||= first_scope.distinct.
        pluck(
          :client_id,
          p_t[:id].to_sql,
          :first_date_in_program
        ).map do |client_id, p_id, date|
          [client_id, [p_id, date]]
        end.to_h
      @first_records[enrollment.client_id] == [enrollment.project.id, enrollment.first_date_in_program]
    end

    def enrollment_scope
      raise NotImplementedError
    end

    def sub_population_title
      raise NotImplementedError
    end

    def sub_population
      raise NotImplementedError
    end

    def active_scope
      enrollment_scope(start_date: @start_date, end_date: @end_date).
        with_service_between(start_date: @start_date, end_date: @end_date)
    end

    def first_scope
      enrollment_source.first_date.where(client_id: enrollment_scope(start_date: @start_date, end_date: @end_date).select(:client_id))
    end

    def enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment.homeless.joins(:project, :organization).preload(:project, :organization)
    end

  end
end