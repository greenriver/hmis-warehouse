###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Measure 2a and 2b: The Extent to which Persons Who Exit Homelessness
# to Permanent Housing Destinations Return to Homelessness within 6, 12,
# and 24 months.
module HudSpmReport::Generators::Fy2023
  class MeasureFive < MeasureBase
    def self.question_number
      'Measure 5'.freeze
    end

    def self.table_descriptions
      {
        'Measure 5' => 'Number of Persons who Become Homeless for the First Time',
        '5.1' => 'Change in the number of persons entering ES, SH, and TH projects with no prior enrollments in HMIS',
        '5.2' => 'Change in the number of persons entering ES, SH, TH, and PH projects with no prior enrollments in HMIS',
      }.freeze
    end

    def run_question!
      tables = [
        ['5.1', :run_5_1],
        ['5.2', :run_5_2],
      ]

      @report.start(self.class.question_number, tables.map(&:first))

      tables.each do |name, msg|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    COLUMNS = {
      'B' => 'Previous FY',
      'C' => 'Current FY',
      'D' => 'Difference',
    }.freeze

    private def run_5_1(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Person with entries into ES-EE, ES-NbN, SH, or TH during the reporting period.',
          3 => 'Of persons above, count those who were in ES-EE, ES-NbN, SH, TH, or any PH within 24 months prior to their start during the reporting year.',
          4 => 'Of persons above, count those who did not have entries in ES-EE, ES-NbN, SH, TH or PH in the previous 24 months. (i.e. number of persons experiencing homelessness for the first time)',
        },
        COLUMNS,
      )
    end

    private def run_5_2(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Person with entries into ES-EE, ES-NbN, SH, TH or PH during the reporting period.',
          3 => 'Of persons above, count those who were in ES-EE, ES-NbN, SH, TH, or any PH within 24 months prior to their start during the reporting year.',
          4 => 'Of persons above, count those who did not have entries in ES-EE, ES-NbN, SH, TH or PH in the previous 24 months. (i.e. number of persons experiencing homelessness for the first time)',
        },
        COLUMNS,
      )
    end
  end
end
