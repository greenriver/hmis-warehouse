###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPit::Generators::Pit::Fy2022
  class ParentingYouth < Base
    QUESTION_NUMBER = 'Parenting Youth Households'.freeze

    def self.filter_pending_associations(pending_associations)
      pending_associations.select { |_, row| row[:max_age].present? && row[:max_age] < 25 && row[:household_type].to_s == 'adults_and_children' }
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
        :hoh_for_youth,
        :child_hoh,
        :youth_hoh,
        :children_of_youth_parents,
        :female,
        :male,
        :transgender,
        :gender_other,
        :non_latino,
        :latino,
        :white,
        :black,
        :asian,
        :native_ak,
        :native_pi,
        :multi_racial,
        :chronic_households,
        :chronic_clients,
      ]
    end

    private def calculate
      table_name = QUESTION_NUMBER
      metadata = {
        header_row: [
          'Parenting Youth Households',
          'Emergency',
          'Transitional',
          'Outreach',
        ],
        row_labels: row_labels,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 21,
      }
      populate_table(table_name, metadata)
    end
  end
end
