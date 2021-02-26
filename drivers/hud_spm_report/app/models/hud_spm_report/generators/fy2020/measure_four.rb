###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Generators::Fy2020
  class MeasureFour < Base
    def self.question_number
      'Measure 4'.freeze
    end

    def run_question!
      tables = [
        ['4.1', :run_4_1, 'Change in earned income for adult system stayers during the reporting period'],
        ['4.2', :run_4_2, 'Change in non-employment cash income for adult system stayers during the reporting period'],
        ['4.3', :run_4_3, 'Change in total income for adult system stayers during the reporting period'],
        ['4.4', :run_4_4, 'Change in earned income for adult system leavers'],
        ['4.5', :run_4_5, 'Change in non-employment cash income for adult system leavers'],
        ['4.6', :run_4_6, 'Change in earned income for adult system stayers during the reporting period'],
      ]
      @report.start(self.class.question_number, tables.map(&:first))

      tables.each do |name, msg, _title|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    FUNDING_SOURCES = [2, 3, 4, 5, 43, 44].freeze

    ROWS = {
      2 => 'Universe: Number of adults who exited (system leavers)',
      3 => 'Number of adults who exited with increased earned income',
      4 => 'Percentage of adults who increased earned income',
    }.freeze

    COLS = {
      'B' => 'Previous FY',
      'C' => 'Current FY',
      'D' => 'Difference',
    }.freeze

    private def run_4_1(table_name)
      run_4_x table_name, [], []
    end

    private def run_4_2(table_name)
      run_4_x table_name, [], []
    end

    private def run_4_3(table_name)
      run_4_x table_name, [], []
    end

    private def run_4_4(table_name)
      run_4_x table_name, [], []
    end

    private def run_4_5(table_name)
      run_4_x table_name, [], []
    end

    private def run_4_6(table_name)
      run_4_x table_name, [], []
    end

    private def run_4_x(table_name, adult_leavers, with_increased_income)
      prepare_table table_name, ROWS, COLS
      handle_clause_based_cells table_name, [
        ['C2', adult_leavers, adult_leavers.count],
        ['C3', with_increased_income, with_increased_income.count],
        ['C4', [], report_precentage(with_increased_income.count, adult_leavers.count)],
      ]
    end
  end
end
