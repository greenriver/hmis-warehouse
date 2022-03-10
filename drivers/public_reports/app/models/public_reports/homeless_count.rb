###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports
  class HomelessCount < ::PublicReports::Report
    acts_as_paranoid

    def title
      _('Number Homeless Report Generator')
    end

    def instance_title
      _('Number Homeless Report')
    end

    private def public_s3_directory
      'homeless-total-count'
    end

    def url
      public_reports_warehouse_reports_homeless_count_index_url(host: ENV.fetch('FQDN'), protocol: 'https')
    end

    private def controller_class
      PublicReports::WarehouseReports::HomelessCountController
    end

    def run_and_save!
      start_report
      pre_calculate_data
      complete_report
    end

    private def chart_data
      count = total_homeless_count
      count = under_threshold if count.positive? && count < 100
      {
        count: count,
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
