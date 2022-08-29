###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AnalysisTool
  class Report
    include Filter::ControlSections
    include Filter::FilterScopes
    include ActionView::Helpers::NumberHelper
    include ArelHelper
    include ::KnownCategories::Age
    include ::KnownCategories::Gender
    include ::KnownCategories::HouseholdType
    include ::KnownCategories::Race
    include ::KnownCategories::VeteranStatus
    include ::KnownCategories::Ethnicity
    include ::KnownCategories::Lot
    include ::KnownCategories::LotThreeYears

    attr_reader :filter
    attr_accessor :comparison_pattern, :breakdowns

    def initialize(filter)
      @filter = filter
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def self.url
      'analysis_tool/warehouse_reports/analysis_tool'
    end

    def section_subpath
      "#{self.class.url}/"
    end

    def self.available_section_types
      [
        'table',
      ]
    end

    def results
      @results ||= [].tap do |table|
        table << [nil] + row_data.keys
        col_data.values.each.with_index do |col_ids, col_i|
          row = []
          row_data.values.each.with_index do |row_ids, row_i|
            row << col_data.keys[col_i] if row_i.zero?
            row << (col_ids.to_a & row_ids.to_a)
          end
          table << row
        end
      end
    end

    def client_count
      @client_count ||= report_scope.distinct.select(:client_id).count
    end

    def percent(value)
      return 0 if value.zero? || client_count.zero?

      ((value.to_f / client_count) * 100).round
    end

    private def row_data
      @row_data ||= Gather.new(
        buckets: breakdown_calculation(breakdowns[:row]),
        scope: report_scope,
        id_column: she_t[:client_id],
        calculation_column: breakdown_column(breakdowns[:row]),
      ).ids
    end

    private def col_data
      @col_data ||= Gather.new(
        buckets: breakdown_calculation(breakdowns[:col]),
        scope: report_scope,
        id_column: she_t[:client_id],
        calculation_column: breakdown_column(breakdowns[:col]),
      ).ids
    end

    def support_title(params)
      cell = params[:cell].map(&:to_i)
      row_breakdown = params[:row_breakdown]&.to_sym || breakdowns[:row]
      col_breakdown = params[:col_breakdown]&.to_sym || breakdowns[:col]

      [
        [
          available_breakdowns[row_breakdown][:title],
          breakdown_calculation(row_breakdown).keys[cell.first],
        ].join(' - '),
        [
          available_breakdowns[col_breakdown][:title],
          breakdown_calculation(col_breakdown).keys[cell.last],
        ].join(' - '),
      ].join(' with ')
    end

    def support_for(params)
      cell = params[:cell].map(&:to_i)
      row_breakdown = params[:row_breakdown]&.to_sym || breakdowns[:row]
      col_breakdown = params[:col_breakdown]&.to_sym || breakdowns[:col]
      row_ids = row_data[breakdown_calculation(row_breakdown).keys[cell.first]]
      col_ids = col_data[breakdown_calculation(col_breakdown).keys[cell.last]]
      client_ids = (row_ids.to_a & col_ids.to_a)
      GrdaWarehouse::Hud::Client.where(id: client_ids)
    end

    def section_ready?(section)
      Rails.cache.exist?(cache_key_for_section(section))
    end

    private def cache_key_for_section(section)
      case section
      when 'table'
        table_cache_key
      end
    end

    private def table_cache_key
      [self.class.name, cache_slug, 'table']
    end

    private def cache_slug
      @filter.attributes
    end

    private def expiration_length
      return 30.seconds if Rails.env.development?

      30.minutes
    end

    def multiple_project_types?
      true
    end

    protected def build_control_sections
      [
        build_general_control_section(include_comparison_period: false),
        build_coc_control_section,
        build_household_control_section,
        add_demographic_disabilities_control_section,
        build_enrollment_control_section,
      ]
    end

    def report_path_array
      [
        :analysis_tool,
        :warehouse_reports,
        :analysis_tool,
        :index,
      ]
    end

    def filter_path_array
      [:filters] + report_path_array
    end

    def include_comparison?
      comparison_pattern != :no_comparison_period
    end

    # @return filtered scope
    def report_scope(all_project_types: false)
      # Report range
      scope = report_scope_source
      scope = filter_for_user_access(scope)
      scope = filter_for_range(scope)
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
      scope = filter_for_ca_homeless(scope)
      scope = filter_for_ce_cls_homeless(scope)
      scope = filter_for_cohorts(scope)
      scope = filter_for_prior_living_situation(scope)
      scope = filter_for_times_homeless(scope)
      filter_for_destination(scope)
    end

    def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry.joins(client: :processed_service_history)
    end

    private def breakdown_calculation(key)
      send(available_breakdowns[key.to_sym].try(:[], :method) || available_breakdowns[:age][:method])
    end

    private def breakdown_column(key)
      available_breakdowns[key.to_sym].try(:[], :calculation_column) || available_breakdowns[:age][:calculation_column]
    end

    def available_breakdowns
      @available_breakdowns ||= {
        age: { title: 'Age', method: :age_calculations, calculation_column: standard_age_calculation },
        gender: { title: 'Gender', method: :gender_calculations, calculation_column: standard_gender_calculation },
        household: { title: 'Household Type', method: :household_type_calculations, calculation_column: standard_household_type_calculation },
        veteran: { title: 'Veteran Status', method: :veteran_status_calculations, calculation_column: standard_veteran_status_calculation },
        race: { title: 'Race', method: :race_calculations, calculation_column: standard_race_calculation },
        ethnicity: { title: 'Ethnicity', method: :ethnicity_calculations, calculation_column: standard_ethnicity_calculation },
        lot_homeless_three_years: { title: 'LOT Homeless (last 3 years)', method: :lot_three_years_calculations, calculation_column: standard_lot_three_years_calculation },
        lot_homeless: { title: 'LOT Homeless (all time)', method: :lot_calculations, calculation_column: standard_lot_calculation },
      }
    end
  end
end
