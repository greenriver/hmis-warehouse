###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memery'
module GrdaWarehouse::CasProjectClientCalculator
  class TcHat < Default
    include ArelHelper
    include Memery
    # A hook/wrapper to enable easily overriding how we get data for a given project client column
    # To use this efficiently, you'll probably want to preload a handful of data, see push_clients_to_cas.rb
    def value_for_cas_project_client(client:, column:)
      current_value = client.send(column)
      # overrides even if we don't have a TC HAT
      current_value = send(column, client) if column.in?(local_calculators)
      # Return existing value if we don't have anything in the new format
      return current_value unless client.most_recent_tc_hat_for_destination.present?

      case column
      when *boolean_lookups.keys
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
      }.freeze
    end

    private def boolean_lookups
      {
        lifetime_sex_offender: 'is the client a lifetime sex',
        foster_care: 'in foster care as a youth',
        open_case: 'current open case',
        drug_test: 'pass a drug test',
        heavy_drug_use: 'heavy drug use',
        sober: 'sober for at least one year',
        willing_case_management: 'engage with housing case management',
        employed_three_months: 'employed for 3 months',
        living_wage: 'an hour or more',
        need_daily_assistance: 'check this box if you feel the client is unable to live alone',
        full_time_employed: 'currently working a full time',
        can_work_full_time: 'client able to work a full-time',
        willing_to_work_full_time: 'willing to work a full-time',
        rrh_successful_exit: 'successfully exit 12-24 month rrh',
        th_desired: 'interested in transitional housing',
        site_case_management_required: 'client need site-based case management',
        ongoing_case_management_required: 'client need ongoing housing case management',
        currently_fleeing: 'are you currently fleeing',
        cas_pregnancy_status: 'Are you currently pregnant?',
      }.freeze
    end
    memoize :boolean_lookups

    private def section_titles
      {
        lifetime_sex_offender: 'Section B',
        foster_care: 'Section E',
        open_case: 'Section E',
        drug_test: 'Section C',
        heavy_drug_use: 'Section C',
        sober: 'Section C',
        willing_case_management: 'Section C',
        employed_three_months: 'Section C',
        living_wage: 'Section C',
        need_daily_assistance: 'PAGE #1',
        full_time_employed: 'Section C',
        can_work_full_time: 'Section C',
        willing_to_work_full_time: 'Section C',
        rrh_successful_exit: 'Section C',
        th_desired: 'Section C',
        site_case_management_required: 'Section D',
        ongoing_case_management_required: 'Section D',
        currently_fleeing: 'Section E',
        cas_pregnancy_status: 'Section E',
      }
    end

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
        :cas_pregnancy_status,
      ]
    end

    def most_recent_assessment_for_destination(client)
      return unless client.present?

      cas_assessment_collected_at(client)&.to_date&.to_s
    end

    private def for_boolean(client, key)
      section_title = section_titles[key]
      question_title = boolean_lookups[key]

      relevant_section = client.most_recent_tc_hat_for_destination.
        section_starts_with(section_title)
      client.most_recent_tc_hat_for_destination.answer_from_section(relevant_section, question_title)&.downcase == 'yes'
    end

    private def family_member(client)
      section_title = 'PAGE #1'
      question_title = 'Household Type'

      relevant_section = client.most_recent_tc_hat_for_destination.
        section_starts_with(section_title)
      family = client.most_recent_tc_hat_for_destination.answer_from_section(relevant_section, question_title)&.downcase&.include?('family')
      youth = client.most_recent_tc_hat_for_destination.answer_from_section(relevant_section, question_title)&.downcase&.include?('youth')

      question_title = 'Are you a single parent with a child over the age of 10?'
      single_parent = client.most_recent_tc_hat_for_destination.answer_from_section(relevant_section, question_title)&.downcase&.include?('yes')

      question_title = 'Do you have legal custody'
      custody_now = client.most_recent_tc_hat_for_destination.answer_from_section(relevant_section, question_title)&.downcase&.include?('yes')

      question_title = 'If you do not have legal custody'
      custody_later = client.most_recent_tc_hat_for_destination.answer_from_section(relevant_section, question_title)&.downcase&.include?('yes')

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
      section_title = 'PAGE #1'
      question_title = 'How many household members'
      relevant_section = client.most_recent_tc_hat_for_destination.
        section_starts_with(section_title)
      client.most_recent_tc_hat_for_destination.answer_from_section(relevant_section, question_title).to_i
    end

    private def required_minimum_occupancy(client)
      household_size(client)
    end

    private def required_number_of_bedrooms(client)
      num = 1
      num = 2 if tc_hat_single_parent_child_over_ten(client)

      num = case household_size(client)
      # when 1, 2 # unnecessary, these would result in 1 bedroom
      when 3, 4
        2
      when (5..)
        3
      else
        num
      end
      num
    end

    private def tc_hat_single_parent_child_over_ten(client)
      section_title = 'PAGE #1'
      question_title = 'Are you a single parent with'
      relevant_section = client.most_recent_tc_hat_for_destination.
        section_starts_with(section_title)
      client.most_recent_tc_hat_for_destination.answer_from_section(relevant_section, question_title)&.downcase&.include?('yes')
    end

    private def neighborhood_ids_for_cas(client)
      section_title = 'Section F'
      question_title = 'Housing Location Preference'

      relevant_section = client.most_recent_tc_hat_for_destination.
        section_starts_with(section_title)
      chosen_neighborhood = client.most_recent_tc_hat_for_destination.answer_from_section(relevant_section, question_title)
      CasAccess::Neighborhood.neighborhood_ids_from_names([chosen_neighborhood])
    end

    private def strengths(client)
      section_title = 'Section B'
      question_title = 'Strengths'

      relevant_section = client.most_recent_tc_hat_for_destination.
        section_starts_with(section_title)
      client.most_recent_tc_hat_for_destination.answer_from_section(relevant_section, question_title)&.
        downcase&.
        split('|')&.
        reject(&:blank?)
    end

    private def challenges(client)
      section_title = 'Section B'
      question_title = 'Possible challenges'

      relevant_section = client.most_recent_tc_hat_for_destination.
        section_starts_with(section_title)
      client.most_recent_tc_hat_for_destination.answer_from_section(relevant_section, question_title)&.
        downcase&.
        split('|')&.
        reject(&:blank?)
    end

    private def housing_for_formerly_homeless(client)
      section_title = 'Section E'
      question_title = 'Housing Preference'

      relevant_section = client.most_recent_tc_hat_for_destination.
        section_starts_with(section_title)
      client.most_recent_tc_hat_for_destination.answer_from_section(relevant_section, question_title)&.include?('with others who are formerly homeless')
    end

    private def dv_date(client)
      section_title = 'Section E'
      question_title = 'most recent date the violence occurred'

      relevant_section = client.most_recent_tc_hat_for_destination.
        section_starts_with(section_title)
      client.most_recent_tc_hat_for_destination.answer_from_section(relevant_section, question_title).presence&.to_date
    end

    private def cas_assessment_collected_at(client)
      client.most_recent_tc_hat_for_destination&.collected_at
    end

    private def days_homeless_in_last_three_years_cached(client)
      days = 0
      days += client.tc_hat_additional_days_homeless

      days + (client.processed_service_history&.days_homeless_last_three_years || 0)
    end

    private def literally_homeless_last_three_years_cached(client)
      days = 0
      days += client.tc_hat_additional_days_homeless

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
      section_title = 'Section C'
      question_title = 'currently working a full time job'

      form = client.most_recent_tc_hat_for_destination
      relevant_section = form.section_starts_with(section_title)
      full_time_employed = form.answer_from_section(relevant_section, question_title) == 'Yes'

      question_title = 'successfully exit 12-24 month RRH'
      rrh_successful_exit = form.answer_from_section(relevant_section, question_title) == 'Yes'
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
  end
end
