###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasClientData
  extend ActiveSupport::Concern
  included do
    # A hook/wrapper to enable easily overriding how we get data for a given project client column
    # To use this efficiently, you'll probably want to preload a handful of data, see push_clients_to_cas.rb
    def value_for_cas_project_client(column)
      current_value = send(column)
      case column
      when *ce_assessment_lookup_keys.keys
        ce_assessment_value_for_boolean(ce_assessment_lookup_keys[column])
      when :family_member, :child_in_household, :required_number_of_bedrooms, :youth_rrh_desired, :dv_rrh_desired, :requires_elevator_access
        return current_value if current_value

        send("ce_assessment_value_for_#{column}")
      else
        # by default, just attempt to fetch the data from the client
        current_value
      end
    end

    private def ce_assessment_lookup_keys
      {
        hiv_positive: 'c_housing_HIV',
        meth_production_conviction: 'c_transfer_barrier_meth',
        requires_wheelchair_accessibility: 'c_disability_accomodations',
      }.freeze
    end
    memoize :ce_assessment_lookup_keys

    private def ce_assessment_value_for_boolean(key)
      most_recent_pathways_or_rrh_assessment.
        question_matching_requirement(key, '1').
        present?
    end

    # private def ce_assessment_value_for_hiv_positive
    #   most_recent_pathways_or_rrh_assessment.
    #     question_matching_requirement('c_housing_HIV', '1').
    #     present?
    # end

    # private def ce_assessment_value_for_meth_production_conviction
    #   most_recent_pathways_or_rrh_assessment.
    #     question_matching_requirement('c_transfer_barrier_meth', '1').
    #     present?
    # end

    private def ce_assessment_value_for_family_member
      response = most_recent_pathways_or_rrh_assessment.
        question_matching_requirement('c_additional_household_members')
      response&.AssessmentAnswer&.to_i&.positive?
    end

    private def ce_assessment_value_for_child_in_household
      ages = (1..5).map do |i|
        most_recent_pathways_or_rrh_assessment.
          question_matching_requirement("c_member#{i}_age")&.AssessmentAnswer.presence
      end.compact
      return false if ages.blank?

      ages.min < 18
    end

    private def days_homeless_in_last_three_years_cached
      # Use pathways/transfer assessment if available
      days = days_homeless_from_most_recent_hud_assessment.assessment_questions.detect do |m|
        m.AssessmentQuestion == GrdaWarehouse::Hud::AssessmentQuestion.DAYS_HOMELESS_ASSESSMENT_QUESTION
      end&.AssessmentAnswer
      return days if days.present?

      processed_service_history&.days_homeless_last_three_years
    end

    private def literally_homeless_last_three_years_cached
      # Use pathways/transfer assessment if available
      days = days_homeless_from_most_recent_hud_assessment.assessment_questions.detect do |m|
        m.AssessmentQuestion == GrdaWarehouse::Hud::AssessmentQuestion.DAYS_HOMELESS_ASSESSMENT_QUESTION
      end&.AssessmentAnswer
      return days if days.present?

      processed_service_history&.literally_homeless_last_three_years
    end

    private def days_homeless_for_vispdat_prioritization
      vispdat_prioritization_days_homeless || days_homeless_in_last_three_years
    end

    private def ce_assessment_value_for_youth_rrh_desired
      # c_youth_choice	1	Youth-specific only: (Youth-specific programs are with agencies who have a focus on young populations; they may be able to offer drop-in spaces for youth, as well as community-building and connections with other youth)
      # c_youth_choice	2	Adult programs only: (Adult programs serve youth who are 18-24, but may not have built in community space or activities to connect with other youth. They can help you find those opportunities. The adult RRH programs typically have more frequent openings)
      # c_youth_choice	3	Both Adult and youth-specific programs
      most_recent_pathways_or_rrh_assessment.
        question_matching_requirement('c_youth_choice')&.AssessmentAnswer.in?([1, 3])
    end

    private def ce_assessment_value_for_dv_rrh_desired
      # c_survivor_choice	1	Domestic Violence (DV)-specific only: (agencies who have a focus on populations experiencing violence; they may be able to offer specialized services for survivors in-house, such as support groups, clinical services, and legal services)
      # c_survivor_choice	2	Non-DV programs only (serve people fleeing violence, but may need to link you to outside, specialized agencies for services such as DV support groups, clinical services and legal services. Non-DV RRH programs typically have more frequent openings)
      # c_survivor_choice	3	Both DV and non-DV programs
      most_recent_pathways_or_rrh_assessment.
        question_matching_requirement('c_survivor_choice')&.AssessmentAnswer.in?([1, 3])
    end

    private def ce_assessment_value_for_required_number_of_bedrooms
      bedrooms = most_recent_pathways_or_rrh_assessment.
        question_matching_requirement('c_larger_room_size')&.AssessmentAnswer
      return unless bedrooms.present?

      bedrooms.to_i
    end

    private def ce_assessment_value_for_requires_elevator_access
      # c_disability_accomodations	1	Wheelchair accessible unit
      # c_disability_accomodations	2	First floor/elevator (little to no stairs to your unit)
      # c_disability_accomodations	5	Both Wheelchair accessible and First Floor/Elevator
      # c_disability_accomodations	3	Other accessibility
      # c_disability_accomodations	4	Not applicable
      most_recent_pathways_or_rrh_assessment.
        question_matching_requirement('c_disability_accomodations')&.AssessmentAnswer.in?([1, 5])
    end

    private def ce_assessment_value_for_requires_elevator_access
      # c_disability_accomodations	1	Wheelchair accessible unit
      # c_disability_accomodations	2	First floor/elevator (little to no stairs to your unit)
      # c_disability_accomodations	5	Both Wheelchair accessible and First Floor/Elevator
      # c_disability_accomodations	3	Other accessibility
      # c_disability_accomodations	4	Not applicable
      most_recent_pathways_or_rrh_assessment.
        question_matching_requirement('c_disability_accomodations')&.AssessmentAnswer.in?([1, 5])
    end
  end
end
