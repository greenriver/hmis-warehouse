###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudPit::Generators::Pit::Fy2025
  class AdultAndChild < Base
    QUESTION_NUMBER = 'Adult & Child (at least one adult and one child)'

    def self.filter_pending_associations(pending_associations)
      pending_associations.select { |_, row| row[:household_type].to_s == 'adults_and_children' }
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
        project_type_so_clause,
      ]
    end

    private def rows
      [
        :households,
        :clients,
        :children,
        :youth,
        :age_25_34,
        :age_35_44,
        :age_45_54,
        :age_55_64,
        :age_over_64,
        :native_ak,
        :native_ak_latino,
        :asian,
        :asian_latino,
        :black_af_american,
        :black_af_american_latino,
        :latino_only,
        :mid_east_na,
        :mid_east_na_latino,
        :native_pi,
        :native_pi_latino,
        :white,
        :white_latino,
        :multi_racial_latino,
        :multi_racial,
        :chronic_households,
        :chronic_clients,
      ]
    end

    private def calculate
      table_name = QUESTION_NUMBER
      metadata = {
        header_row: [
          'Persons in Households with at least one Adult and one Child',
          'Emergency',
          'Transitional',
          'Outreach',
        ],
        row_labels: row_labels,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: rows.count + 1,
      }
      populate_table(table_name, metadata)
    end
  end
end
