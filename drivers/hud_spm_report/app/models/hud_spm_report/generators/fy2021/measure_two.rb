###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Measure 2a and 2b: The Extent to which Persons Who Exit Homelessness
# to Permanent Housing Destinations Return to Homelessness within 6, 12,
# and 24 months.
module HudSpmReport::Generators::Fy2021
  class MeasureTwo < Base
    def self.question_number
      'Measure 2'.freeze
    end

    def self.table_descriptions
      {
        'Measure 2' => 'The Extent to which Persons Who Exit Homelessness to Permanent Housing Destinations Return to Homelessness within 6, 12, and 24 months',
      }.freeze
    end

    def run_question!
      table_name = '2'

      @report.start(self.class.question_number, [table_name])

      exit_project_types = SO + ES + TH + SH + PH
      universe_members = universe.members.where(t[:m2_exit_from_project_type].in(exit_project_types))

      prepare_table table_name, {
        2 => 'Exit was from SO',
        3 => 'Exit was from ES',
        4 => 'Exit was from TH',
        5 => 'Exit was from SH',
        6 => 'Exit was from PH',
        7 => 'TOTAL Returns to Homeless',
      }, {
        'B' => 'Total Number of Persons who Exited to a Permanent Housing Destination (2 Years Prior)',
        'C' => 'Number Returning to Homelessness in Less than 6 Months (0 - 180 days)',
        'D' => 'Percentage of Returns in Less than 6 Months (0 - 180 days)',
        'E' => 'Number Returning to Homelessness from 6 to 12 Months (181 - 365 days)',
        'F' => 'Percentage of Returns from 6 to 12 Months (181 - 365 days)',
        'G' => 'Number Returning to Homelessness from 13 to 24 Months (366 - 730 days)',
        'H' => 'Percentage of Returns from 13 to 24 Months (366 - 730 days)',
        'I' => 'Number of Returns in 2 Years',
        'J' => 'Percentage of Returns in 2 Years',
      }

      # 7. Since each client may only be reported no more than once in columns
      # C, E, or G, each cell in column I is simply a sum of cells in the same
      # row. This is indicated in the above table shell with a simple formula.
      #
      # 8. Since each client may only be reported on one row (2, 3, 4, 5, or
      # 6), cells B, C, E, and G in row 7 are simply a sum of the rows above.
      # This is also indicated with a simple formula.
      #
      # 9. Columns D, F, H, andJ are the percentages of clients who exited to a
      # permanent housing destination but later returned to homelessness. This
      # is also indicated with a simple formula. HMIS systems should calculate
      # these percentages to 2 decimal  places.
      {
        2 => SO,
        3 => ES,
        4 => TH,
        5 => SH,
        6 => PH,
        7 => SO + ES + TH + SH + PH,
      }.each do |row, project_types|
        scope = universe_members.where(t[:m2_exit_from_project_type].in(project_types))
        exited = scope
        n_exited = exited.count
        if n_exited.positive?
          reentered_0_5 = scope.where(t[:m2_reentry_days].between(1 .. 180))
          reentered_6_12 = scope.where(t[:m2_reentry_days].between(181 .. 365))
          reentered_13_24 = scope.where(t[:m2_reentry_days].between(366 .. 730))
          reentered = scope.where(t[:m2_reentry_days].between(1 .. 730))
        else
          reentered_0_5 = scope.none
          reentered_6_12 = scope.none
          reentered_13_24 = scope.none
          reentered = scope.none
        end

        handle_clause_based_cells table_name, [
          ["B#{row}", exited, exited.count],
          ["C#{row}", reentered_0_5, reentered_0_5.count],
          ["D#{row}", [], report_precentage(reentered_0_5.count, n_exited)],
          ["E#{row}", reentered_6_12, reentered_6_12.count],
          ["F#{row}", [], report_precentage(reentered_6_12.count, n_exited)],
          ["G#{row}", reentered_13_24, reentered_13_24.count],
          ["H#{row}", [], report_precentage(reentered_13_24.count, n_exited)],
          ["I#{row}", reentered, reentered.count],
          ["J#{row}", [], report_precentage(reentered.count, n_exited)],
        ]
      end

      @report.complete(self.class.question_number)
    end
  end
end
