###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPit::Generators::Pit::Fy2022
  class AdditionalHomelessPopulations < Base
    QUESTION_NUMBER = 'Additional Homeless Populations'.freeze

    # Only relevant to adults
    def self.filter_pending_associations(pending_associations)
      pending_associations.select { |_, row| row[:age].present? && row[:age] >= 18 }
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
        :adults_with_mental_illness,
        :adults_with_mental_illness_indefinite,
        :adults_with_substance_use,
        :adults_with_substance_use_indefinite,
        :adults_with_hiv,
        :adults_with_hiv_indefinite,
        :adult_dv_survivors,
        :adult_dv_survivors_currently_fleeing,
      ]
    end

    private def calculate
      table_name = QUESTION_NUMBER
      metadata = {
        header_row: [
          'Additional Homeless Populations',
          'Emergency',
          'Transitional',
          'Safe Haven',
          'Outreach',
        ],
        row_labels: row_labels,
        first_column: 'B',
        last_column: 'E',
        first_row: 2,
        last_row: 9,
      }
      populate_table(table_name, metadata)
    end
  end
end
