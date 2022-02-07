###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ObviousClientMatcher
  extend ActiveSupport::Concern

  included do
    private def clients
      @clients ||= hashed(client_destinations.pluck(*client_columns), client_columns)
    end

    # fetch a list of existing clients from the DND Warehouse DataSource (current destinations)
    private def client_destinations
      GrdaWarehouse::Hud::Client.destination
    end

    private def client_columns
      [
        :id,
        :FirstName,
        :LastName,
        :MiddleName,
        :SSN,
        :DOB,
      ]
    end

    private def hashed(results, columns)
      results.map do |row|
        Hash[columns.zip(row)]
      end
    end

    private def check_social(incoming_ssn, client_ssn)
      return false unless ::HUD.valid_social?(incoming_ssn)

      incoming_ssn == client_ssn
    end

    private def check_birthday(incoming_dob, client_dob)
      return false if incoming_dob.blank?

      incoming_dob == client_dob
    end

    private def check_name(incoming_first, incoming_last, client_first, client_last)
      "#{incoming_first} #{incoming_last}".downcase == "#{client_first} #{client_last}".downcase
    end

    def matching_clients(ssn:, dob:, first_name:, last_name:)
      ssn_matches = []
      birthdate_matches = []
      name_matches = []

      clients.select do |client|
        ssn_matches << client if check_social(ssn, client[:SSN])
        birthdate_matches << client if check_birthday(dob, client[:DOB])
        name_matches << client if check_name(first_name, last_name, client[:FirstName], client[:LastName])
      end

      ssn_matches + birthdate_matches + name_matches
    end
  end
end
