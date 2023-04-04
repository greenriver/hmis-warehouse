###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPit::Generators::Pit::Fy2023
  class UnaccompaniedYouth < Base
    QUESTION_NUMBER = 'Unaccompanied Youth'.freeze

    def self.filter_pending_associations(pending_associations)
      pending_associations.select { |_, row| row[:max_age].present? && row[:max_age] < 25 && row[:household_type].to_s == 'adults_only' }
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_NUMBER])

      calculate

      @report.complete(QUESTION_NUMBER)
    end

    private def project_types
      [
        project_type_es_clause,
        project_type_th_clause,
        project_type_sh_clause,
        project_type_so_clause,
      ]
    end

    private def rows
      [
        :households,
        :clients,
        :children,
        :youth,
        :female,
        :male,
        :no_single_gender,
        :questioning,
        :transgender,
        :non_latino,
        :latino,
        :native_ak,
        :asian,
        :black_af_american,
        :native_pi,
        :white,
        :multi_racial,
        :chronic_clients,
      ]
    end

    private def calculate
      table_name = QUESTION_NUMBER
      metadata = {
        header_row: [
          'Unaccompanied Youth Households',
          'Emergency',
          'Transitional',
          'Safe Haven',
          'Outreach',
        ],
        row_labels: row_labels,
        first_column: 'B',
        last_column: 'E',
        first_row: 2,
        last_row: rows.count + 1,
      }
      populate_table(table_name, metadata)
    end
  end
end
