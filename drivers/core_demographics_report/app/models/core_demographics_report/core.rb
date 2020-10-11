###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CoreDemographicsReport
  class Core
    attr_reader :filter
    attr_accessor :comparison_pattern, :project_type_codes

    def initialize(filter)
      @filter = filter
    end

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

    def client_filters?
      true
    end

    def multiple_project_types?
      true
    end

    def report_path_array
      [
        :core_demographics_report,
        :warehouse_reports,
        :core,
        :index,
      ]
    end

    def filter_path_array
      [:filters] + report_path_array
    end

    def detail_link_base
      "#{section_subpath}details"
    end

    def section_subpath
      "#{self.class.url}/"
    end

    def detail_path_array
      [:details] + report_path_array
    end

    def control_sections
      @control_sections ||= build_control_sections
    end

    protected def build_control_sections
      [
        build_general_control_section,
        build_coc_control_section,
        build_household_control_section,
        build_demographics_control_section,
        build_enrollment_control_section,
      ]
    end

    protected def build_general_control_section
      ::Filters::UiControlSection.new(id: 'general').tap do |section|
        section.add_control(
          id: 'project_types',
          required: true,
          label: 'Population by Project Type',
          short_label: 'Project Type',
          value: describe_household_control_section,
        )
        section.add_control(id: 'reporting_period', required: true, value: date_range_words)
        section.add_control(id: 'comparison_period', value: nil)
      end
    end

    protected def describe_household_control_section
      if chosen_project_types_only_homeless?
        'Only Homeless'
      elsif filter.project_type_codes.sort == GrdaWarehouse::Hud::Project::PROJECT_GROUP_TITLES.keys.map(&:to_s).sort
        'All'
      else
        chosen_project_types
      end
    end

    protected def build_coc_control_section
      title = if GrdaWarehouse::Config.get(:multi_coc_installation)
        'CoC & Funding'
      else
        'Projects & Funding'
      end
      ::Filters::UiControlSection.new(id: 'coc', title: title).tap do |section|
        if GrdaWarehouse::Config.get(:multi_coc_installation)
          section.add_control(
            id: 'coc_codes',
            label: 'CoC Codes',
            short_label: 'CoC',
            value: chosen_coc_codes,
          )
        end
        section.add_control(id: 'funding_sources', value: funder_names)
        section.add_control(id: 'data_sources', value: data_source_names)
        section.add_control(id: 'organizations', value: organization_names)
        section.add_control(id: 'projects', value: project_names)
        section.add_control(id: 'project_groups', value: project_groups)
      end
    end

    protected def build_household_control_section
      ::Filters::UiControlSection.new(id: 'household').tap do |section|
        section.add_control(id: 'household_type', required: true, value: @filter.household_type == :all ? nil : chosen_household_type)
        if performance_type == 'Client'
          section.add_control(
            id: 'hoh_only',
            label: 'Only Heads of Household?',
            value: @filter.hoh_only ? 'HOH Only' : nil,
          )
        end
      end
    end

    protected def build_demographics_control_section
      ::Filters::UiControlSection.new(id: 'demographics').tap do |section|
        section.add_control(
          id: 'sub_population',
          label: 'Sub-Population',
          short_label: 'Sub-Population',
          required: true,
          value: @filter.sub_population == :clients ? nil : chosen_sub_population,
        )
        if performance_type == 'Client'
          section.add_control(id: 'races', value: chosen_races, short_label: 'Race')
          section.add_control(id: 'ethnicities', value: chosen_ethnicities, short_label: 'Ethnicity')
          section.add_control(id: 'age_ranges', value: chosen_age_ranges, short_label: 'Age')
          section.add_control(
            id: 'genders',
            short_label: 'Gender',
            value: chosen_genders,
          )
          section.add_control(
            id: 'veteran_statuses',
            short_label: 'Veteran Status',
            value: chosen_veteran_statuses,
          )
        end
      end
    end

    protected def build_enrollment_control_section
      return if multiple_project_types?

      ::Filters::UiControlSection.new(id: 'enrollment').tap do |section|
        section.add_control(id: 'prior_living_situations', value: chosen_prior_living_situations)
        section.add_control(id: 'destinations', value: chosen_destinations)
      end
    end

    def include_comparison?
      comparison_pattern != :no_comparison_period
    end
  end
end
