###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Number of Homeless Persons
module HudSpmReport::Generators::Fy2020
  class MeasureThree < Base
    def self.question_number
      'Measure 3'.freeze
    end

    def run_question!
      tables = [
        ['3.1', :run_3_1, 'Change in PIT counts of sheltered and unsheltered homeless persons'],
        ['3.2', :run_3_2, 'Change in annual counts of sheltered homeless persons in HMIS'],
      ]
      @report.start(self.class.question_number, tables.map(&:first))

      tables.each do |name, msg, _title|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    private def run_3_1(table_name)
      universe_members = universe.members.none

      prepare_table table_name, {
        2 => 'Universe: Total PIT Count of sheltered and unsheltered persons',
        3 => 'Emergency Shelter Total',
        4 => 'Safe Haven Total',
        5 => 'Transitional Housing Total',
        6 => 'Total Sheltered Count',
        7 => 'Unsheltered Count',
      }, {
        'B' => 'Previous FY PIT Count',
        'C' => 'Current FY PIT Count',
        'D' => 'Difference',
      }

      handle_clause_based_cells table_name, [
        ['C2', universe_members, universe_members.count],
      ]
    end

    private def run_3_2(table_name)
      universe_members = universe.members.none

      prepare_table table_name, {
        2 => 'Universe: Unduplicated Total sheltered homeless persons',
        3 => 'Emergency Shelter Total',
        4 => 'Safe Haven Total',
        5 => 'Transitional Housing Total',
      }, {
        'B' => 'Previous FY',
        'C' => 'Current FY',
        'D' => 'Difference',
      }

      handle_clause_based_cells table_name, [
        ['C2', universe_members, universe_members.count],
      ]
    end
  end
end
