###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memoist'
module GrdaWarehouse::CasProjectClientCalculator
  class Boston < Default
    extend Memoist
    # A hook/wrapper to enable easily overriding how we get data for a given project client column
    # To use this efficiently, you'll probably want to preload a handful of data, see push_clients_to_cas.rb
    def value_for_cas_project_client(client:, column:)
      if most_recent_pathways_or_transfer(client).present?
        current_value = case column
        when *boolean_lookups.keys
          for_boolean(client, boolean_lookups[column])
        when *pathways_questions
          send(column, client)
        end
        # by default, just attempt to fetch the data from the client
        return current_value unless current_value.nil?
      end
      # If calculator didn't return anything, ask the client for the answer
      # special case disabling_condition since it actually doesn't come from the pathways assessment
      # and we need to make it performant, so we can't just ask the client
      if column == :disabling_condition?
        send(column, client)
      elsif column.in?(unrelated_columns)
      else
        client.send(column)
      end
    end

    def unrelated_columns
      [
        :vispdat_score,
        :vispdat_length_homeless_in_days,
        :vispdat_priority_score,
        :vispdat_prioritization_days_homeless,
      ].freeze
    end

    private def custom_descriptions
      {
        disabling_condition: 'The client has a verification of disability on file, or a disability marked indefinite and impairing collected in the past 3 years, or the client\'s most recent affirmative disability response has not been followed by a negative response.',
        family_member: 'Are there additional members in the household response from the most recent pathways assessment',
        child_in_household: 'Was anyone under 18 listed on the most recent pathways assessment',
        required_number_of_bedrooms: 'Number of bedrooms required from the most recent pathways assessment',
        youth_rrh_desired: 'Youth Choice response from the most recent pathways assessment',
        dv_rrh_desired: 'Survivor Choice response from the most recent pathways assessment',
        requires_elevator_access: 'Does the client need a first-floor or elevator accessible unit response from the most recent pathways assessment',
        neighborhood_ids_for_cas: 'Neighborhoods chosen on the most recent pathways assessment',
        default_shelter_agency_contacts: '',
        days_homeless_in_last_three_years_cached: 'Boston total nights homeless in the past 3 years from the most recent pathways assessment',
        literally_homeless_last_three_years_cached: 'Boston total nights homeless in the past 3 years from the most recent pathways assessment',
        cas_assessment_name: '',
        max_current_total_monthly_income: 'Estimated gross income from the most recent pathways assessment',
        contact_info_for_rrh_assessment: 'Client case manager contacts',
        cas_assessment_collected_at: 'Date the assessment was collected', # note this is really just assessment_collected_at
        majority_sheltered: 'Most recent current living situation was sheltered',
        assessment_score_for_cas: 'Days homeless in the past 3 years for pathways, score for transfer assessments',
        tie_breaker_date: 'Date pathways was collected, or Financial Assistance End Date for transfer assessments',
        financial_assistance_end_date: 'Latest Date Eligible for Financial Assistance response from the most recent pathways assessment',
        assessor_first_name: 'First name of the user who completed the most recent pathways assessment',
        assessor_last_name: 'Last name of the user who completed the most recent pathways assessment',
        assessor_email: 'Email of the user who completed the most recent pathways assessment',
        assessor_phone: 'Phone number of the user who completed the most recent pathways assessment',
        cas_pregnancy_status: 'Has the client indicated they were pregnant within the past year in their responses to HMIS Health and DV questions',
        most_recent_vispdat_score: 'Unused',
        calculate_vispdat_priority_score: 'Unused',
        days_homeless_for_vispdat_prioritization: 'Unused',
        hiv_positive: 'HIV/AIDS response from the most recent pathways assessment',
        meth_production_conviction: 'Meth production response from the most recent pathways assessment',
        requires_wheelchair_accessibility: 'Does the client need a wheelchair accessible unit response from the most recent pathways assessment',
        income_maximization_assistance_requested: 'Did the client request income maximization services response from the most recent pathways assessment',
        sro_ok: 'Is the client ok with an SRO response from the most recent pathways assessment',
        evicted: 'Has the client ever been evicted response from the most recent pathways assessment',
      }.freeze
    end

    private def boolean_lookups
      {
        hiv_positive: 'c_housing_HIV',
        meth_production_conviction: 'c_transfer_barrier_meth',
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
        :cas_pregnancy_status,
        :most_recent_vispdat_score,
        :calculate_vispdat_priority_score,
        :days_homeless_for_vispdat_prioritization,
        :disabling_condition?,
      ]
    end
    # memoize :pathways_questions

    private def most_recent_pathways_or_transfer(client)
      client.most_recent_pathways_or_rrh_assessment_for_destination
    end
    memoize :most_recent_pathways_or_transfer

    private def for_boolean(client, key)
      most_recent_pathways_or_transfer(client).
        question_matching_requirement(key, '1').
        present?
    end

    private def family_member(client)
      response = most_recent_pathways_or_transfer(client).
        question_matching_requirement('c_additional_household_members')
      response&.AssessmentAnswer&.to_i&.positive?
    end

    private def child_in_household(client)
      ages = (1..5).map do |i|
        most_recent_pathways_or_transfer(client).
          question_matching_requirement("c_member#{i}_age")&.AssessmentAnswer.presence
      end.compact
      return false if ages.blank?

      ages.map(&:to_i).min < 18
    end

    private def youth_rrh_desired(client)
      # c_youth_choice	1	Youth-specific only: (Youth-specific programs are with agencies who have a focus on young populations; they may be able to offer drop-in spaces for youth, as well as community-building and connections with other youth)
      # c_youth_choice	2	Adult programs only: (Adult programs serve youth who are 18-24, but may not have built in community space or activities to connect with other youth. They can help you find those opportunities. The adult RRH programs typically have more frequent openings)
      # c_youth_choice	3	Both Adult and youth-specific programs
      most_recent_pathways_or_transfer(client).
        question_matching_requirement('c_youth_choice')&.AssessmentAnswer.to_s.in?(['1', '3'])
    end

    private def dv_rrh_desired(client)
      # c_survivor_choice	1	Domestic Violence (DV)-specific only: (agencies who have a focus on populations experiencing violence; they may be able to offer specialized services for survivors in-house, such as support groups, clinical services, and legal services)
      # c_survivor_choice	2	Non-DV programs only (serve people fleeing violence, but may need to link you to outside, specialized agencies for services such as DV support groups, clinical services and legal services. Non-DV RRH programs typically have more frequent openings)
      # c_survivor_choice	3	Both DV and non-DV programs
      most_recent_pathways_or_transfer(client).
        question_matching_requirement('c_survivor_choice')&.AssessmentAnswer.to_s.in?(['1', '3'])
    end

    # Bedrooms come through as an integer that needs to be looked up, but needs to be passed to CAS
    # as an integer of the number of rooms. For now we'll grab just the integer section of the looked up value
    # so that we get the right number in CAS
    private def required_number_of_bedrooms(client)
      bedrooms = most_recent_pathways_or_transfer(client).
        question_matching_requirement('c_larger_room_size')&.lookup&.response_text&.scan(/\d+/)&.first
      return unless bedrooms.present?

      bedrooms.to_i
    end

    private def requires_elevator_access(client)
      # c_disability_accomodations	1	Wheelchair accessible unit
      # c_disability_accomodations	2	First floor/elevator (little to no stairs to your unit)
      # c_disability_accomodations	5	Both Wheelchair accessible and First Floor/Elevator
      # c_disability_accomodations	3	Other accessibility
      # c_disability_accomodations	4	Not applicable
      most_recent_pathways_or_transfer(client).
        question_matching_requirement('c_disability_accomodations')&.AssessmentAnswer.to_s.in?(['2', '5'])
    end

    private def requires_wheelchair_accessibility(client)
      # c_disability_accomodations	1	Wheelchair accessible unit
      # c_disability_accomodations	2	First floor/elevator (little to no stairs to your unit)
      # c_disability_accomodations	5	Both Wheelchair accessible and First Floor/Elevator
      # c_disability_accomodations	3	Other accessibility
      # c_disability_accomodations	4	Not applicable
      most_recent_pathways_or_transfer(client).
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
        name if most_recent_pathways_or_transfer(client).
          question_matching_requirement(key, '1').present?
      end.compact
      Cas::Neighborhood.neighborhood_ids_from_names(names)
    end

    private def days_homeless_in_last_three_years_cached(client)
      days = most_recent_pathways_or_transfer(client).
        question_matching_requirement('c_new_boston_homeless_nights_total')&.AssessmentAnswer
      return days if days.present?

      client.processed_service_history&.days_homeless_last_three_years
    end

    private def literally_homeless_last_three_years_cached(client)
      days = most_recent_pathways_or_transfer(client).
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
      value = most_recent_pathways_or_transfer(client).
        question_matching_requirement('c_housing_assessment_name')&.AssessmentAnswer
      return 'IdentifiedClientAssessment' unless value.present?

      {
        1 => 'IdentifiedPathwaysVersionThreePathways',
        2 => 'IdentifiedPathwaysVersionThreeTransfer',
      }[value.to_i] || 'IdentifiedClientAssessment'
    end

    private def max_current_total_monthly_income(client)
      amount = most_recent_pathways_or_transfer(client).
        question_matching_requirement('c_hh_estimated_annual_gross')&.AssessmentAnswer
      return nil if amount.blank?

      amount = amount.to_i
      return nil unless amount.positive?

      (amount / 12).round
    end

    private def cas_assessment_collected_at(client)
      most_recent_pathways_or_transfer(client)&.AssessmentDate
    end

    private def assessment_score(client)
      most_recent_pathways_or_transfer(client)&.
        results_matching_requirement('total')&.AssessmentResult
    end

    private def financial_assistance_end_date(client)
      most_recent_pathways_or_transfer(client).
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
      most_recent_pathways_or_transfer(client)&.user&.UserFirstName
    end

    private def assessor_last_name(client)
      most_recent_pathways_or_transfer(client)&.user&.UserLastName
    end

    private def assessor_email(client)
      most_recent_pathways_or_transfer(client)&.user&.UserEmail
    end

    private def assessor_phone(client)
      [
        most_recent_pathways_or_transfer(client)&.user&.UserPhone,
        most_recent_pathways_or_transfer(client)&.user&.UserExtension,
      ].compact.join('x')
    end

    private def cas_pregnancy_status(client)
      one_year_ago = 1.years.ago.to_date
      client.source_health_and_dvs&.detect do |m|
        m.PregnancyStatus == 1 &&
        (
          (m.InformationDate.present? && m.InformationDate > one_year_ago) ||
          (m.DueDate.present? && m.DueDate > Date.current - 3.months)
        )
      end.present?
    end

    private def most_recent_vispdat_score(_)
      0
    end

    private def calculate_vispdat_priority_score(_)
      0
    end

    private def days_homeless_for_vispdat_prioritization(client)
      client.processed_service_history&.days_homeless_last_three_years
    end

    private def cas_active_ids
      @cas_active_ids ||= GrdaWarehouse::Hud::Client.cas_active.pluck(:id)
    end

    private def disabled_client_ids
      @disabled_client_ids ||= GrdaWarehouse::Hud::Client.disabled_client_scope(client_ids: cas_active_ids).pluck(:id).to_set
    end

    private def chronically_disabled_ids
      @chronically_disabled_ids ||= GrdaWarehouse::Hud::Client.chronically_disabled.where(id: cas_active_ids).pluck(:id).to_set
    end

    private def disabling_condition?(client)
      # The following is equivalent to, but hopefully much faster in batches
      # client.chronically_disabled? || client.disabling_condition?
      chronically_disabled_ids.include?(client.id) || disabled_client_ids.include?(client.id)
    end
  end
end
