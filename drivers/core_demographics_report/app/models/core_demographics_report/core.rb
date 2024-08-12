###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CoreDemographicsReport
  class Core
    include CoreDemographicsReport::ReportConcern # NOTE: this must come before age calculations
    include Filter::ControlSections
    include Filter::FilterScopes
    include ActionView::Helpers::NumberHelper
    include ArelHelper
    include CoreDemographicsReport::AgeCalculations
    include CoreDemographicsReport::GenderCalculations
    include CoreDemographicsReport::RaceCalculations
    include CoreDemographicsReport::EthnicityCalculations
    # RaceEthnicityCalculations relies on Race and Ethnicity Calculations, and must come  after thme
    include CoreDemographicsReport::RaceEthnicityCalculations
    include CoreDemographicsReport::DisabilityCalculations
    include CoreDemographicsReport::RelationshipCalculations
    include CoreDemographicsReport::DvCalculations
    include CoreDemographicsReport::PriorCalculations
    include CoreDemographicsReport::HouseholdTypeCalculations
    include CoreDemographicsReport::Projects
    include CoreDemographicsReport::Details

    attr_reader :filter
    attr_accessor :comparison_pattern, :project_type_codes

    def initialize(filter)
      @filter = filter
      @project_types = filter.project_type_ids || HudUtility2024.homeless_project_types
      @comparison_pattern = filter.comparison_pattern
    end

    # The CoC breakdowns aren't relevant to the Core Demographics report right now.
    def calculate_coc_breakdowns?
      false
    end

    def self.url
      'core_demographics_report/warehouse_reports/core'
    end

    def self.available_section_types
      [
        'ages',
        'genders',
        'gender_ages',
        'races_ethnicities',
        'races',
        'ethnicities',
        'disabilities',
        'relationships',
        'dvs',
        'priors',
        'household_types',
        'projects',
      ]
    end

    def section_ready?(section)
      return true unless section.in?(['disabilities', 'races'])

      Rails.cache.exist?(cache_key_for_section(section))
    end

    private def cache_key_for_section(section)
      case section
      when 'disabilities'
        disabilities_cache_key
      when 'races'
        races_cache_key
      end
    end

    protected def build_control_sections
      [
        build_general_control_section,
        build_coc_control_section,
        add_demographic_disabilities_control_section,
      ]
    end

    def report_path_array
      [
        :core_demographics_report,
        :warehouse_reports,
        :core,
        :index,
      ]
    end

    def self.data_for_export(reports)
      {}.tap do |rows|
        reports.each do |report|
          rows['Date Range'] ||= []
          rows['Date Range'] += [report.filter.date_range_words, nil, nil, nil]
          rows['Unique Clients'] ||= []
          rows['Unique Clients'] += [report.total_client_count, nil, nil, nil]
          rows['Heads of Household'] ||= []
          rows['Heads of Household'] += [report.hoh_count, nil, nil, nil]
          rows['Households'] ||= []
          rows['Households'] += [report.household_count, nil, nil, nil]

          rows = report.age_data_for_export(rows)
          rows = report.gender_data_for_export(rows)
          rows = report.race_combination_data_for_export(rows)
          rows = report.race_data_for_export(rows)
          rows = report.ethnicity_data_for_export(rows)
          rows = report.relationship_data_for_export(rows)
          rows = report.disability_data_for_export(rows)
          rows = report.dv_status_data_for_export(rows)
          rows = report.priors_data_for_export(rows)
          rows = report.household_type_data_for_export(rows)
          rows = report.enrollment_data_for_export(rows)
        end
      end
    end
  end
end
