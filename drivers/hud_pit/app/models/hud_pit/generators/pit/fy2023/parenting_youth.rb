###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPit::Generators::Pit::Fy2023
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

    private def sub_calculations
      calcs = super
      # The following calculations should only be run for the HoH for parenting youth
      # per HUD guidance from 11/2021
      [
        :female,
        :male,
        :no_single_gender,
        :questioning,
        :transgender,
        :non_latino,
        :latino,
        :native_ak,
        :asian,
        :native_pi,
        :black_af_american,
        :white,
        :multi_racial,
      ].each do |key|
        calcs[key][:query] = calcs[key][:query].and(hoh_clause)
      end
      calcs
    end

    private def rows
      [
        :households,
        :clients,
        :hoh_for_youth,
        :children_of_youth_parents,
        :child_hoh,
        :children_of_0_to_18_parents,
        :youth_hoh,
        :children_of_18_to_24_parents,
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
        last_row: rows.count + 1,
      }
      populate_table(table_name, metadata)
    end
  end
end
