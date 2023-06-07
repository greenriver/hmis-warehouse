###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CoreDemographicsReport::DemographicSummary
  class Report
    include Filter::ControlSections
    include Filter::FilterScopes
    include ActionView::Helpers::NumberHelper
    include ArelHelper
    include CoreDemographicsReport::AgeCalculations
    include CoreDemographicsReport::GenderCalculations
    include CoreDemographicsReport::RaceCalculations
    include CoreDemographicsReport::EthnicityCalculations
    include CoreDemographicsReport::HouseholdTypeCalculations
    include CoreDemographicsReport::ChronicCalculations
    include CoreDemographicsReport::UnshelteredCalculations
    include CoreDemographicsReport::HighAcuityCalculations
    include CoreDemographicsReport::FirstTimeCalculations
    include CoreDemographicsReport::OutcomeCalculations
    include CoreDemographicsReport::Projects
    include CoreDemographicsReport::Details
    include CoreDemographicsReport::ReportConcern

    attr_reader :filter
    attr_accessor :comparison_pattern, :project_type_codes

    def initialize(filter)
      @filter = filter
      @project_types = filter.project_type_ids || GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
      @comparison_pattern = filter.comparison_pattern
    end

    def self.url
      'core_demographics_report/warehouse_reports/demographic_summary'
    end

    def self.available_section_types
      [
        'ages',
        'genders',
        'gender_ages',
        'races',
        'ethnicities',
        'household_types',
        'chronic',
        'high_acuity',
        'unsheltered',
        'no_recent_homelessness',
        'outcome',
      ]
    end

    def section_ready?(section)
      return true unless section.in?(['disabilities', 'races'])

      Rails.cache.exist?(cache_key_for_section(section))
    end

    def detail_hash
      {}.merge(age_detail_hash).
        merge(gender_detail_hash).
        merge(ethnicity_detail_hash).
        merge(race_detail_hash).
        merge(household_detail_hash).
        merge(chronic_detail_hash).
        merge(high_acuity_detail_hash).
        merge(unsheltered_detail_hash).
        merge(no_recent_homelessness_detail_hash).
        merge(outcome_detail_hash).
        merge(enrollment_detail_hash)
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
        build_general_control_section(include_inactivity_days: true),
        build_coc_control_section,
        add_demographic_disabilities_control_section,
      ]
    end

    def report_path_array
      [
        :core_demographics_report,
        :warehouse_reports,
        :demographic_summary,
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
          rows = report.race_data_for_export(rows)
          rows = report.ethnicity_data_for_export(rows)
          rows = report.household_type_data_for_export(rows)
          rows = report.chronic_data_for_export(rows)
          rows = report.high_acuity_data_for_export(rows)
          rows = report.unsheltered_data_for_export(rows)
          rows = report.no_recent_homelessness_data_for_export(rows)
          rows = report.outcome_data_for_export(rows)
        end
      end
    end
  end
end
