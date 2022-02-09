###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reporting
  class D3Charts

    attr_reader :report
    def initialize(user, program_1, program_2)
      @user = user
      @program_1 = program_1
      @program_2 = program_2
      @report = Reporting::RrhReport.new(program_1_id: program_1, program_2_id: program_2)
    end

    def programs
      @programs ||= housed_scope(@user).pluck(:project_id, :residential_project).to_h
    end

    def self.programs_for_select(user)
      Reporting::Housed.where(project_type: 13).
        viewable_by(user).
        pluck(:residential_project, :project_id).to_a.uniq
    end

    def housed_scope user
      Reporting::Housed.viewable_by(user)
    end

    def program_1_name
      @program_1_name ||= programs.try(:[], @program_1.to_i) || 'All'
    end

    def program_2_name
      @program_2_name ||= programs.try(:[], @program_2.to_i) || 'All'
    end

    def all
      {
        overview: {data: overview, selectors: ['#d3-overview-1', '#d3-overview-2']},
        outcomes: {data: outcomes, selectors: ['#d3-outcome-1', '#d3-outcome-2'], legend: '#d3-outcome__legend'},
        shelter_returns: {data: shelter_returns, selectors: ['#d3-return-1', '#d3-return-2']},
        demographics: {data: demographics, selectors: ['#d3-demographics-1', '#d3-demographics-2'], legend: '#d3-demographics__legend'}
      }
    end

    def overview
      program_1_data = @report.housed_plot_1
      program_2_data = @report.housed_plot_2
      both = program_1_data + program_2_data
      {
        program_1: program_1_data,
        program_2: program_2_data,
        both: both
      }
    end

    def outcomes
      {
        program_1: outcome_1_data,
        program_2: outcome_2_data,
        both: outcome_1_data + outcome_2_data
      }
    end

    def shelter_returns
      {
        program_1: sr_1_data,
        program_2: sr_2_data,
        both: (sr_1_data + sr_2_data),
        x_bands: @report.length_of_time_buckets.values
      }
    end

    def demographics
      {
        program_1: demo_1_data,
        program_2: demo_2_data,
        both: (demo_1_data + demo_2_data)
      }
    end

    def demo_1_data
      @report.demographic_plot_1
    end

    def demo_2_data
      @report.demographic_plot_2
    end

    def sr_1_data
      # TODO: @elliot there is a bug here. The data for the same program is different
      @report.return_length_1
    end

    def sr_2_data
      # TODO: @elliot there is a bug here. The data for the same program is different
      @report.return_length_2
    end

    def outcome_1_data
      @report.success_failure_1
    end

    def outcome_2_data
      @report.success_failure_2
    end

    private



  end
end
