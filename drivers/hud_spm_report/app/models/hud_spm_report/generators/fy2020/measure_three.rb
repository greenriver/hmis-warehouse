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

    def self.tables
      [
        ['3.1', :run_3_1, 'Change in PIT counts of sheltered and unsheltered homeless persons'],
        ['3.2', :run_3_2, 'Change in annual counts of sheltered homeless persons in HMIS'],
      ].freeze
    end

    def self.table_descriptions
      {
        'Measure 3' => 'Number of Homeless Persons',
      }.merge(
        tables.map do |table|
          [table.first, table.last]
        end.to_h,
      ).freeze
    end

    def run_question!
      @report.start(self.class.question_number, tables.map(&:first))

      tables.each do |name, msg, _title|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    private def run_3_1(table_name)
      # 1. Metric 3.1 - Counts of clients using PIT count data. This data should be manually entered from the appropriate point-in-time count data previously
      # submitted. Due to ever-changing data, it is often difficult or impossible to run the same query months later and return the same results. Thus, this
      # metric is not intended to be programmed into the HMIS as part of the System Performance Measures report.

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

      # Per tha above -- We provide only an empty shell
      handle_clause_based_cells table_name, [
        ['C2'],
        ['C3'],
        ['C4'],
        ['C5'],
        ['C6'],
        ['C7'],
      ]
    end

    private def run_3_2(table_name)
      # Metric 3.2 - Counts of clients using HMIS data. Using HMIS data, determine the
      # unduplicated counts of active clients for each of the project types throughout
      # the reporting period:

      # We don't need to check this since universe filters
      # for us but an explicit check would be:
      # `where(['m3_active_project_types && ARRAY[?]', ES+SH+TH])`
      universe_members = universe.members
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

      {
        2 => universe_members,
        3 => universe_members.where(['m3_active_project_types @> ARRAY[?]', ES]),
        4 => universe_members.where(['m3_active_project_types @> ARRAY[?]', SH]),
        5 => universe_members.where(['m3_active_project_types @> ARRAY[?]', TH]),
      }.each do |row, scope|
        handle_clause_based_cells table_name, [
          ["C#{row}", scope, scope.count],
        ]
      end
    end
  end
end
