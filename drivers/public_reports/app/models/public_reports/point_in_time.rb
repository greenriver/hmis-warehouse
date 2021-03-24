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
      public_reports_warehouse_reports_point_in_time_index_url(host: ENV.fetch('FQDN'))
    end

    def generate_publish_url
      # TODO: This is the standard S3 public access, it will need to be updated
      # when moved to CloudFront
      if ENV['S3_PUBLIC_URL'].present?
        "#{ENV['S3_PUBLIC_URL']}/#{public_s3_directory}"
      else
        # "http://#{s3_bucket}.s3-website-#{ENV.fetch('AWS_REGION')}.amazonaws.com/#{public_s3_directory}"
        "https://#{s3_bucket}.s3.amazonaws.com/#{public_s3_directory}/index.html"
      end
    end

    def run_and_save!
      start_report
      pre_calculate_data
      complete_report
    end

    private def chart_data
      x = ['x']
      y = ['Unique people experiencing homelessness']
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
      report_scope.joins(:service_history_services).
        where(shs_t[:date].eq(date)).
        select(:client_id).
        distinct.count
    end

    private def report_scope
      # for compatability with FilterScopes
      @filter = filter_object
      @project_types = @filter.project_type_numbers
      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry
      scope = filter_for_range(scope)
      scope = filter_for_cocs(scope)
      scope = filter_for_project_type(scope)
      scope = filter_for_data_sources(scope)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope
    end
  end
end
