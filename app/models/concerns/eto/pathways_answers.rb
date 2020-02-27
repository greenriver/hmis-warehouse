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
        # 2/17/2020
        # Total boston pathways assessment score
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('scoring - only')
        answer_from_section(relevant_section, 'pathways assessment score')&.to_i
      end

      def staff_email_answer
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('elements needed for assessor')
        answer_from_section(relevant_section, 'assessor email')
      end

      def rrh_desired_answer
        # 2/17/2020
        # 9A
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Why do people take RRH')
        answer_from_section(relevant_section, '9A.')&.downcase == 'yes'
      end

      def youth_rrh_desired_answer
        # 2/17/2020
        # 9C
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Why do people take RRH')
        answer_from_section(relevant_section, '9C.')&.downcase == 'yes'
      end

      def rrh_th_desired_answer
        # 2/17/2020
        # 9F
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Why do people take RRH')
        answer_from_section(relevant_section, '9F.')&.downcase == 'yes'
      end

      def income_maximization_assistance_requested_answer
        # 2/17/2020
        # 10C
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Key Points to Share with the Participant Regarding Household History')
        answer_from_section(relevant_section, '10C.')&.downcase == 'yes'
      end

      def income_total_annual_answer
        # 2/17/2020
        # 6A
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Key Points to Share with the Participant Regarding Unit Preferences')
        answer_from_section(relevant_section, '6A.')&.to_i
      end

      def pending_subsidized_housing_placement_answer
        # 2/17/2020
        # 5D
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Section 5 - Household Composition')
        answer_from_section(relevant_section, '5D.')&.downcase == 'yes'
      end

      def domestic_violence_answer
        # 2/17/2020
        # 2B
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Key Points to Share with the Participant regarding Safety & Urgent Health Conditions')
        answer_from_section(relevant_section, '2b.')&.downcase == 'yes'
      end

      def interested_in_set_asides_answer
        # 2/17/2020
        # 6I
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('6I.')
        answer_from_section(relevant_section, 'I confirm my interest in signing up for the homeless set aside units')&.downcase == 'yes'
      end

      def required_number_of_bedrooms_answer
        # 2/17/2020
        # 6C
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Key Points to Share with the Participant Regarding Unit Preferences')
        answer_from_section(relevant_section, '6c.')&.to_i
      end

      def required_minimum_occupancy_answer
        # 2/17/2020
        # FIXME: this may be unnecessary
      end

      def requires_wheelchair_accessibility_answer
        # 2/17/2020
        # 6D
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Key Points to Share with the Participant Regarding Unit Preferences')
        answer_from_section(relevant_section, '6d.')&.downcase&.include?('wheelchair') || false
      end

      def requires_elevator_access_answer
        # 2/17/2020
        # 6D
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Key Points to Share with the Participant Regarding Unit Preferences')
        answer_from_section(relevant_section, '6D.')&.downcase&.include?('elevator') || false
      end

      def youth_rrh_aggregate_answer
        # 2/17/2020
        # 9C
        return nil unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Why do people take RRH instead of waiting for a subsidized housing unit like a Section 8 voucher?')
        answer = answer_from_section(relevant_section, '9c.')
        return nil if answer.blank?

        case answer.downcase
        when answer.starts_with?('Youth-Specific Only')
          'youth'
        when answer.starts_with?('Adult Programs Only')
          'adult'
        when answer.starts_with?('Both Adult')
          'both'
        end
      end

      def dv_rrh_aggregate_answer
        # 2/17/2020
        # 9D
        return nil unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Why do people take RRH instead of waiting for a subsidized housing unit like a Section 8 voucher?')
        answer = answer_from_section(relevant_section, '9d.')
        return nil unless answer

        case answer.downcase
        when answer.starts_with?('Domestic Violence')
          'dv'
        when answer.starts_with?('Non-DV Programs Only')
          'non-dv'
        when answer.starts_with?('Both DV')
          'both'
        end
      end

      # def veteran_rrh_desired_answer

      # end

      def sro_ok_answer
        # 2/17/2020
        # 6B
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Key Points to Share with the Participant Regarding Unit Preferences')
        answer_from_section(relevant_section, '6b.')&.downcase == 'yes'
      end

      def other_accessibility_answer
        # 2/17/2020
        # 6D
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Key Points to Share with the Participant Regarding Unit Preferences')
        answer_from_section(relevant_section, '6d.')&.downcase&.include?('other accessibility') || false
      end

      def disabled_housing_answer
        # 2/17/2020
        # 6G
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Key Points to Share with the Participant Regarding Unit Preferences')
        answer_from_section(relevant_section, '6g.')&.downcase == 'yes'
      end

      def evicted_answer
        # 2/17/2020
        # 10B
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Key Points to Share with the Participant Regarding Household History')
        answer_from_section(relevant_section, '10B.')&.downcase == 'yes'
      end

      def neighborhood_interests_answer
        # 2/17/2020
        # 6H
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Key Points to Share with the Participant Regarding Unit Preferences')
        answer_from_section(relevant_section, '6h.')&.split('|')&.map(&:presence)&.compact
      end

      # def pathways_dv_score_answer
      #   # Dv priority score
      #   # FIXME: this may be unecessary
      # end

      # def pathways_length_of_time_homeless_score_answer
      #   # Length of time homeless in 3 years score
      #   # FIXME: this may be unecessary
      # end
    end
  end
end
