###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memery'
module GrdaWarehouse::CasProjectClientCalculator
  class Mdha < Default
    def value_for_cas_project_client(client:, column:)
      current_value = case column.to_sym
      when :match_group
        match_group(client)
      when :chronically_homeless_for_cas
        chronically_homeless_for_cas(client)
      when *eccovia_columns
        send(column, client)
      when :days_homeless
        days_homeless_plus_prior(client)
      end
      return current_value unless current_value.nil?

      client.send(column)
    end

    def chronically_homeless_for_cas(client)
      client.source_enrollments.map { |en| en&.ch_enrollment&.chronically_homeless_at_entry }.any?
    end

    private def custom_descriptions
      {
        email: 'Client email from the Eccovia API',
        home_phone: 'Client home phone from the Eccovia API',
        cell_phone: 'Client cell phone from the Eccovia API',
        default_shelter_agency_contacts: 'Client shelter agency contacts from the Eccovia API',
        most_recent_vispdat_score: 'Client most recent VI-SPDAT score from the Eccovia API',
        assessment_score_for_cas: 'Client most recent VI-SPDAT score from the Eccovia API',
        contact_info_for_rrh_assessment: 'Assessor email from the Eccovia API',
        cas_assessment_collected_at: 'Most recent assessment completion date',
        assessor_first_name: 'Most recent assessment assessor\'s first name',
        assessor_last_name: 'Most recent assessment assessor\'s last name',
        assessor_email: 'Most recent assessment assessor\'s email',
        match_group: 'Prioritization group',
      }.freeze
    end

    private def eccovia_columns
      return [] unless RailsDrivers.loaded.include?(:eccovia_data)

      [
        :email,
        :home_phone,
        :cell_phone,
        :default_shelter_agency_contacts,
        :most_recent_vispdat_score,
        :assessment_score_for_cas,
        :contact_info_for_rrh_assessment,
        :cas_assessment_collected_at,
        :assessor_first_name,
        :assessor_last_name,
        :assessor_email,
      ]
    end

    private def match_group(client)
      if client.encampment_decomissioned?
        1
      elsif client.veteran?
        2
      else
        3
      end
    end

    private def email(client)
      client.source_eccovia_client_contacts.map(&:email).reject(&:blank?).join(', ')
    end

    private def home_phone(client)
      client.source_eccovia_client_contacts.map(&:phone).reject(&:blank?).join(', ')
    end

    private def cell_phone(client)
      client.source_eccovia_client_contacts.map(&:cell).reject(&:blank?).join(', ')
    end

    private def default_shelter_agency_contacts(client)
      client.source_eccovia_case_managers.map(&:email).reject(&:blank?)
    end

    private def most_recent_vispdat_score(client)
      client.source_eccovia_assessments.max_by(&:assessed_at)&.score
    end

    private def assessment_score_for_cas(client)
      most_recent_vispdat_score(client)
    end

    private def cas_assessment_collected_at(client)
      client.source_eccovia_assessments.max_by(&:assessed_at)&.assessed_at
    end

    private def contact_info_for_rrh_assessment(client)
      assessor_email(client)
    end

    private def assessor_first_name(client)
      client.source_eccovia_assessments.max_by(&:assessed_at)&.assessor_name&.split(' ')&.first
    end

    private def assessor_last_name(client)
      client.source_eccovia_assessments.max_by(&:assessed_at)&.assessor_name&.split(' ')&.last
    end

    private def assessor_email(client)
      client.source_eccovia_assessments.max_by(&:assessed_at)&.assessor_email
    end

    private def days_homeless_plus_prior(client)
      homeless_days = client.days_homeless
      range = Date.yesterday .. Date.current
      # don't use source_enrollments.ongoing since we've already preloaded source_enrollments
      ongoing_enrollments = client.source_enrollments.select { |en| en.open_during_range?(range) }
      earliest_date_to_street = ongoing_enrollments.map(&:DateToStreetESSH).compact.min
      earliest_homeless_entry_date = ongoing_enrollments.select { |en| en.project.homeless? }&.map(&:EntryDate)&.min
      start_date = [earliest_date_to_street, earliest_homeless_entry_date, Date.current].compact.min
      end_date = [earliest_homeless_entry_date, Date.current].compact.min
      prior_days = (end_date - start_date).to_i.clamp(0..)
      homeless_days + prior_days
    end
  end
end
