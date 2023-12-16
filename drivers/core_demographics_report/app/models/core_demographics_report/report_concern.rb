###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::ReportConcern
  extend ActiveSupport::Concern

  include ApplicationHelper
  included do
    def base_count_sym = :count

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
      filter.apply(report_scope_source, report_scope_source, all_project_types: all_project_types, include_date_range: include_date_range)
    end

    def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    def yn(boolean)
      boolean ? 'Yes' : 'No'
    end

    def mask_small_population(value)
      return value unless @filter.mask_small_populations

      bracket_small_population(value)
    end

    def total_client_count
      @total_client_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(distinct_client_ids.count)
      end
    end

    def hoh_count
      @hoh_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(hoh_scope.select(:client_id).distinct.count)
      end
    end

    def household_count
      @household_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(report_scope.select(:household_id).distinct.count)
      end
    end

    def project_count
      @project_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(report_scope.select(p_t[:id]).distinct.count)
      end
    end

    def can_see_client_details?(user)
      user.can_access_some_version_of_clients? && ! filter.mask_small_populations
    end

    def self.clear_report_cache
      Rails.cache.delete_matched("#{[name]}*")
    end

    def self.genders
      g = HudUtility2024.gender_field_name_label.dup
      g[:GenderNone] = 'Unknown Gender'
      g
    end

    def genders
      @genders ||= self.class.genders
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

    private def gender_clause(gender_col)
      return c_t[gender_col].eq(1) unless gender_col == :GenderNone

      c_t[:GenderNone].in([8, 9, 99])
    end

    private def average_age(clause:)
      average_age = nf('AVG', [age_calculation])
      scope = report_scope.joins(:client).where(clause)
      scope.joins(:client).pluck(average_age)&.first&.to_i
    end

    def available_coc_codes
      @available_coc_codes ||= filter.chosen_coc_codes.present? ? filter.chosen_coc_codes : []
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
