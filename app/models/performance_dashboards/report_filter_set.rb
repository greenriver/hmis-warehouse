###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboards
  class ReportFilterSet
    include ActiveModel::Attributes
    include ActiveModel::AttributeAssignment

    attr_accessor :user

    attribute :start_date, :date, default: -> { (Date.current - 1.year).end_of_year }
    attribute :end_date, :date, default: -> { (Date.current - 1.year).beginning_of_year }
    attribute :comparison_pattern, :symbol, default: :no_comparison_period
    attribute :coc_codes, :normalized_string_array, default: []
    attribute :household_type, :symbol, default: :all
    attribute :hoh_only, :boolean
    attribute :project_type_codes, :normalized_string_array,
              default: -> { GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING.keys }
    attribute :data_source_ids, :normalized_integer_array, default: []
    attribute :organization_ids, :normalized_integer_array, default: []
    attribute :project_ids, :normalized_integer_array, default: []
    attribute :funder_ids, :normalized_integer_array, default: []
    attribute :veteran_statuses, :normalized_string_array, default: []
    attribute :age_ranges, :normalized_symbol_array, default: []
    attribute :genders, :normalized_string_array, default: []
    attribute :sub_population, :symbol, default: :clients
    attribute :races, :normalized_string_array, default: []
    attribute :ethnicities, :normalized_integer_array, default: []

    def range
      # FIXME: called by the Overview#housed but doesn't seem to be provided by params
      nil
    end

    # FIXME: - what's this do?
    # app/models/performance_dashboards/base.rb
    # 45:    f.user_id = @filter.user.id
    attr_accessor :user_id

    def to_h
      # FIXME: - what's this do?
      attributes
    end

    def exiting_total_count
      # FIXME: - what's this do?
      nil
    end

    def enrolled_total_count
      # FIXME: - what's this do?
      nil
    end

    def entering_total_count
      # FIXME: - what's this do?
      nil
    end

    def races
      # FIXME: - this behavior preserved from controller
      values = attributes['races'].select do |race|
        HUD.races.key?(race)
      end
      values.map { |v| [v, 1] }.to_h
    end

    def project_types
      project_type_codes.flat_map do |code|
        GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING[code.to_sym]
      end
    end

    def to_comparison_set
      comparison = dup
      (comparison.start_date, comparison.end_date) = comparison_dates if comparison_pattern != :no_comparison_period
      comparison
    end

    private def ensure_dates_work
      self.end_date = start_date + 1.years if end_date - start_date > 365
      return if end_date > start_date

      new_start = end_date
      self.end_date = start_date
      self.start_date = new_start
      self.end_date = start_date + 1.years if end_date - start_date > 365
    end

    private def comparison_dates
      case comparison_pattern
      when :prior_period
        prior_end = start_date - 1.days
        period_length = (end_date - start_date).to_i
        prior_start = prior_end - period_length.to_i.days
        [prior_start, prior_end]
      when :prior_year
        prior_end = end_date - 1.years
        prior_start = start_date - 1.years
        [prior_start, prior_end]
      else
        [start_date, end_date]
      end
    end
  end
end
