###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Eto
  module PathwaysAnswers
    extend ActiveSupport::Concern
    included do
      def assessment_completed_on_answer
        collected_at
      end

      def assessment_score_answer
        nil # FIXME: this does not appear to come through the API at this time.
      end

      def rrh_desired_answer
        # 9C
      end

      def youth_rrh_desired_answer
        # 9C
      end

      def rrh_th_desired_answer
        # 9F
      end

      def rrh_assessment_contact_info_answer
        nil # FIXME: this does not appear to come through the API at this time.
      end

      def income_maximization_assistance_requested_answer
        # 10C

        # relevant_section = answers[:sections].select do |section|
        #   section[:section_title].downcase == 'section 8: housing resource assessment'.downcase
        # end&.first
        # return false unless relevant_section.present?

        # relevant_question = relevant_section[:questions].select do |question|
        #   question[:question].downcase.include? "increase and maximize all income sources"
        # end&.first.try(:[], :answer)
        # relevant_question&.downcase == 'yes' || false
      end

      def income_total_annual_answer
        # 6A
      end

      def pending_subsidized_housing_placement_answer
        # 5D
      end

      def domestic_violence_answer
        # 2B
      end

      def interested_in_set_asides_answer
        # 6I
      end

      def required_number_of_bedrooms_answer
        # 6C
      end

      def required_minimum_occupancy_answer
      end

      def requires_wheelchair_accessibility_answer
        # 6D
      end

      def requires_elevator_access_answer
        # 6D
      end

      def youth_rrh_aggregate_answer
        # 9C
      end

      def dv_rrh_aggregate_answer
        # 9C
      end

      # def veteran_rrh_desired_answer

      # end

      def sro_ok_answer
        # 6B
      end

      def other_accessibility_answer
        # 6D
      end

      def disabled_housing_answer
        # 6G
      end

      def evicted_answer
        # 10B
      end

      def neighborhood_interests_answer
        # 6H
      end
    end
  end
end
