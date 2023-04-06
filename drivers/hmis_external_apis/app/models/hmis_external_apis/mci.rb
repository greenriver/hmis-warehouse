###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  class Mci
    # Performing "clearance"
    #
    # Input: Hmis::Hud::Client instance, which may or may not be persisted yet.
    # Returns: the API response (1-N clients with their scores), which we will resolve as a GraphQL type, according to the openapi structure (see comment below, I don't think we want to transform it too much/ at all)
    # Behavior: Just does the clearance and returns the response. Probably we
    # log the request and response body somewhere, Elliot and I were discussing
    # that.
    def clearance(client)
      # FIXME: Is this the right way to determine this?
      gender_code =
        if client.female?
          gender(word: 'Female')
        elsif client.male?
          gender(word: 'Male')
        else
          gender(word: 'Unknown')
        end

      payload = {
        "firstName": client.first_name,
        # "firstNameSearchCriteria" => 0, # FIXME: No documentation for how to use this
        "middleName": client.middle_name,
        # "middleNameSearchCriteria": 0,  # FIXME: No documentation for how to use this
        "lastName": client.last_name,
        # "lastNameSearchCriteria": 0,    # FIXME: No documentation for how to use this
        "ssn": client.ssn, # FIXME: Is this the correct ssn field?
        "genderCode": gender_code,
        # "dobFrom": "string",
        # "dobTo": "string",
        "birthDate": (client.dob.present? and client.dob.to_s(:db) + 'T00:00:00'),
        'searchWithOR' => 0,
      }

      conn.post('clients/v1/api/clients/clearance', payload)
    end

    # Creating a client
    #
    # Input: Hmis::Hud::Client instance (persisted)
    # Returns: client
    # Behavior: Hit createclient with any demographic info you can get off the
    # Client, store the MCI ID (needs a DB update
    # https://www.pivotaltracker.com/story/show/184816322), and return the
    # client
    def create_mci_id(client)
      # FIXME: check if client has mci id first and abort if it does
      # FIXME:

      payload = MciPayload.from_client(client)
      result = conn.post('clients/v1/api/clients/newclient', payload)

      ap result

      # mci_id = result.parsed_payload

      # FIXME: pseudo-code:
      # client.mci_external_ids.build(external_id: mci_id)
      # ...

      client
    end

    # Updating client
    #
    # Input: Hmis::Hud::Client instance (that has an MCI ID attached to it)
    # Returns: client
    # Behavior: Hit updateclient with any demographic info you can get off the
    # Client, log the request, return
    def update_client(client)
      payload = MciPayload.from_client(client)
      result = conn.post('clients/v1/api/clients/updateclient', payload)

      ap result

      client
    end

    # Input: list of MCI ids
    # Returns: list of Hmis::Hud::Clients
    # Behavior: For each MCI ID, first check if we have a Client with that MCI
    # ID already. If we do, include that in the response. If we don't, call the
    # MCI ID lookup endpoint and new up a Hmis::Hud::Client.
    def get_clients_by_mci_ids(mci_ids)
      clients = Hmis::Hud::Client.where(mci_id: mci_ids).order(:mci_id).to_a
      new_clients = []

      # FIXME: This is just a naïve implementation until I know how to batch
      # requests
      mci_ids.each do |mci_id|
        next if clients.bsearch { |c| c.mci_id == mci_id }

        result = conn.get("clients/v1/api/Clients/#{mci_id}")

        new_clients << MciPayload.build_client(result.parsed_body)
      end

      clients + new_clients
    end

    # def search
    #   payload = {}
    #   conn.post('clients/v1/api/Clients/search', payload)
    # end

    def table_values(table_name)
      value = table_name.upcase.gsub(/[^A-Z_]/, '')
      result = conn.get("clients/v1/api/Lookup/#{value}")

      result.parsed_body.map { |x| [x['key'], x['value']] }.to_h
    end

    def gender(code: nil, word: nil)
      @gender_lookup ||= table_values('GENDER')
      @gender_lookup_inverted ||= @gender_lookup.invert

      raise 'Only specify code or word' if code.present? && word.present?

      code.present? ? @gender_lookup[code.to_s] : @gender_lookup_inverted[word]
    end

    def lookup_tables
      conn.get('clients/v1/api/Lookup/logicalTables')
    end

    private

    def conn
      @conn ||=
        begin
          creds = GrdaWarehouse::RemoteCredentials::Oauth.find_by(slug: 'mci')

          OauthClientConnection.new(
            client_id: creds.client_id,
            client_secret: creds.client_secret,
            token_url: creds.token_url,
            base_url: creds.base_url,
            headers: creds.additional_headers,
            scope: creds.oauth_scope,
          )
        end
    end
  end
end
