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