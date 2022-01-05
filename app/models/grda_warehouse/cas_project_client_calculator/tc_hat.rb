###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memoist'
module GrdaWarehouse::CasProjectClientCalculator
  class TcHat
    extend Memoist
    # A hook/wrapper to enable easily overriding how we get data for a given project client column
    # To use this efficiently, you'll probably want to preload a handful of data, see push_clients_to_cas.rb
    def value_for_cas_project_client(client:, column:)
      current_value = client.send(column)
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

    private def boolean_lookups
      {
        lifetime_sex_offender: 'is the client a lifetime sex',
        foster_care: 'in foster care as a youth',
        open_case: 'current open case',
      }.freeze
    end
    memoize :boolean_lookups

    private def section_titles
      {
        lifetime_sex_offender: 'Section B',
        foster_care: 'Section E',
        open_case: 'Section E',
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
      ]
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
      client.most_recent_tc_hat_for_destination.answer_from_section(relevant_section, question_title)&.downcase&.include?('family')
    end

    private def neighborhood_ids_for_cas(client)
      section_title = 'Section F'
      question_title = 'Housing Location Preference'

      relevant_section = client.most_recent_tc_hat_for_destination.
        section_starts_with(section_title)
      chosen_neighborhood = client.most_recent_tc_hat_for_destination.answer_from_section(relevant_section, question_title)
      Cas::Neighborhood.neighborhood_ids_from_names([chosen_neighborhood])
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
  end
end
