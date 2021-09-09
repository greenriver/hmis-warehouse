###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Measure 4: Employment and Income Growth for Homeless Persons in CoC Program–funded Projects
module HudSpmReport::Generators::Fy2021
  class MeasureFour < Base
    def self.question_number
      'Measure 4'.freeze
    end

    def self.tables
      [
        ['4.1', :run_4_1, 'Change in earned income for adult system stayers during the reporting period'],
        ['4.2', :run_4_2, 'Change in non-employment cash income for adult system stayers during the reporting period'],
        ['4.3', :run_4_3, 'Change in total income for adult system stayers during the reporting period'],
        ['4.4', :run_4_4, 'Change in earned income for adult system leavers'],
        ['4.5', :run_4_5, 'Change in non-employment cash income for adult system leavers'],
        ['4.6', :run_4_6, 'Change in earned income for adult system stayers during the reporting period'],
      ]
    end

    def self.table_descriptions
      {
        'Measure 4' => 'Employment and Income Growth for Homeless Persons in CoC Program–funded Projects',
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

    ROWS = {
      2 => 'Universe: Number of adults who exited (system leavers)',
      3 => 'Number of adults who exited with increased earned income',
      4 => 'Percentage of adults who increased earned income',
    }.freeze

    private def spmc_t
      HudSpmReport::Fy2020::SpmClient.arel_table
    end

    private def run_4_1(table_name)
      run_4_x table_name, true, spmc_t[:m4_latest_earned_income].gt(spmc_t[:m4_earliest_earned_income])
    end

    private def run_4_2(table_name)
      run_4_x table_name, true, spmc_t[:m4_latest_non_earned_income].gt(spmc_t[:m4_earliest_non_earned_income])
    end

    private def run_4_3(table_name)
      run_4_x table_name, true, spmc_t[:m4_latest_income].gt(spmc_t[:m4_earliest_income])
    end

    private def run_4_4(table_name)
      run_4_x table_name, false, spmc_t[:m4_latest_earned_income].gt(spmc_t[:m4_earliest_earned_income])
    end

    private def run_4_5(table_name)
      run_4_x table_name, false, spmc_t[:m4_latest_non_earned_income].gt(spmc_t[:m4_earliest_non_earned_income])
    end

    private def run_4_6(table_name)
      run_4_x table_name, false, spmc_t[:m4_latest_income].gt(spmc_t[:m4_earliest_income])
    end

    private def run_4_x(table_name, stayer, income_change_clause)
      prepare_table(table_name, ROWS, CHANGE_TABLE_COLS)

      universe_members = universe.members.where(t[:m4_stayer].eq(stayer))
      with_increased_income = universe_members.where(income_change_clause)

      handle_clause_based_cells table_name, [
        ['C2', universe_members, universe_members.count],
        ['C3', with_increased_income, with_increased_income.count],
        ['C4', [], report_precentage(with_increased_income.count, universe_members.count)],
      ]
    end
  end
end
