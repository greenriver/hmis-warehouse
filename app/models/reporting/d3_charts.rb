module Reporting
  class D3Charts

    attr_reader :report
    def initialize(program_1, program_2)
      @program_1 = program_1
      @program_2 = program_2
      @report = Reporting::RrhReport.new(program_1_id: program_1, program_2_id: program_2)
    end

    def programs
      @programs ||= Reporting::Housed.pluck(:project_id, :residential_project).to_h
    end

    def program_1_name
      @program_1_name ||= programs.try(:[], @program_1) || 'All'
    end

    def program_2_name
      @program_2_name ||= programs.try(:[], @program_2) || 'All'
    end

    def overview
      program_1_data = @report.housed_plot_1
      program_2_data = @report.housed_plot_2
      {
        program_1: program_1_data.to_json,
        program_2: program_2_data.to_json,
        both: (program_1_data + program_2_data).to_json
      }
    end

    def outcomes
      {
        program_1: outcome_1_data.to_json,
        program_2: outcome_2_data.to_json
      }
    end

    def shelter_returns
      x_bands = ['Less than 1 week', '1 week to one month', '1 month to 3 months', '3 months to 6 months', '3 months to 1 year', '1 year to 2 years', '2 years or more']
      {
        program_1: sr_1_data,
        program_2: sr_2_data,
        both: (sr_1_data + sr_2_data),
        x_bands: x_bands
      }.to_json
    end

    def sr_1_data
      @report.return_length_1
      # [{discrete: 'Less than 1 week', count: 154}, {discrete: '1 week to one month', count: 63}, {discrete: '1 month to 3 months', count: 133}, {discrete: '3 months to 6 months', count: 107}, {discrete: '3 months to 1 year', count: 105}, {discrete: '1 year to 2 years', count: 47}]
    end

    def sr_2_data
      @report.return_length_2
      # [{discrete: 'Less than 1 week', count: 1}, {discrete: '1 month to 3 months', count: 1}, {discrete: '3 months to 6 months', count: 1}]
    end

    def outcome_1_data
      @report.success_failure_1
      # [{outcome: 'exited to other institution', count: 839}, {outcome: 'returned to shelter', count: 1112}, {outcome: 'successful exit to PH', count: 2814}, {outcome: 'unknown outcome', count: 4044}]
    end

    def outcome_2_data
      @report.success_failure_2
      # [{outcome: 'exited to other institution', count: 34}, {outcome: 'returned to shelter', count: 9}, {outcome: 'successful exit to PH', count: 72}, {outcome: 'unknown outcome', count: 74}]
    end

    private



  end
end