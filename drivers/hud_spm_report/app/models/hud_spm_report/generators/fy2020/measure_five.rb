###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Measure 5: Number of Persons who Become Homeless for the First Time
module HudSpmReport::Generators::Fy2020
  class MeasureFive < Base
    def self.question_number
      'Measure 5'.freeze
    end

    def run_question!
      tables = [
        ['5.1', :run_5_1, 'Change in the number of persons entering ES, SH, and TH projects with no prior enrollments in HMIS'],
        ['5.2', :run_5_2, 'Change in the number of persons entering ES, SH, TH, and PH projects with no prior enrollments in HMIS'],
      ]
      @report.start(self.class.question_number, tables.map(&:first))

      universe

      tables.each do |name, msg, _title|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    COLS = {
      'B' => 'Previous FY',
      'C' => 'Current FY',
      'D' => 'Difference',
    }.freeze

    private def run_5_1(table_name)
      run_5_x(table_name, ES + SH + TH, 'Person with entries into ES, SH, or TH during the reporting period.')
    end

    private def run_5_2(table_name)
      run_5_x(table_name, ES + SH + TH + PH, 'Person with entries into ES, SH, TH or PH during the reporting period.')
    end

    private def run_5_x(table_name, _project_types, universe_desc)
      first_timers = <<~TXT
        Of persons above, count those who did not have entries in ES, SH, TH or PH in the
        previous 24 months. (i.e. Number of persons experiencing homelessness for the first time)
      TXT
      repeaters = <<~TXT
        Of persons above, count those who were in ES, SH, TH or any PH
        within 24 months prior to their start during the reporting year.
      TXT

      prepare_table table_name, {
        2 => "Universe: #{universe_desc}",
        3 => repeaters,
        4 => first_timers,
      }, COLS

      # FIXME
      c2 = []
      c3 = []

      handle_clause_based_cells table_name, [
        ['C2', c2, c2.count],
        ['C3', c3, c2.count],
        ['C4', c2 - c3, c2.count - c3.count],
      ]
    end
  end
end
