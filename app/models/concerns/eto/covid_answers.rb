###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Eto
  module CovidAnswers
    extend ActiveSupport::Concern
    included do
      def number_of_bedrooms_answer
        return false unless hmis_assessment.covid_19_impact_assessment?

        relevant_section = section_starts_with('PAGE #1. Impact Assessment')
        answer_from_section(relevant_section, 'A-13. How many bedrooms')&.to_i
      end

      def monthly_rent_total_answer
        return false unless hmis_assessment.covid_19_impact_assessment?

        relevant_section = section_starts_with('PAGE #1. Impact Assessment')
        answer_from_section(relevant_section, 'A-15. How much is your total monthly')&.to_i
      end

      def total_subsidy_answer
        return false unless hmis_assessment.covid_19_impact_assessment?

        relevant_section = section_starts_with('PAGE #1. Impact Assessment')
        answer_from_section(relevant_section, 'A-16. What is the total amount of assistance')&.to_i
      end

      def subsidy_months_answer
        return false unless hmis_assessment.covid_19_impact_assessment?

        relevant_section = section_starts_with('PAGE #1. Impact Assessment')
        answer_from_section(relevant_section, 'A-17. How many months of assistance')&.to_i
      end

      def percent_ami_answer
        return false unless hmis_assessment.covid_19_impact_assessment?

        relevant_section = section_starts_with('PAGE #1. Impact Assessment')
        answer_from_section(relevant_section, 'A-12. Household Percentage of Area')
      end

      def household_type_answer
        return false unless hmis_assessment.covid_19_impact_assessment?

        relevant_section = section_starts_with('PAGE #1. Impact Assessment')
        answer_from_section(relevant_section, 'A-10. Household Type')
      end

      def household_size_answer
        return false unless hmis_assessment.covid_19_impact_assessment?

        relevant_section = section_starts_with('PAGE #1. Impact Assessment')
        answer_from_section(relevant_section, 'A-11. How many people are in')&.to_i
      end
    end
  end
end
