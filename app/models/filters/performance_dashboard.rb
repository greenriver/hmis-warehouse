###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class PerformanceDashboard < DateRangeAndSources
    attribute :comparison_pattern, Symbol, default: -> (r,_) { r.default_comparison_pattern }
    attribute :household_type, Symbol, default: :all
    attribute :hoh_only, Boolean, default: false
    # NOTE: params[:filters][:project_types] will be 'es', 'th', etc.
    # the report expects @filter.project_types to be an array of integers 1, 2 etc.
    attribute :project_type_codes, Array, default: -> (r,_) { r.default_project_type_codes }
    attribute :veteran_statuses, Array, default: []
    attribute :age_ranges, Array, default: []
    attribute :genders, Array, default: []
    attribute :races, Array, default: []
    attribute :ethnicities, Array, default: []

    # NOTE: params[:filters][:project_types] will be 'es', 'th', etc.
    # the report expects @filter.project_types to be an array of integers 1, 2 etc.
    def set_from_params(filters)
      return unless filters.present?

      self.start = filters.dig(:start)&.to_date
      self.end = filters.dig(:end)&.to_date
      pattern = filters.dig(:comparison_pattern)&.to_sym
      self.comparison_pattern = pattern if PerformanceDashboards::Overview.valid_comparison_pattern?(pattern)
      self.coc_codes = filters.dig(:coc_codes)&.select { |code| PerformanceDashboards::Overview.coc_codes.include?(code) }
      self.household_type = filters.dig(:household_type)&.to_sym
      self.hoh_only = filters.dig(:hoh_only) == '1'
      self.project_type_codes = Array.wrap(filters.dig(:project_type_codes))&.reject { |type| type.blank? }.presence
      self.data_source_ids = filters.dig(:data_source_ids)&.reject(&:blank?)&.map(&:to_i)
      self.organization_ids = filters.dig(:organization_ids)&.reject(&:blank?)&.map(&:to_i)
      self.project_ids = filters.dig(:project_ids)&.reject(&:blank?)&.map(&:to_i)
      self.funder_ids = filters.dig(:funder_ids)&.reject(&:blank?)&.map(&:to_i)
      self.veteran_statuses = filters.dig(:veteran_statuses)&.reject(&:blank?)&.map(&:to_i)
      self.age_ranges = filters.dig(:age_ranges)&.reject(&:blank?)&.map { |range| range.to_sym }
      self.genders = filters.dig(:genders)&.reject(&:blank?)&.map { |gender| gender.to_i }
      self.sub_population = filters.dig(:sub_population)&.to_sym
      self.races = filters.dig(:races)&.select { |race| HUD.races.keys.include?(race) }
      self.ethnicities = filters.dig(:ethnicities)&.reject(&:blank?)&.map { |ethnicity| ethnicity.to_i }

      ensure_dates_work
    end

    # @filter.coc_codes = params.dig(:filters, :coc_codes)&.select { |code| PerformanceDashboards::Overview.coc_codes.include?(code) }
    # @filter.project_types = @filter.project_type_codes.map { |type| GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING[type.to_sym] }.flatten
    # races = params.dig(:filters, :races)&.select { |race| HUD.races.keys.include?(race) } || defaults.races
    # @filter.races = races.map { |race| [race, 1] }.to_h

    def start_date
      first
    end

    def end_date
      last
    end

    def default_start
      (Date.current - 1.year).beginning_of_year
    end

    def default_end
      (Date.current - 1.year).end_of_year
    end

    # disallow selection > 1 year, and reverse dates
    def ensure_dates_work
      ensure_date_order
      ensure_date_span
    end

    def ensure_date_order
      return unless last < first

      new_first = last
      self.end = first
      self.start = new_first
    end

    def ensure_date_span
      return if last - first < 365

      self.end = first + 1.years
    end

    def default_comparison_pattern
      :no_comparison_period
    end

    def default_project_type_codes
      GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPE_CODES
    end
  end
end