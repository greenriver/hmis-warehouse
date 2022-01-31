###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports
  class PointInTime < ::PublicReports::Report
    include ArelHelper
    acts_as_paranoid

    def title
      _('Point-in-Time Report Generator')
    end

    def instance_title
      _('Point-in-Time Report')
    end

    private def public_s3_directory
      'point-in-time'
    end

    def url
      public_reports_warehouse_reports_point_in_time_index_url(host: ENV.fetch('FQDN'), protocol: 'https')
    end

    private def controller_class
      PublicReports::WarehouseReports::PointInTimeController
    end

    def run_and_save!
      start_report
      pre_calculate_data
      complete_report
    end

    private def chart_data
      client_title = if filter_object.hoh_only
        'households'
      else
        'people'
      end
      x = ['x']
      y = ["Unique #{client_title} experiencing homelessness"]
      pit_counts.each do |date, count|
        x << date
        y << count
      end
      [x, y].to_json
    end

    private def pre_calculate_data
      update(precalculated_data: chart_data)
    end

    private def pit_count_dates
      year = filter_object.start.year
      dates = []
      while year < filter_object.end.year + 1
        d = Date.new(year, 1, -1)
        d -= (d.wday - 3) % 7
        dates << d
        year += 1
      end
      dates.select { |date| date.between?(filter_object.start, filter_object.end) }
    end

    private def pit_counts
      pit_count_dates.map do |date|
        [
          date,
          client_count_for_date(date),
        ]
      end
    end

    private def client_count_for_date(date)
      report_scope.service_on_date(date).
        select(:client_id).
        distinct.count
    end

    private def report_scope
      # for compatability with FilterScopes
      @filter = filter_object
      @project_types = @filter.project_type_numbers
      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry
      scope = filter_for_user_access(scope)
      scope = filter_for_range(scope)
      scope = filter_for_cocs(scope)
      scope = filter_for_project_type(scope)
      scope = filter_for_data_sources(scope)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope = filter_for_head_of_household(scope)
      scope
    end
  end
end
