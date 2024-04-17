###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPit::Generators::Pit::Fy2024
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
      # Updated 4/2024 to include both HoH and spouse clients per the following guidance
      # •	HUD Notice CPD-2023-11: “Parenting youth are youth who identify as the parent or legal guardian of one or more children who are present with or sleeping in the same place as that youth parent, where there is no person over age 24 in the household”. “CoCs must report data on persons in Youth Households, including the gender, race, and ethnicity for parenting youth and unaccompanied youth, as outlined in Appendix C. However, while gender, race, and ethnicity are reported for all unaccompanied youth, CoCs will only report the gender, race, and ethnicity on the parents in the parenting youth households.”
      # •	Also, Appendix C to HUD Notice CPD-2023-11shows who should be counted for each item. Throughout the categories for Gender and Race/Ethnicity, it indicates that the data collection is for “youth parents only”. In other places HUD refers for “Head of Household” and HUD didn’t use that language here.
      [
        :woman,
        :man,
        :culturally_specific_identity,
        :transgender,
        :non_binary,
        :questioning,
        :different_identity,
        :more_than_one_gender,
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
      ].each do |key|
        calcs[key][:query] = calcs[key][:query].and(hoh_or_spouse)
      end
      calcs
    end

    private def rows
      [
        :households,
        :clients,
        :hoh_for_youth, # HoH or spouse/partner (RelationshipToHoH = 3)
        :children_of_youth_parents,
        :child_hoh,
        :children_of_0_to_18_parents, # HoH or spouse/partner (RelationshipToHoH = 3)
        :youth_hoh,
        :children_of_18_to_24_parents, # HoH or spouse/partner (RelationshipToHoH = 3)
        :woman,
        :man,
        :culturally_specific_identity,
        :transgender,
        :non_binary,
        :questioning,
        :different_identity,
        :more_than_one_gender,
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
        :multi_racial,
        :multi_racial_latino,
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
