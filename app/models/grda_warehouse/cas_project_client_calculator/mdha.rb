###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memoist'
module GrdaWarehouse::CasProjectClientCalculator
  class Mdha
    def value_for_cas_project_client(client:, column:)
      current_value = case column.to_sym
      when :match_group
        match_group(client)
      when *eccovia_columns
        send(column, client)
      end
      return current_value unless current_value.nil?

      client.send(column)
    end

    def description_for_column(column)
      GrdaWarehouse::Hud::Client.cas_columns_data.dig(column, :description)
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
      # TODO: return 1 if client has encampment decomissioning flag, once we have that data
      if client.veteran?
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
  end
end
