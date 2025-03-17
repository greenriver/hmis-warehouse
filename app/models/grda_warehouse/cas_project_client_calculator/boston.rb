###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

require 'memery'
module GrdaWarehouse::CasProjectClientCalculator
  class Boston < Default
    include Memery
    MAX_UNVERIFIED_ADDITIONAL_DAYS = 548
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

    def handles_days_homeless?
      true
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
        tie_breaker_date: 'Date pathways was collected for Pathways 2023, First Date Homeless for Pathways 2024, or Financial Assistance End Date for Transfer Assessments',
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
        lifetime_sex_offender: 'Registered sex offender (level 1,2,3) - lifetime registration (SORI)',
        requires_wheelchair_accessibility: 'Does the client need a wheelchair accessible unit response from the most recent pathways assessment',
        income_maximization_assistance_requested: 'Did the client request income maximization services response from the most recent pathways assessment',
        sro_ok: 'Is the client ok with an SRO response from the most recent pathways assessment',
        evicted: 'Has the client ever been evicted response from the most recent pathways assessment',
        rrh_desired: 'Is the client interested in Rapid Re-Housing',
        total_homeless_nights_unsheltered: 'Total # of Unsheltered Nights',
        required_minimum_occupancy: 'What is the total number of people in your household?',
        housing_barrier: 'Do you have any of the following histories and/or barriers?',
        additional_homeless_nights_sheltered: 'Length of Time Homeless (Sheltered) - Non-HMIS',
        additional_homeless_nights_unsheltered: 'Length of Time Homeless (Unsheltered) - Non-HMIS',
        calculated_homeless_nights_sheltered: 'Length of Time Homeless (Sheltered) - Warehouse',
        calculated_homeless_nights_unsheltered: 'Length of Time Homeless (Unsheltered) - Warehouse',
        total_homeless_nights_sheltered: 'Total # of Sheltered Nights',
      }.freeze
    end

    private def boolean_lookups
      {
        hiv_positive: 'c_housing_HIV',
        income_maximization_assistance_requested: 'c_interest_income_max',
        sro_ok: 'c_singleadult_sro',
        rrh_desired: 'c_interested_rrh',
        housing_barrier: 'c_pathways_barriers_yn',
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
        :domestic_violence,
        :currently_fleeing,
        :dv_date, # needed to show up in the UI
        :cellphone,
        :required_minimum_occupancy,
        :service_need,
        :additional_homeless_nights_sheltered,
        :additional_homeless_nights_unsheltered,
        :calculated_homeless_nights_sheltered,
        :calculated_homeless_nights_unsheltered,
        :total_homeless_nights_sheltered,
        :total_homeless_nights_unsheltered,
        :date_of_first_service,
        :psh_required,
        :meth_production_conviction,
        :lifetime_sex_offender,
        :evicted,
        :days_homeless,
        :hmis_days_homeless_all_time,
      ]
    end
    # memoize :pathways_questions

    def most_recent_assessment_for_destination(client)
      return unless client.present?

      client.most_recent_pathways_or_rrh_assessment_for_destination&.AssessmentDate&.to_date&.to_s
    end

    def most_recent_pathways_assessment_for_destination(client)
      return unless client.present?

      client.most_recent_pathways_assessment_for_destination&.AssessmentDate&.to_date&.to_s
    end

    def most_recent_transfer_assessment_for_destination(client)
      return unless client.present?

      client.most_recent_transfer_assessment_for_destination&.AssessmentDate&.to_date&.to_s
    end

    private def most_recent_pathways_or_transfer(client)
      client.most_recent_pathways_or_rrh_assessment_for_destination
    end
    memoize :most_recent_pathways_or_transfer

    private def for_boolean(client, key)
      most_recent_pathways_or_transfer(client).
        question_matching_requirement(key, '1').
        present?
    end

    private def meth_production_conviction(client)
      # check pathways and transfer fields
      conviction = most_recent_pathways_or_transfer(client).question_matching_requirement('c_pathways_barrier_meth', '1').present? ||
      most_recent_pathways_or_transfer(client).question_matching_requirement('c_transfer_barrier_meth', '1').present?
      return true if conviction

      # Otherwise, unknown
      nil
    end

    private def lifetime_sex_offender(client)
      most_recent_pathways_or_transfer(client).
        question_matching_requirement('c_transfer_barrier_SORI', '1').present?
    end

    private def evicted(client)
      evicted = most_recent_pathways_or_transfer(client).question_matching_requirement('c_pathways_barrier_meth', '1').present?
      return true if evicted

      evicted = most_recent_pathways_or_transfer(client).
        question_matching_requirement('c_transfer_barrier_PHAterm', '1').present?
      return true if evicted

      # Otherwise unknown
      nil
    end

    private def service_need(client)
      need = most_recent_pathways_or_transfer(client).question_matching_requirement('c_pathways_service_indicators', '1').present?
      return true if need

      # Otherwise, unknown
      nil
    end

    private def family_member(client)
      household_members_response = most_recent_pathways_or_transfer(client).
        question_matching_requirement('c_additional_household_members')&.AssessmentAnswer&.to_i&.positive?
      pregnant_or_parenting_pathway_response = most_recent_pathways_or_transfer(client).
        question_matching_requirement('c_pathway_pregnant_parentingchild')&.AssessmentAnswer&.to_i&.positive?
      household_members_response || pregnant_or_parenting_pathway_response
    end

    private def child_in_household(client)
      most_recent_pathways_or_transfer(client).
        question_matching_requirement('c_pathway_pregnant_parentingchild')&.AssessmentAnswer&.to_i&.positive?
    end

    private def required_minimum_occupancy(client)
      most_recent_pathways_or_transfer(client).
        question_matching_requirement('c_pathways_Household_size')&.AssessmentAnswer&.to_i
    end

    private def cellphone(client)
      # TODO: what is this field name?
      most_recent_pathways_or_transfer(client).
        question_matching_requirement('FIXME')&.AssessmentAnswer
    end

    private def youth_rrh_desired(client)
      # c_youth_choice	1	Youth-specific only: (Youth-specific programs are with agencies who have a focus on young populations; they may be able to offer drop-in spaces for youth, as well as community-building and connections with other youth)
      # c_youth_choice	2	Adult programs only: (Adult programs serve youth who are 18-24, but may not have built in community space or activities to connect with other youth. They can help you find those opportunities. The adult RRH programs typically have more frequent openings)
      # c_youth_choice	3	Both Adult and youth-specific programs
      option_one = most_recent_pathways_or_transfer(client).
        question_matching_requirement('c_youth_choice')&.AssessmentAnswer.to_s.in?(['1', '3'])
      return option_one if option_one
      return false unless client.youth_on?

      # If the client is a youth, and interested in RRH, note that
      for_boolean(client, 'c_interested_rrh')
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
      CasAccess::Neighborhood.neighborhood_ids_from_names(names)
    end

    # # From HMIS/Warehouse
    # calculated_homeless_nights_unsheltered
    # calculated_homeless_nights_sheltered
    #
    # Self-report
    # additional_homeless_nights_unsheltered
    # additional_homeless_nights_sheltered
    #
    # # Calculated based on setup
    # total_homeless_nights_unsheltered
    # total_homeless_nights_sheltered

    # Unsheltered days homeless from HMIS data - unsheltered days exclude any day the client was also sheltered
    # For Individual Pathways, this is limited to the last 3 years
    # For Family Pathways, this is for "all time" which we are limiting to the last 20 years for performance
    # See https://docs.google.com/spreadsheets/d/1A9zMLGI-nxnSRfuwn1akSS7B_tLJYzMKuSaIIMghTnE/edit?gid=0#gid=0 for spec
    def calculated_homeless_nights_unsheltered(client)
      return client.unsheltered_days_homeless_last_three_years unless most_recent_pathways_or_transfer(client).family_pathways_2024?

      end_date = Date.current
      start_date = end_date - 20.years
      client.unsheltered_days_homeless(start_date: start_date, end_date: end_date).count
    end

    # Sheltered days homeless from HMIS data
    # For Individual Pathways, this is limited to the last 3 years
    # For Family Pathways, this is for "all time" which we are limiting to the last 20 years for performance
    # See https://docs.google.com/spreadsheets/d/1A9zMLGI-nxnSRfuwn1akSS7B_tLJYzMKuSaIIMghTnE/edit?gid=0#gid=0 for spec
    def calculated_homeless_nights_sheltered(client)
      return client.sheltered_days_homeless_last_three_years unless most_recent_pathways_or_transfer(client).family_pathways_2024?

      end_date = Date.current
      start_date = end_date - 20.years
      client.sheltered_homeless_dates(start_date: start_date, end_date: end_date).count
    end

    # See https://docs.google.com/spreadsheets/d/1A9zMLGI-nxnSRfuwn1akSS7B_tLJYzMKuSaIIMghTnE/edit?gid=0#gid=0 for spec
    # Allowed Self-Report Unsheltered
    # The lesser of max_possible_self_report_homeless_days(client) and days from pathways
    def additional_homeless_nights_unsheltered(client)
      unsheltered = most_recent_pathways_or_transfer(client).
        question_matching_requirement('c_add_boston_nights_outside_pathways')&.AssessmentAnswer.to_i || 0

      [unsheltered, max_possible_self_report_homeless_days(client)].min
    end

    # See https://docs.google.com/spreadsheets/d/1A9zMLGI-nxnSRfuwn1akSS7B_tLJYzMKuSaIIMghTnE/edit?gid=0#gid=0 for spec
    # Allowed Self-Report Sheltered
    # min of (max_possible_self_report_homeless_days(client) - self-report unsheltered) and self-reported sheltered
    #
    def additional_homeless_nights_sheltered(client)
      sheltered = most_recent_pathways_or_transfer(client).
        question_matching_requirement('c_add_boston_nights_sheltered_pathways')&.AssessmentAnswer.to_i || 0

      allowed_sheltered_self_report = max_possible_self_report_homeless_days(client) - additional_homeless_nights_unsheltered(client)
      [allowed_sheltered_self_report, sheltered].min
    end

    # Cap total homeless unsheltered nights at 1,096, incorporate clamp on self-report
    # See https://docs.google.com/spreadsheets/d/1A9zMLGI-nxnSRfuwn1akSS7B_tLJYzMKuSaIIMghTnE/edit?gid=0#gid=0 for spec
    private def total_homeless_nights_unsheltered(client)
      calculated_homeless_nights_unsheltered(client) + additional_homeless_nights_unsheltered(client)
    end

    # See https://docs.google.com/spreadsheets/d/1A9zMLGI-nxnSRfuwn1akSS7B_tLJYzMKuSaIIMghTnE/edit?gid=0#gid=0 for spec
    def total_homeless_nights_sheltered(client)
      calculated_homeless_nights_sheltered(client) + additional_homeless_nights_sheltered(client)
    end

    # NOTE: this is also used in cohorts
    def days_homeless_in_last_three_years_cached(client)
      assessment = most_recent_pathways_or_transfer(client)
      pre_calculated_days = client.processed_service_history&.days_homeless_last_three_years || 0
      return pre_calculated_days unless assessment.present?

      pathways_days = pathways_days_homeless(client)
      return pathways_days if pathways_days.positive?

      pre_calculated_days
    end

    # For individual pathways, assessments, extra days are limited to 1,096 if a certification is on file, 548 if not
    # For family pathways, this is limited to 548 if there is no certification on file, no limit otherwise
    # Self-report days are only available if the overall number of warehouse/calculated/HMIS days does not meet the maximum
    private def max_possible_self_report_homeless_days(client)
      # Ignore clamping prior to the start date
      start_date = GrdaWarehouse::Config.get(:self_report_start_date)

      allowed_days = (max_possible_days(client) - warehouse_days_from_hmis(client)).clamp(0, MAX_UNVERIFIED_ADDITIONAL_DAYS)
      return allowed_days unless ce_self_certification_client_ids.include?(client.id) || start_date&.past?

      (max_possible_days(client) - warehouse_days_from_hmis(client)).clamp(0, max_possible_days(client))
    end

    # Individual Pathways and transfer assessments would be capped at 3 years
    # Family Pathways has no official cap, we're setting it to 20 years
    private def max_possible_days(client)
      return 1_096 unless most_recent_pathways_or_transfer(client).family_pathways_2024?

      # 20 years
      7_300
    end

    private def warehouse_days_from_hmis(client)
      calculated_homeless_nights_unsheltered(client) + calculated_homeless_nights_sheltered(client)
    end

    private def literally_homeless_last_three_years_cached(client)
      assessment = most_recent_pathways_or_transfer(client)
      pre_calculated_days = client.processed_service_history&.literally_homeless_last_three_years || 0
      return pre_calculated_days unless assessment.present?

      pathways_days = pathways_days_homeless(client)
      return pathways_days if pathways_days.positive?

      pre_calculated_days
    end

    # Overrides the usual calculation for first date homeless if available
    # If the question doesn't exist on the assessment or is empty, use the usual definition
    private def date_of_first_service(client)
      field_name = 'c_pathways_first_date_homeless'
      answer = most_recent_pathways_or_transfer(client).
        question_matching_requirement(field_name)&.AssessmentAnswer

      return client.date_of_first_service if answer.blank?

      answer.to_date
    end

    # If a client has more than 548 self-reported days (combination of sheltered and unsheltered)
    # and does not have a verification uploaded, count unsheltered days first, then count sheltered days UP TO 548.
    # If the self reported days are verified, use the provided amounts.
    private def pathways_days_homeless(client)
      unsheltered_days = additional_homeless_nights_unsheltered(client)
      sheltered_days = additional_homeless_nights_sheltered(client)
      days = (unsheltered_days + sheltered_days).clamp(0, max_possible_self_report_homeless_days(client))

      warehouse_unsheltered_days = calculated_homeless_nights_unsheltered(client)
      warehouse_sheltered_days = calculated_homeless_nights_sheltered(client)

      days += warehouse_unsheltered_days
      days += warehouse_sheltered_days
      days.clamp(0, max_possible_days(client))
    end

    # all-time days homeless
    def days_homeless(client)
      overall_nights_homeless(client)
    end

    def hmis_days_homeless_all_time(client)
      overall_nights_homeless(client)
    end

    private def overall_nights_homeless(client)
      total_homeless_nights_unsheltered(client) + total_homeless_nights_sheltered(client)
    end

    private def default_shelter_agency_contacts(client)
      contact_emails = client.client_contacts.shelter_agency_contacts.where.not(email: nil).pluck(:email)
      contact_emails << client.source_assessments.max_by(&:assessment_date)&.user&.user_email
      contact_emails.compact.uniq
    end

    # 0 = No PSH
    # 1 = PSH required
    # 2 = Either
    # Default to either if we don't have an answer
    # CAS uses `yes`, `no`, `maybe` strings
    private def psh_required(client)
      value = most_recent_pathways_or_transfer(client).
        question_matching_requirement('c_rrh_transfer_needs_subsidized_housing_resource')&.AssessmentAnswer.to_i || 2
      case value
      when 0
        'no'
      when 1
        'yes'
      else
        'maybe'
      end
    end

    private def contact_info_for_rrh_assessment(client)
      client.client_contacts.case_managers.map(&:full_address).join("\n\n")
    end

    # FIXME: this question was removed from 2024 pathways, need it restored, or new
    # instructions.  May also need to accommodate new and old versions.
    private def cas_assessment_name(client)
      # c_housing_assessment_name	1	Pathways
      # c_housing_assessment_name	2	RRH-PSH Transfer
      value = most_recent_pathways_or_transfer(client).
        question_matching_requirement('c_housing_assessment_name')&.AssessmentAnswer
      return 'IdentifiedClientAssessment' unless value.present?

      {
        1 => 'IdentifiedPathwaysVersionThreePathways',
        2 => 'IdentifiedPathwaysVersionThreeTransfer',
        3 => 'IdentifiedPathwaysVersionFourPathways',
        4 => 'IdentifiedPathwaysVersionFourTransfer',
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

    # For 2024/2025 score calculations are:
    # Individual Pathways Assessment: days homeless in the past 3 years, prefer Pathways answer clamped to 1,096, use
    # days in the past three years from the warehouse if not available.
    # Family Pathways Assessment: overall days homeless (all time), prefer Pathways answer, use client.days_homeless if
    # not available.
    # Transfer Assessment: use assessment score.
    private def assessment_score_for_cas(client)
      case cas_assessment_name(client)
      when 'IdentifiedPathwaysVersionThreePathways', 'IdentifiedPathwaysVersionFourPathways'
        if most_recent_pathways_or_transfer(client).family_pathways_2024?
          # Family
          overall_days_homeless(client)
        else
          # Individual
          days_homeless_in_last_three_years_cached(client)
        end

        # all time homeless days (no cap on total, but self-report limited to 548 if no verification)
        # Also need a mechanism to identify family Pathways assessments/AssessmentQuestions
      when 'IdentifiedPathwaysVersionThreeTransfer', 'IdentifiedPathwaysVersionFourTransfer'
        assessment_score(client)
      end
    end

    # Various tie-breaker dates used for prioritization in CAS when all else is equal
    # For Pathways V3, use the date the assessment was collected
    # For the V3 Transfer assessment, use the financial assistance end date
    # For Pathways V4, use the first date of homelessness
    private def tie_breaker_date(client)
      case cas_assessment_name(client)
      when 'IdentifiedPathwaysVersionThreePathways'
        cas_assessment_collected_at(client)
      when 'IdentifiedPathwaysVersionThreeTransfer', 'IdentifiedPathwaysVersionFourTransfer'
        financial_assistance_end_date(client)
      when 'IdentifiedPathwaysVersionFourPathways'
        date_of_first_service(client)
      end
    end

    # as of 3/21/2022 Set majority_sheltered based on CLS response
    # NOTE: this is also used in cohorts
    def majority_sheltered(client)
      cls = client.most_recent_cls
      return nil if cls.blank?

      # Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)
      return false if cls.CurrentLivingSituation == 116

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

    private def client_id_limit
      @client_id_limit ||= client_id.presence || cas_active_ids
    end

    private def disabled_client_ids
      @disabled_client_ids ||= GrdaWarehouse::Hud::Client.disabled_client_scope(client_ids: client_id_limit).pluck(:id).to_set
    end

    private def chronically_disabled_ids
      @chronically_disabled_ids ||= GrdaWarehouse::Hud::Client.chronically_disabled.where(id: client_id_limit).pluck(:id).to_set
    end

    private def disabling_condition?(client)
      # The following is equivalent to, but hopefully much faster in batches
      # client.chronically_disabled? || client.disabling_condition?
      chronically_disabled_ids.include?(client.id) || disabled_client_ids.include?(client.id)
    end

    private def ce_self_certification_client_ids
      @ce_self_certification_client_ids ||= GrdaWarehouse::ClientFile.
        recent_ce_self_report_certification.
        pluck(:client_id)
    end

    private def ongoing_enrollment_enrollment_ids(client)
      range = (Date.yesterday .. Date.current)
      client.source_enrollments.select { |m| m.open_during_range?(range) }.
        map { |en| [en.data_source_id, en.enrollment_id] }.to_set
    end

    # Any open enrollments 4.11.B CurrentlyFleeing = 1
    private def currently_fleeing(client)
      client.source_health_and_dvs.select do |m|
        m.CurrentlyFleeing == 1 &&
        [m.data_source_id, m.enrollment_id].in?(ongoing_enrollment_enrollment_ids(client))
      end.any?
    end

    private def dv_date(client)
      client.source_health_and_dvs.select do |m|
        m.CurrentlyFleeing == 1 &&
        [m.data_source_id, m.enrollment_id].in?(ongoing_enrollment_enrollment_ids(client))
      end&.max_by(&:InformationDate)&.InformationDate
    end

    # CE enrollments 4.11.2 DomesticViolenceSurvivor = 1
    private def domestic_violence(client)
      return 1 if client.source_health_and_dvs.
        joins(:project).
        merge(GrdaWarehouse::Hud::Project.with_project_type(HudUtility2024.project_type_number('CE'))).
        select do |m|
                    m.DomesticViolenceSurvivor == 1 &&
                    [m.data_source_id, m.enrollment_id].in?(ongoing_enrollment_enrollment_ids(client))
                  end.any?

      # Return 0 so we don't drop into calling this on the client, which has different results
      0
    end
  end
end
