###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::ReportConcern
  extend ActiveSupport::Concern
  included do
    def self.comparison_patterns
      {
        no_comparison_period: 'None',
        prior_year: 'Same period, prior year',
        prior_period: 'Prior Period',
      }.invert.freeze
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def multiple_project_types?
      true
    end

    def filter_path_array
      [:filters] + report_path_array
    end

    def include_comparison?
      comparison_pattern != :no_comparison_period
    end

    # @return filtered scope
    def report_scope(all_project_types: false, include_date_range: true)
      # Report range
      scope = report_scope_source
      scope = filter_for_user_access(scope)
      scope = filter_for_range(scope) unless include_date_range
      scope = filter_for_cocs(scope)
      scope = filter_for_sub_population(scope)
      scope = filter_for_household_type(scope)
      scope = filter_for_head_of_household(scope)
      scope = filter_for_age(scope)
      scope = filter_for_gender(scope)
      scope = filter_for_race(scope)
      scope = filter_for_ethnicity(scope)
      scope = filter_for_veteran_status(scope)
      scope = filter_for_project_type(scope, all_project_types: all_project_types)
      scope = filter_for_data_sources(scope)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope = filter_for_funders(scope)
      scope = filter_for_disabilities(scope)
      scope = filter_for_indefinite_disabilities(scope)
      scope = filter_for_dv_status(scope)
      scope = filter_for_chronic_at_entry(scope)
      scope = filter_for_times_homeless(scope)
      scope = filter_for_ca_homeless(scope)
      scope = filter_for_ce_cls_homeless(scope)
      scope = filter_for_cohorts(scope)
      scope
    end

    def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    def yn(boolean)
      boolean ? 'Yes' : 'No'
    end

    def total_client_count
      @total_client_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        distinct_client_ids.count
      end
    end

    def hoh_count
      @hoh_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        hoh_scope.select(:client_id).distinct.count
      end
    end

    def household_count
      @household_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        report_scope.select(:household_id).distinct.count
      end
    end

    def project_count
      @project_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        report_scope.select(p_t[:id]).distinct.count
      end
    end

    def can_see_client_details?(user)
      user.can_access_some_version_of_clients?
    end

    private def hoh_scope
      report_scope.where(she_t[:head_of_household].eq(true))
    end

    private def distinct_client_ids
      report_scope.select(:client_id).distinct
    end

    private def adult_clause
      age_calculation.in((18..110).to_a)
    end

    private def youth_clause
      age_calculation.in((18..24).to_a)
    end

    private def child_clause
      age_calculation.in((0..17).to_a)
    end

    private def male_clause
      c_t[:Male].eq(1)
    end

    private def female_clause
      c_t[:Female].eq(1)
    end

    private def trans_clause
      c_t[:Transgender].eq(1)
    end

    private def questioning_clause
      c_t[:Questioning].eq(1)
    end

    private def no_single_gender_clause
      c_t[:NoSingleGender].eq(1)
    end

    private def unknown_gender_clause
      c_t[:GenderNone].in([8, 9, 99])
    end

    private def average_age(clause:)
      average_age = nf('AVG', [age_calculation])
      scope = report_scope.joins(:client).where(clause)
      scope.joins(:client).pluck(average_age)&.first&.to_i
    end

    private def cache_slug
      @filter.attributes
    end

    private def expiration_length
      return 3.minutes if Rails.env.development?

      30.minutes
    end
  end
end
