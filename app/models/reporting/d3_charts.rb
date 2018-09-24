module Reporting
  class D3Charts

    def initialize(program_1, program_2)
      @program_1 = program_1
      @program_2 = program_2
    end

    def overview
      # TODO: Are these the dates we want?
      program_1_data = overview_data(@program_1)
      program_2_data = overview_data(@program_2)
      {
        program_1: program_1_data.to_json,
        program_2: program_2_data.to_json,
        both: (program_1_data + program_2_data).to_json
      }
    end

    def outcomes
      # TODO: this is placeholder data
      outcome_1_data = [{outcome: 'exited to other institution', count: 839}, {outcome: 'returned to shelter', count: 1112}, {outcome: 'successful exit to PH', count: 2814}, {outcome: 'unknown outcome', count: 4044}]
      outcome_2_data = [{outcome: 'exited to other institution', count: 34}, {outcome: 'returned to shelter', count: 9}, {outcome: 'successful exit to PH', count: 72}, {outcome: 'unknown outcome', count: 74}]
      {
        program_1: outcome_1_data.to_json,
        program_2: outcome_2_data.to_json
      }
    end

    def shelter_returns
      sr_1_data = [{discrete: 'Less than 1 week', count: 154}, {discrete: '1 week to one month', count: 63}, {discrete: '1 month to 3 months', count: 133}, {discrete: '3 months to 6 months', count: 107}, {discrete: '3 months to 1 year', count: 105}, {discrete: '1 year to 2 years', count: 47}]
      sr_2_data = [{discrete: 'Less than 1 week', count: 1}, {discrete: '1 month to 3 months', count: 1}, {discrete: '3 months to 6 months', count: 1}]
      x_bands = ['Less than 1 week', '1 week to one month', '1 month to 3 months', '3 months to 6 months', '3 months to 1 year', '1 year to 2 years', '2 years or more']
      {
        program_1: sr_1_data,
        program_2: sr_2_data,
        both: (sr_1_data + sr_2_data),
        x_bands: x_bands
      }.to_json
    end

    private

    def overview_data(program)
      start_date = DateTime.new(2012, 1, 1)
      end_date = DateTime.new(2018, 8, 1)
      housed_scope(program).order('housed_date').
        where('month_year > ?', start_date).
        where('month_year < ?', end_date).
        group_by(&:month_year).map do |k, v| 
          {month_year: k, n_clients: v.uniq(&:client_id).size}
        end
    end

    def housed_scope(program)
      if program.present?
        Reporting::Housed.where(residential_project: program)
      else
        Reporting::Housed.all
      end
    end

  end
end