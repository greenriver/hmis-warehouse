###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memoist'
module GrdaWarehouse::CasProjectClientCalculator
  class Boston
    extend Memoist
    # A hook/wrapper to enable easily overriding how we get data for a given project client column
    # To use this efficiently, you'll probably want to preload a handful of data, see push_clients_to_cas.rb
    def value_for_cas_project_client(client:, column:)
      current_value = client.send(column)
      # Return existing value if we don't have anything in the new format
      return current_value unless client.most_recent_pathways_or_rrh_assessment_for_destination.present?

      case column
      when *boolean_lookups.keys
        assessment_value = for_boolean(client, boolean_lookups[column])
        return assessment_value unless assessment_value.nil?
      when *pathways_questions
        assessment_value = send(column, client)
        return assessment_value unless assessment_value.nil?
      end
      # by default, just attempt to fetch the data from the client
      current_value
    end

    private def boolean_lookups
      {
        hiv_positive: 'c_housing_HIV',
        meth_production_conviction: 'c_transfer_barrier_meth',
        requires_wheelchair_accessibility: 'c_disability_accomodations',
        income_maximization_assistance_requested: 'c_interest_income_max',
        sro_ok: 'c_singleadult_sro',
        evicted: 'c_pathways_barrier_eviction',
      }.freeze
    end
    memoize :boolean_lookups

    private def pathways_questions
      [
        :family_member,
        :child_in_household,
        :required_number_of_bedrooms,
        :youth_rrh_desired,
        :dv_rrh_desired,
        :requires_elevator_access,
        :requires_wheelchair_accessibility,
        :neighborhood_ids_for_cas,
        :default_shelter_agency_contacts,
        :days_homeless_in_last_three_years_cached,
        :literally_homeless_last_three_years_cached,
        :cas_assessment_name,
        :max_current_total_monthly_income,
        :contact_info_for_rrh_assessment,
        :cas_assessment_collected_at, # note this is really just assessment_collected_at
        :majority_sheltered,
        :assessment_score_for_cas,
        :tie_breaker_date,
        :financial_assistance_end_date,
        :assessor_first_name,
        :assessor_last_name,
        :assessor_email,
        :assessor_phone,
      ]
    end
    # memoize :pathways_questions

    private def for_boolean(client, key)
      client.most_recent_pathways_or_rrh_assessment_for_destination.
        question_matching_requirement(key, '1').
        present?
    end

    private def family_member(client)
      response = client.most_recent_pathways_or_rrh_assessment_for_destination.
        question_matching_requirement('c_additional_household_members')
      response&.AssessmentAnswer&.to_i&.positive?
    end

    private def child_in_household(client)
      ages = (1..5).map do |i|
        client.most_recent_pathways_or_rrh_assessment_for_destination.
          question_matching_requirement("c_member#{i}_age")&.AssessmentAnswer.presence
      end.compact
      return false if ages.blank?

      ages.map(&:to_i).min < 18
    end

    private def youth_rrh_desired(client)
      # c_youth_choice	1	Youth-specific only: (Youth-specific programs are with agencies who have a focus on young populations; they may be able to offer drop-in spaces for youth, as well as community-building and connections with other youth)
      # c_youth_choice	2	Adult programs only: (Adult programs serve youth who are 18-24, but may not have built in community space or activities to connect with other youth. They can help you find those opportunities. The adult RRH programs typically have more frequent openings)
      # c_youth_choice	3	Both Adult and youth-specific programs
      client.most_recent_pathways_or_rrh_assessment_for_destination.
        question_matching_requirement('c_youth_choice')&.AssessmentAnswer.to_s.in?(['1', '3'])
    end

    private def dv_rrh_desired(client)
      # c_survivor_choice	1	Domestic Violence (DV)-specific only: (agencies who have a focus on populations experiencing violence; they may be able to offer specialized services for survivors in-house, such as support groups, clinical services, and legal services)
      # c_survivor_choice	2	Non-DV programs only (serve people fleeing violence, but may need to link you to outside, specialized agencies for services such as DV support groups, clinical services and legal services. Non-DV RRH programs typically have more frequent openings)
      # c_survivor_choice	3	Both DV and non-DV programs
      client.most_recent_pathways_or_rrh_assessment_for_destination.
        question_matching_requirement('c_survivor_choice')&.AssessmentAnswer.to_s.in?(['1', '3'])
    end

    private def required_number_of_bedrooms(client)
      bedrooms = client.most_recent_pathways_or_rrh_assessment_for_destination.
        question_matching_requirement('c_larger_room_size')&.AssessmentAnswer
      return unless bedrooms.present?

      bedrooms.to_i
    end

    private def requires_elevator_access(client)
      # c_disability_accomodations	1	Wheelchair accessible unit
      # c_disability_accomodations	2	First floor/elevator (little to no stairs to your unit)
      # c_disability_accomodations	5	Both Wheelchair accessible and First Floor/Elevator
      # c_disability_accomodations	3	Other accessibility
      # c_disability_accomodations	4	Not applicable
      client.most_recent_pathways_or_rrh_assessment_for_destination.
        question_matching_requirement('c_disability_accomodations')&.AssessmentAnswer.to_s.in?(['2', '5'])
    end

    private def requires_wheelchair_accessibility(client)
      # c_disability_accomodations	1	Wheelchair accessible unit
      # c_disability_accomodations	2	First floor/elevator (little to no stairs to your unit)
      # c_disability_accomodations	5	Both Wheelchair accessible and First Floor/Elevator
      # c_disability_accomodations	3	Other accessibility
      # c_disability_accomodations	4	Not applicable
      client.most_recent_pathways_or_rrh_assessment_for_destination.
        question_matching_requirement('c_disability_accomodations')&.AssessmentAnswer.to_s.in?(['1', '5'])
    end

    private def neighborhood_ids_for_cas(client)
      neighborhoods = {
        'c_neighborhoods_all' => '',
        'c_neighborhood_allston_brighton' => 'Allston / Brighton',
        'c_neighborhood_backbayplus' => 'Back Bay / Fenway / South End',
        'c_neighborhood_charlestown' => 'Charlestown',
        'c_neighborhood_dorchester21' => 'Dorchester - 02121',
        'c_neighborhood_dorchester22' => 'Dorchester - 02122',
        'c_neighborhood_dorchester24' => 'Dorchester - 02124',
        'c_neighborhood_dorchester25' => 'Dorchester - 02125',
        'c_neighborhood_downtownplus' => 'Downtown / Beacon Hill / North End / Chinatown / Gov Center / West End',
        'c_neighborhood_eastboston' => 'East Boston',
        'c_neighborhood_hydepark' => 'Hyde Park',
        'c_neighborhood_jamaicaplain' => 'Jamaica Plain',
        'c_neighborhood_mattapan' => 'Mattapan',
        'c_neighborhood_missionhill' => 'Mission Hill',
        'c_neighborhood_roslindale' => 'Roslindale',
        'c_neighborhood_roxbury' => 'Roxbury - 02119',
        'c_neighborhood_southboston_seaport' => 'South Boston / Seaport',
        'c_neighborhood_westroxbury' => 'West Roxbury',
      }
      names = neighborhoods.map do |key, name|
        name if client.most_recent_pathways_or_rrh_assessment_for_destination.
          question_matching_requirement(key, '1').present?
      end.compact
      Cas::Neighborhood.neighborhood_ids_from_names(names)
    end

    private def days_homeless_in_last_three_years_cached(client)
      days = client.most_recent_pathways_or_rrh_assessment_for_destination.
        question_matching_requirement('c_new_boston_homeless_nights_total')&.AssessmentAnswer
      return days if days.present?

      client.processed_service_history&.days_homeless_last_three_years
    end

    private def literally_homeless_last_three_years_cached(client)
      days = client.most_recent_pathways_or_rrh_assessment_for_destination.
        question_matching_requirement('c_new_boston_homeless_nights_total')&.AssessmentAnswer
      return days if days.present?

      client.processed_service_history&.literally_homeless_last_three_years
    end

    private def default_shelter_agency_contacts(client)
      client.client_contacts.shelter_agency_contacts.where.not(email: nil).pluck(:email)
    end

    private def contact_info_for_rrh_assessment(client)
      client.client_contacts.case_managers.map(&:full_address).join("\n\n")
    end

    private def cas_assessment_name(client)
      # c_housing_assessment_name	1	Pathways
      # c_housing_assessment_name	2	RRH-PSH Transfer
      value = client.most_recent_pathways_or_rrh_assessment_for_destination.
        question_matching_requirement('c_housing_assessment_name')&.AssessmentAnswer
      return 'IdentifiedClientAssessment' unless value.present?

      {
        1 => 'IdentifiedPathwaysVersionThreePathways',
        2 => 'IdentifiedPathwaysVersionThreeTransfer',
      }[value.to_i] || 'IdentifiedClientAssessment'
    end

    private def max_current_total_monthly_income(client)
      amount = client.most_recent_pathways_or_rrh_assessment_for_destination.
        question_matching_requirement('c_hh_estimated_annual_gross')&.AssessmentAnswer
      if amount.present?
        amount = amount.to_i
        return (amount / 12).round if amount.positive?
      end

      client.source_enrollments.open_on_date(Date.current).map do |enrollment|
        enrollment.income_benefits.limit(1).
          order(InformationDate: :desc).
          pluck(:TotalMonthlyIncome).first
      end.compact.max || 0
    end

    private def cas_assessment_collected_at(client)
      client.most_recent_pathways_or_rrh_assessment_for_destination&.AssessmentDate
    end

    private def assessment_score(client)
      client.most_recent_pathways_or_rrh_assessment_for_destination&.
        results_matching_requirement('total')&.AssessmentResult
    end

    private def financial_assistance_end_date(client)
      client.most_recent_pathways_or_rrh_assessment_for_destination.
        question_matching_requirement('c_latest_date_financial_assistance_eligibility_rrh')&.AssessmentAnswer
    end

    private def assessment_score_for_cas(client)
      case cas_assessment_name(client)
      when 'IdentifiedPathwaysVersionThreePathways'
        days_homeless_in_last_three_years_cached(client)
      when 'IdentifiedPathwaysVersionThreeTransfer'
        assessment_score(client)
      end
    end

    private def tie_breaker_date(client)
      case cas_assessment_name(client)
      when 'IdentifiedPathwaysVersionThreePathways'
        cas_assessment_collected_at(client)
      when 'IdentifiedPathwaysVersionThreeTransfer'
        financial_assistance_end_date(client)
      end
    end

    # as of 3/21/2022 Set majority_sheltered based on CLS response
    private def majority_sheltered(client)
      cls = client.most_recent_cls
      return nil if cls.blank?

      # Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)
      return false if cls.CurrentLivingSituation == 16

      # nil missing
      # 30 No exit interview completed
      # 17 Other
      # 37 Worker unable to determine
      # 8 Client doesn’t know
      # 9 Client refused
      # 99 Data not collected
      return nil if cls.CurrentLivingSituation.in?([nil, 30, 17, 37, 8, 9, 99])

      true
    end

    private def assessor_first_name(client)
      client.most_recent_pathways_or_rrh_assessment_for_destination&.user&.UserFirstName
    end

    private def assessor_last_name(client)
      client.most_recent_pathways_or_rrh_assessment_for_destination&.user&.UserLastName
    end

    private def assessor_email(client)
      client.most_recent_pathways_or_rrh_assessment_for_destination&.user&.UserEmail
    end

    private def assessor_phone(client)
      [
        client.most_recent_pathways_or_rrh_assessment_for_destination&.user&.UserPhone,
        client.most_recent_pathways_or_rrh_assessment_for_destination&.user&.UserExtension,
      ].compact.join('x')
    end
  end
end
