###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CoreDemographicsReport
  class Core
    include Filter::ControlSections
    include ActionView::Helpers::NumberHelper

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

    def multiple_project_types?
      true
    end

    protected def build_control_sections
      [
        build_general_control_section,
        build_coc_control_section,
        build_household_control_section,
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

    def include_comparison?
      comparison_pattern != :no_comparison_period
    end
  end
end
