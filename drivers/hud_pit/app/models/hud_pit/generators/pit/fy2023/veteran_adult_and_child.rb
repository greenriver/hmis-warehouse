###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPit::Generators::Pit::Fy2023
  class VeteranAdultAndChild < Base
    QUESTION_NUMBER = 'Veteran Households with at least one Adult & one Child'.freeze

    def self.filter_pending_associations(pending_associations)
      pending_associations.select { |_, row| row[:hoh_veteran] && row[:household_type].to_s == 'adults_and_children' }
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
        :veterans,
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
        :chronic_households,
        :chronic_clients,
      ]
    end

    private def row_limits
      (5..19).map do |i|
        [i, a_t[:veteran].eq(true)]
      end.to_h
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
