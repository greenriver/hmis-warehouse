###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports
  class PitByMonth < ::PublicReports::Report
    acts_as_paranoid

    def title
      _('Point-in-Time by Month Report Generator')
    end

    def instance_title
      _('Point-in-Time by Month Report')
    end

    private def public_s3_directory
      'point-in-time-by-month'
    end

    def url
      public_reports_warehouse_reports_pit_by_month_index_url(host: ENV.fetch('FQDN'))
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
      pit_count = ['Average people experiencing homelessness per day']
      new_count = ['Average newly homeless per day']
      pit_counts.each do |date, (pit, newly)|
        x << date
        pit_count << pit
        new_count << newly
      end
      [x, pit_count, new_count].to_json
    end

    private def pre_calculate_data
      update(precalculated_data: chart_data)
    end

    # first of the month
    private def pit_count_dates
      month = filter_object.start.beginning_of_month
      dates = []
      while month < filter_object.end
        next_month = month.next_month.beginning_of_month
        dates << next_month
        month = next_month
      end
      dates.select { |date| date.between?(filter_object.start, filter_object.end) }
    end

    private def pit_counts
      pit_count_dates.map do |date|
        [
          date,
          [
            average_daily_client_count_for_month(date),
            average_daily_newly_homeless_for_month(date),
          ],
        ]
      end
    end

    private def average_daily_client_count_for_month(date)
      client_count = report_scope.joins(:service_history_services).
        where(shs_t[:date].between(date.beginning_of_month..date.end_of_month)).
        pluck(shs_t[:client_id].to_sql, shs_t[:date].to_sql).
        uniq.count
      return 0 unless client_count.positive?

      client_count / days_in_month(date)
    end

    private def average_daily_newly_homeless_for_month(date)
      newly_homeless_in_month = newly_homeless_for_month(date).count
      return 0 unless newly_homeless_in_month.positive?

      newly_homeless_in_month / days_in_month(date)
    end

    private def days_in_month(date)
      (date.end_of_month - date.beginning_of_month).to_i
    end

    private def newly_homeless_for_month(date)
      @filter = filter_object
      @project_types = @filter.project_type_numbers
      scope = GrdaWarehouse::ServiceHistoryEnrollment.first_date
      scope = scope.where(first_date_in_program: date.beginning_of_month..date.end_of_month)
      scope = filter_for_cocs(scope)
      scope = filter_for_project_type(scope)
      scope = filter_for_data_sources(scope)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope
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
