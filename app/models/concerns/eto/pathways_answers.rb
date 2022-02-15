###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
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
        return nil unless hmis_assessment.pathways?

        # relevant_section = section_starts_with('scoring - only')
        # answer_from_section(relevant_section, 'pathways assessment score')&.to_i

        return 0 if ssvf_eligible_answer
        return 0 if !domestic_violence_answer && (days_homeless_in_the_last_three_years_answer.blank? || days_homeless_in_the_last_three_years_answer < 30)
        return 65 if pending_subsidized_housing_placement_answer

        score = 0
        score += 25 if client.DOB.present? && client.age <= 24
        score += if domestic_violence_answer
          15
        else
          case days_homeless_in_the_last_three_years_answer
          when (30..60)
            1
          when (61..90)
            2
          when (91..120)
            3
          when (121..150)
            4
          when (151..180)
            5
          when (181..210)
            6
          when (211..240)
            7
          when (241..269)
            8
          when (270..Float::INFINITY)
            15
          else
            0
          end
        end
        score += 5 if documented_disability_answer
        score += 1 if evicted_answer
        score += 1 if income_maximization_assistance_requested_answer

        score = 1 if score.zero?
        score
      end

      def documented_disability_answer
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Section MM: Key Points')
        answer_from_section(relevant_section, '10A.')&.downcase == 'yes'
      end

      def days_homeless_in_the_last_three_years_answer
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Section M: Key Point')
        answer_from_section(relevant_section, 'R-6. 3C.')&.to_i
      end

      def staff_email_answer
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Section PP: Elements needed for Assessor Info')
        answer_from_section(relevant_section, 'assessor email')
      end

      def client_phones_answer
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('section s: key points to share with the participant regarding contact information')
        answer_from_section(relevant_section, 'S-1. 4A.')
      end

      def client_emails_answer
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('section s: key points to share with the participant regarding contact information')
        answer_from_section(relevant_section, 'S-2.')
      end

      def client_shelters_answer
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('section s: key points to share with the participant regarding contact information')
        answer_from_section(relevant_section, 'S-3. 4C.')
      end

      def client_case_managers_answer
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('section s: key points to share with the participant regarding contact information')
        answer_from_section(relevant_section, 'S-4. 4D.')
      end

      def client_day_shelters_answer
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('section s: key points to share with the participant regarding contact information')
        answer_from_section(relevant_section, 'S-6. 4F.')
      end

      def client_night_shelters_answer
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('section s: key points to share with the participant regarding contact information')
        answer_from_section(relevant_section, 'S-7. 4G.')
      end

      def rrh_desired_answer
        # 2/17/2020
        # 9A
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Section LL: Why do people take RRH')
        answer_from_section(relevant_section, '9A.')&.downcase == 'yes'
      end

      def youth_rrh_desired_answer
        # 2/17/2020
        # 9C
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Section LL: Why do people take RRH')
        answer_from_section(relevant_section, '9C.')&.downcase == 'yes'
      end

      def rrh_th_desired_answer
        # 2/17/2020
        # 9F
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Section LL: Why do people take RRH')
        answer_from_section(relevant_section, '9F.')&.downcase == 'yes'
      end

      def income_maximization_assistance_requested_answer
        # 2/17/2020
        # 10C
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Section MM: Key Points to Share with the Participant Regarding Household History')
        answer_from_section(relevant_section, '10C.')&.downcase == 'yes'
      end

      def income_total_annual_answer
        # 2/17/2020
        # 6A
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Section Y: Key Points to Share with the Participant Regarding Unit Preferences')
        answer_from_section(relevant_section, '6A.')&.to_i
      end

      def pending_subsidized_housing_placement_answer
        # 2/17/2020
        # 5D
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('PAGE #7. Section 5 - Household Composition/Pending Housing')
        answer_from_section(relevant_section, '5D.')&.downcase == 'yes'
      end

      def domestic_violence_answer
        # 2/17/2020
        # 2B
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Section L: Key Points to Share with the Participant regarding Safety & Urgent Health Conditions')
        answer_from_section(relevant_section, '2b.')&.downcase == 'yes'
      end

      def interested_in_set_asides_answer
        # 2/17/2020
        # 6I
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Section Z: 6I. Confirm Interest in Signing Up for Homeless Set-Aside Units')
        answer_from_section(relevant_section, 'I confirm my interest in signing up for the homeless set aside units')&.downcase == 'yes'
      end

      def required_number_of_bedrooms_answer
        # 2/17/2020
        # 6C
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Section Y: Key Points to Share with the Participant Regarding Unit Preferences')
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

        relevant_section = section_starts_with('Section Y: Key Points to Share with the Participant Regarding Unit Preferences')
        answer_from_section(relevant_section, '6d.')&.downcase&.include?('wheelchair') || false
      end

      def requires_elevator_access_answer
        # 2/17/2020
        # 6D
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Section Y: Key Points to Share with the Participant Regarding Unit Preferences')
        answer_from_section(relevant_section, '6D.')&.downcase&.include?('elevator') || false
      end

      def youth_rrh_aggregate_answer
        # 2/17/2020
        # 9C
        return nil unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Section LL: Why do people take RRH instead of waiting for a subsidized housing unit like a Section 8 voucher?')
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

        relevant_section = section_starts_with('Section LL: Why do people take RRH instead of waiting for a subsidized housing unit like a Section 8 voucher?')
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

      def ssvf_eligible_answer
        # 3/7/2020
        # V.1
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('PAGE #9')
        answer_from_section(relevant_section, 'Z-6. V.1 Would')&.downcase&.starts_with?('yes') || false
      end

      def sro_ok_answer
        # 2/17/2020
        # 6B
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Section Y: Key Points to Share with the Participant Regarding Unit Preferences')
        answer_from_section(relevant_section, '6b.')&.downcase == 'yes'
      end

      def other_accessibility_answer
        # 2/17/2020
        # 6D
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Section Y: Key Points to Share with the Participant Regarding Unit Preferences')
        answer_from_section(relevant_section, '6d.')&.downcase&.include?('other accessibility') || false
      end

      def disabled_housing_answer
        # 2/17/2020
        # 6G
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Section Y: Key Points to Share with the Participant Regarding Unit Preferences')
        answer_from_section(relevant_section, '6g.')&.downcase == 'yes'
      end

      def evicted_answer
        # 2/17/2020
        # 10B
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Section MM: Key Points to Share with the Participant Regarding Household History')
        answer_from_section(relevant_section, '10B.')&.downcase == 'yes'
      end

      def neighborhood_interests_answer
        # 2/17/2020
        # 6H
        return false unless hmis_assessment.pathways?

        relevant_section = section_starts_with('Section Y: Key Points to Share with the Participant Regarding Unit Preferences')
        answer_from_section(relevant_section, '6h.')&.split('|')&.map(&:presence)&.compact
      end
    end
  end
end
