###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports
  class HomelessCountComparison < ::PublicReports::Report
    acts_as_paranoid

    def title
      _('Percent Homeless Comparison Report Generator')
    end

    def instance_title
      _('Homeless Count Comparison Report')
    end

    private def public_s3_directory
      'homeless-total-count-comparison'
    end

    def url
      public_reports_warehouse_reports_homeless_count_index_url(host: ENV.fetch('FQDN'), protocol: 'https')
    end

    private def controller_class
      PublicReports::WarehouseReports::HomelessCountComparisonController
    end

    def run_and_save!
      start_report
      pre_calculate_data
      complete_report
    end

    private def chart_data
      filter_object.comparison_pattern = :prior_period
      {
        count: percent_change_in_count,
        date_range: filter_object.date_range_words,
        comparison_range: filter_object.to_comparison.date_range_words,
        change_direction: change_direction,
      }.to_json
    end

    private def pre_calculate_data
      update(precalculated_data: chart_data)
    end

    private def percent_change_in_count
      return 0 if total_homeless_count.zero? || total_homeless_count_prior.zero?

      @percent_change_in_count ||= (total_homeless_count * 100 / total_homeless_count_prior.to_f) - 100
    end

    private def change_direction
      if percent_change_in_count.negative?
        'negative'
      elsif percent_change_in_count.positive?
        'positive'
      else
        'no-change'
      end
    end

    private def total_homeless_count
      report_scope.distinct.select(:client_id).count
    end

    private def total_homeless_count_prior
      comparison_scope.distinct.select(:client_id).count
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

    private def comparison_scope
      # for compatability with FilterScopes
      filter_object.comparison_pattern = :prior_period
      @filter = filter_object.to_comparison
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
