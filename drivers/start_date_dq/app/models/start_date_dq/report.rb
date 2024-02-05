###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module StartDateDq
  class Report
    include ActionView::Helpers::NumberHelper
    include ArelHelper
    include Filter::FilterScopes

    attr_reader :filter

    def initialize(user_id, filter = nil)
      @filter = filter || default_filter(user_id)
    end

    def default_filter(user_id)
      Filters::FilterBase.new(user_id: user_id)
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def self.url
      'start_date_dq/warehouse_reports/reports'
    end

    def title
      'Date Homelessness Started'
    end

    def column_names
      [
        'Days Between Date Homelessness Started and Entry Date',
        'Date Homelessness Started (Self-Reported)',
        'Entry Date',
        'Exit Date',
        'Days between Entry Date and Exit Date (or report end)',
        'Personal ID',
        'Project',
        'Project Type',
      ]
    end

    def column_values(row, user)
      date_to_street = row.enrollment.DateToStreetESSH
      entry_date = row.enrollment.EntryDate
      exit_date = row.enrollment.exit&.ExitDate
      days_between_start_and_exit = ([filter.end, exit_date].compact.min - entry_date).to_i
      {
        days_between: (entry_date - date_to_street).to_i,
        date_to_street: date_to_street,
        entry_date: entry_date,
        exit_date: exit_date,
        days_between_start_and_exit: days_between_start_and_exit,
        personal_id: row.enrollment.PersonalID,
        project_name: row.project&.name(user),
        project_type: HudUtility2024.project_type_brief(row.project_type),
      }
    end

    def data
      scope = report_scope.joins(:client, :project).
        left_outer_joins(enrollment: :exit).
        where(e_t[:EntryDate].not_eq(nil).
          and(e_t[:DateToStreetESSH].not_eq(nil)))

      exit_date_query = nf('LEAST', [cl(ex_t[:ExitDate], filter.end), filter.end])
      days_between = case filter.dates_to_compare
      when :entry_to_exit
        datediff(scope, 'day', exit_date_query, e_t[:EntryDate])
      when :date_to_street_to_entry
        datediff(scope, 'day', e_t[:EntryDate], e_t[:DateToStreetESSH])
      when :date_to_street_to_exit
        datediff(scope, 'day', exit_date_query, e_t[:DateToStreetESSH])
      end

      if filter.length_of_times.present?
        conditions = filter.length_of_times.filter_map do |s|
          next unless day_ranges.key?(s)

          range = day_ranges[s]
          if range.begin == -Float::INFINITY
            days_between.lteq(range.end)
          elsif range.end == Float::INFINITY
            days_between.gteq(range.begin)
          else
            days_between.gteq(range.begin).and(days_between.lteq(range.end))
          end
        end

        if conditions.present?
          days_between_condition = conditions.reduce(conditions[0]) do |clause, cond|
            clause == cond ? clause : clause.or(cond)
          end
          scope = scope.where(days_between_condition)
        end
      end

      fields = []
      fields << report_scope_source.arel_table[Arel.star]
      fields << GrdaWarehouse::Hud::Client.arel_table[Arel.star]
      fields << GrdaWarehouse::Hud::Enrollment.arel_table[Arel.star]
      fields << GrdaWarehouse::Hud::Project.arel_table[Arel.star]
      fields << Arel.sql(days_between.as('days_between').to_sql)

      scope.distinct.
        order(days_between.desc).
        select(fields)
    end

    def report_scope
      scope = report_scope_source
      scope = filter_for_user_access(scope)
      scope = filter_for_range(scope)
      scope = filter_for_project_type(scope, all_project_types: false)
      scope = filter_for_projects(scope)
      scope = filter_for_cocs(scope)
      scope
    end

    def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry.joins(:enrollment)
    end

    def day_ranges
      {
        '<0 days': (-Float::INFINITY..-1),
        '0-30 days': (0..30),
        '31-90 days': (31..90),
        '91-180 days': (91..180),
        '181+ days': (181..Float::INFINITY),
      }
    end
  end
end
