###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Measure 5: Number of Persons who Become Homeless for the First Time
module HudSpmReport::Generators::Fy2020
  class MeasureFive < Base
    def self.question_number
      'Measure 5'.freeze
    end

    def self.tables
      [
        ['5.1', :run_5_1, 'Change in the number of persons entering ES, SH, and TH projects with no prior enrollments in HMIS'],
        ['5.2', :run_5_2, 'Change in the number of persons entering ES, SH, TH, and PH projects with no prior enrollments in HMIS'],
      ]
    end

    def self.table_descriptions
      {
        'Measure 5' => 'Number of Persons who Become Homeless for the First Time',
      }.merge(
        tables.map do |table|
          [table.first, table.last]
        end.to_h,
      ).freeze
    end

    def run_question!
      @report.start(self.class.question_number, self.class.tables.map(&:first))

      self.class.tables.each do |name, msg, _title|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    private def run_5_1(table_name)
      run_5_x(table_name, ES + SH + TH, 'Person with entries into ES, SH, or TH during the reporting period.')
    end

    private def run_5_2(table_name)
      run_5_x(table_name, ES + SH + TH + PH, 'Person with entries into ES, SH, TH or PH during the reporting period.')
    end

    private def run_5_x(table_name, project_types, universe_desc)
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
      }, CHANGE_TABLE_COLS

      c2 = universe.members.where(['m5_active_project_types && ARRAY[?]', project_types])
      c3 = c2.where(['m5_recent_project_types && ARRAY[?]', ES + SH + TH + PH])

      handle_clause_based_cells table_name, [
        ['C2', c2, c2.count],
        ['C3', c3, c3.count],
        ['C4', c2 - c3, c2.count - c3.count],
      ]
    end
  end
end
