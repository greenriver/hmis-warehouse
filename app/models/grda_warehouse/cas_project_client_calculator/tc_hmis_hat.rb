###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memery'
module GrdaWarehouse::CasProjectClientCalculator
  class TcHmisHat < Default
    include ArelHelper
    include Memery
    # A hook/wrapper to enable easily overriding how we get data for a given project client column
    # To use this efficiently, you'll probably want to preload a handful of data, see push_clients_to_cas.rb
    def value_for_cas_project_client(client:, column:)
      current_value = client.send(column)
      # overrides even if we don't have a TC HAT
      current_value = send(column, client) if column.in?(local_calculators)
      # Return existing value if we don't have anything in the new format
      return current_value unless most_recent_assessment_for_destination(client).present?

      case column
      when *boolean_lookups
        assessment_value = for_boolean(client, column)
        return assessment_value unless assessment_value.nil?
      when *tc_hat_questions
        assessment_value = send(column, client)
        return assessment_value unless assessment_value.nil?
      end
      # by default, just attempt to fetch the data from the client
      current_value
    end

    private def local_calculators
      [
        :ssvf_eligible,
        :child_in_household,
        :default_shelter_agency_contacts,
      ].freeze
    end

    private def custom_descriptions
      {
        lifetime_sex_offender: 'Life-Time Sex Offender response from the most recent TC-HAT',
        family_member: 'Household Type response from the most recent TC-HAT, with additional calculations',
        vash_eligible: 'Client is marked as VASH Eligible on a cohort',
        health_prioritized: 'Client is marked for Health Prioritization',
        strengths: 'Strengths response from the most recent TC-HAT',
        challenges: 'Challenges response from the most recent TC-HAT',
        foster_care: 'Was the client in foster care as a youth response from the most recent TC-HAT',
        open_case: 'Does the client have a current open case response from the most recent TC-HAT',
        housing_for_formerly_homeless: 'Housing preference response from the most recent TC-HAT',
        drug_test: 'Can the client pass a drug test response from the most recent TC-HAT',
        heavy_drug_use: 'Is the client a heavy drug user response from the most recent TC-HAT',
        sober: 'Has the client been sober at least one year response from the most recent TC-HAT',
        willing_case_management: 'Is the client willing to participate in case management response from the most recent TC-HAT',
        employed_three_months: 'Has the client been employed for at least three months response from the most recent TC-HAT',
        living_wage: 'Is the client making a living wage response from the most recent TC-HAT',
        can_work_full_time: 'Is the client available to work full-time response from the most recent TC-HAT',
        full_time_employed: 'Does the client have full-time employment response from the most recent TC-HAT',
        required_number_of_bedrooms: 'Bedrooms required to house household',
        required_minimum_occupancy: 'Number of household members',
        child_in_household: 'Is the client a member of a household with at least one minor child',
        cas_pregnancy_status: 'Are you currently pregnant?',
        default_shelter_agency_contacts: '',
      }.freeze
    end

    private def assessment_keys
      {
        family_member: :hat_a6_household_type,
        lifetime_sex_offender: :hat_b3_lifetime_sex_offender,
        strengths: :hat_b1_strength,
        challenges: :hat_b2_challenge,
        foster_care: :hat_e12_foster_youth,
        open_case: :hat_e11_cps,
        housing_for_formerly_homeless: :hat_f1_housing_preference,
        neighborhood_ids_for_cas: :hat_f3_housing_location_preference,
        drug_test: :hat_c7_can_pass_drug_test,
        heavy_drug_use: :hat_c8_history_of_drug_use,
        sober: :hat_c9_sober_for_one_year,
        willing_case_management: :hat_c10_willing_to_engage_case_management,
        employed_three_months: :hat_c11_employed_at_least_3_months,
        living_wage: :hat_c12_earning_at_least_13_hr,
        need_daily_assistance: :hat_a11_unable_to_live_alone,
        full_time_employed: :hat_c1_working_full_time,
        can_work_full_time: :hat_c2_able_to_work_full_time,
        willing_to_work_full_time: :hat_c3_willing_to_work_full_time,
        rrh_successful_exit: :hat_c5_staff_expect_successful_rrh,
        th_desired: :hat_c6_client_interested_in_th,
        site_case_management_required: :hat_d2_site_based_cm,
        ongoing_case_management_required: :hat_d3_ongoing_housing_cm,
        currently_fleeing: :hat_e13_ipv_fleeing,
        dv_date: :hat_e14_ipv_date,
        required_minimum_occupancy: :hat_a8_household_size,
        # Internal
        single_parent_child_over_ten: :hat_a7_single_parent,
        legal_custody: :hat_a9_custody,
        future_custody: :hat_a10_future_custody,
        household_size: :hat_a8_household_size,
        cas_pregnancy_status: :hat_e9_pregnant,
      }.freeze
    end
    memoize :assessment_keys

    private def boolean_lookups
      [
        :lifetime_sex_offender,
        :foster_care,
        :open_case,
        :drug_test,
        :heavy_drug_use,
        :sober,
        :willing_case_management,
        :employed_three_months,
        :living_wage,
        :need_daily_assistance,
        :full_time_employed,
        :can_work_full_time,
        :willing_to_work_full_time,
        :rrh_successful_exit,
        :th_desired,
        :site_case_management_required,
        :ongoing_case_management_required,
        :currently_fleeing,
        :cas_pregnancy_status,
      ].freeze
    end
    memoize :boolean_lookups

    private def tc_hat_questions
      [
        :family_member,
        :lifetime_sex_offender,
        :strengths,
        :challenges,
        :foster_care,
        :open_case,
        :housing_for_formerly_homeless,
        :neighborhood_ids_for_cas,
        :cas_assessment_collected_at, # note this is really just assessment_collected_at
        :days_homeless_in_last_three_years_cached,
        :literally_homeless_last_three_years_cached,
        :drug_test,
        :heavy_drug_use,
        :sober,
        :willing_case_management,
        :employed_three_months,
        :living_wage,
        :need_daily_assistance,
        :full_time_employed,
        :can_work_full_time,
        :willing_to_work_full_time,
        :rrh_successful_exit,
        :lifetime_sex_offender,
        :th_desired,
        :drug_test,
        :employed_three_months,
        :site_case_management_required,
        :ongoing_case_management_required,
        :currently_fleeing,
        :dv_date,
        :va_eligible,
        :vash_eligible,
        :rrh_desired,
        :required_minimum_occupancy,
        :required_number_of_bedrooms,
      ]
    end

    def most_recent_assessment_for_destination(client)
      return unless client.present?

      cas_assessment_collected_at(client)&.to_date&.to_s
    end

    private def cas_assessment(client)
      client.source_clients.map do |source_client|
        source_client.assessments.housing_needs.order(assessment_date: :desc).first
      end.
        compact.
        max_by(&:assessment_date)
    end
    memoize :cas_assessment

    private def for_string(client, key)
      cas_assessment(client).answer(assessment_keys[key])
    end

    private def for_boolean(client, key)
      cas_assessment(client).question_matching_requirement(assessment_keys[key], 'yes', case_sensitive: false)
    end

    private def family_member(client)
      household_type = for_string(client, :family_member)&.downcase
      family = household_type&.include?('family')
      youth = household_type&.include?('youth')

      single_parent = for_boolean(client, :single_parent_child_over_ten)
      custody_now = for_boolean(client, :legal_custody)
      custody_later = for_boolean(client, :future_custody)
      pregnant = for_boolean(client, :cas_pregnancy_status)

      # Pregnant clients are always considered a family
      return true if pregnant
      # There is a child, but the parent doesn't, and won't have custody
      return false if single_parent && (!custody_now && !custody_later)
      # Client indicated the household is adult only
      return false unless family || youth
      return true if household_size(client) > 1
      # If the client failed to count the child, but will have custody at some point,
      # still consider this a family
      return true if household_size(client) == 1 && (custody_now || custody_later)

      false
    end

    private def household_size(client)
      for_string(client, :household_size).to_i
    end

    private def required_minimum_occupancy(client)
      household_size(client)
    end

    private def required_number_of_bedrooms(client)
      num = 1
      num = 2 if for_boolean(client, :single_parent_child_over_ten)

      case household_size(client)
      # when 1, 2 # unnecessary, these would result in 1 bedroom
      when 3, 4
        2
      when (5..)
        3
      else
        num
      end
    end

    private def neighborhood_ids_for_cas(client)
      chosen_neighborhood = for_string(client, :neighborhood_ids_for_cas)
      CasAccess::Neighborhood.neighborhood_ids_from_names([chosen_neighborhood])
    end

    private def strengths(client)
      strengths = for_string(client, :strengths)
      return [] unless strengths.present?

      JSON.parse(strengths).reject(&:blank?)
    end

    private def challenges(client)
      challenges = for_string(client, :challenges)
      return [] unless challenges.present?

      JSON.parse(challenges).reject(&:blank?)
    end

    private def housing_for_formerly_homeless(client)
      for_string(client, :housing_for_formerly_homeless)&.
        include?('with others who are formerly homeless')
    end

    private def dv_date(client)
      for_string(client, :dv_date).presence&.to_date
    end

    private def cas_assessment_collected_at(client)
      cas_assessment(client)&.assessment_date.presence&.to_date
    end

    private def days_homeless_in_last_three_years_cached(client)
      days = 0
      days += (client.tc_hat_additional_days_homeless || 0)

      days + (client.processed_service_history&.days_homeless_last_three_years || 0)
    end

    private def literally_homeless_last_three_years_cached(client)
      days = 0
      days += (client.tc_hat_additional_days_homeless || 0)

      days + (client.processed_service_history&.literally_homeless_last_three_years || 0)
    end

    # Set based on client having any active cohorts with VA Eligible set to Yes or true
    private def va_eligible(client)
      client.cohort_clients.
        joins(:cohort).
        merge(GrdaWarehouse::Cohort.active).
        where(c_client_t[:va_eligible].lower.matches('%yes%')).
        exists?
    end

    # Set based on client having any active cohorts with VASH Eligible set to Yes or true
    private def vash_eligible(client)
      client.cohort_clients.
        joins(:cohort).
        merge(GrdaWarehouse::Cohort.active).
        where(vash_eligible: true).
        exists?
    end

    private def rrh_desired(client)
      full_time_employed = for_boolean(client, :full_time_employed)
      rrh_successful_exit = for_boolean(client, :rrh_successful_exit)

      full_time_employed || rrh_successful_exit
    end

    private def ssvf_eligible(client)
      # ssvf_eligible only _looks_ like a boolean
      client.active_cohort_clients.map(&:ssvf_eligible).
        any?('true')
    end

    private def child_in_household(client)
      # Any open enrollment in SO, ES, SH, TH or PH, with a child under age 18
      project_types = HudUtility2024.residential_project_type_numbers_by_codes(:so, :es, :sh, :th, :ph)
      client.service_history_enrollments.ongoing.in_project_type(project_types).
        where(she_t[:age].lt(18).or(she_t[:other_clients_under_18].eq(true))).exists?
    end

    private def default_shelter_agency_contacts(client)
      # Email of most recent assessor
      email = cas_assessment(client)&.user&.user_email
      # if we don't know the assessor, and the assessment was added by the system, ignore it
      return nil if email == User.system_user.email

      email
    end
  end
end
