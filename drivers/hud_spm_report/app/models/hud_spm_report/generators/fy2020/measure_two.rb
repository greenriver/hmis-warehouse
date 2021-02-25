###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Generators::Fy2020
  class MeasureTwo < Base
    def self.question_number
      'Measure 2'.freeze
    end

    def run_question!
      table_name = '2'

      @report.start(self.class.question_number, table_name)

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

      {
        2 => SO,
        3 => ES,
        4 => TH,
        5 => SH,
        6 => PH,
        7 => SO + ES + TH + SH + PH,
      }.each do |row, project_types|
        scope = universe_members.where(t[:m2_exit_from_project_type].in(project_types))
        n_exited = scope.count
        n_reentered_0_6 = scope.where(t[:m2_reentry_days].between(1 .. 180)).count
        n_reentered_6_12 = scope.where(t[:m2_reentry_days].between(181 .. 365)).count
        n_reentered_12_24 = scope.where(t[:m2_reentry_days].between(366 .. 730)).count
        n_reentered = n_reentered_0_6 + n_reentered_6_12 + n_reentered_12_24

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

        handle_clause_based_cells table_name, [
          ["B#{row}", universe_members, n_exited],
          ["C#{row}", universe_members, n_reentered_0_6],
          ["D#{row}", universe_members, m2_precentage(n_reentered_0_6, n_exited)],
          ["E#{row}", universe_members, n_reentered_6_12],
          ["F#{row}", universe_members, m2_precentage(n_reentered_6_12, n_exited)],
          ["G#{row}", universe_members, n_reentered_12_24],
          ["F#{row}", universe_members, m2_precentage(n_reentered_12_24, n_exited)],
          ["I#{row}", universe_members, n_reentered],
          ["J#{row}", universe_members, m2_precentage(n_reentered, n_exited)],
        ]
      end

      @report.complete(self.class.question_number)
    end

    private def m2_precentage(numerator, denominator)
      return 0 if denominator.zero?

      (numerator * 100.0 / denominator).round(2)
    end
  end
end
