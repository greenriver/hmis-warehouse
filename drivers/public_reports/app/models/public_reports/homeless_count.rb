###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports
  class HomelessCount < ::PublicReports::Report
    acts_as_paranoid

    def title
      _('Homeless Count Generator')
    end

    def instance_title
      _('Homeless Count Report')
    end

    private def public_s3_directory
      'homeless-total-count'
    end

    def url
      public_reports_warehouse_reports_homeless_count_index_url(host: ENV.fetch('FQDN'))
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
      {
        count: total_homeless_count,
        date_range: filter_object.date_range_words,
      }.to_json
    end

    private def pre_calculate_data
      update(precalculated_data: chart_data)
    end

    private def total_homeless_count
      report_scope.distinct.select(:client_id).count
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
