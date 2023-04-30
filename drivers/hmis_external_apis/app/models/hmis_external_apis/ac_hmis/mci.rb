###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# To connect to the API, you need a remote credential labeled 'mci'. Replace
# the empty strings below with values from the documentation.
#
#  creds = GrdaWarehouse::RemoteCredentials::Oauth.where(slug: 'mci').first_or_initialize
#
#  creds.client_id = ''
#  creds.client_secret = ''
#  creds.oauth_scope = 'API_TEST'
#  creds.token_url = ''
#  creds.base_url = ''
#  creds.additional_headers = {
#    'Ocp-Apim-Subscription-Key' => ''
#  }
#
#  Then
#
#  mci = HmisExternalApis::AcHmis::Mci.new

module HmisExternalApis::AcHmis
  class Mci
    SYSTEM_ID= 'ac_hmis_mci'.freeze
    Error = StandardError.new

    # Perform "clearance" to find potential matches for a client in MCI
    #
    # @param client [Hmis::Hud::Client] client, which may or may not be persisted
    # @return [Array{HmisExternalApis::AcHmis::MciClearanceResult}]
    def clearance(client)
      payload = {
        **MciPayload.from_client(client).slice(
          'firstName',
          'middleName',
          'lastName',
          'ssn',
          'birthDate',
          'genderCode',
        ),
        'searchWithOR' => 0,
        # "firstNameSearchCriteria" => 0, # FIXME: No documentation for how to use this
        # "middleNameSearchCriteria": 0,  # FIXME: No documentation for how to use this
        # "lastNameSearchCriteria": 0,    # FIXME: No documentation for how to use this
      }
      result = conn.post('clients/v1/api/clients/clearance', payload)

      save_log!(result, payload)

      raise(Error, result.error) if result.error

      Rails.logger.info "Did clearance for client #{client.id}"

      result.parsed_body.map do |clearance_result|
        mci_id = clearance_result['mciId'].to_s
        score = clearance_result['score'].to_i
        MciClearanceResult.new({
                                 mci_id: mci_id,
                                 score: score,
                                 client: MciPayload.build_client(clearance_result),
                                 # TODO: if no exact match by MCI ID, look for match by MCI Unique ID
                                 existing_client_id: find_client_by_mci(mci_id)&.id,
                               })
      end
    end

    # Create a new MCI ID for a client
    #
    # @param client [Hmis::Hud::Client] Persisted client
    # @return [Hmis::Hud::Client] Client with MCI ID attached
    def create_mci_id(client)
      raise(Error, 'Client needs to be saved first') unless client.persisted?

      external_id = get_external_id(client)

      raise(Error, 'Client already has an MCI id') if external_id

      payload = MciPayload.from_client(client, mci_id: nil)

      endpoint = 'clients/v1/api/clients/newclient'
      result = conn.post(endpoint, payload)

      if result.error
        save_log!(result, payload)

        raise(Error, result.error['detail']) if result.error
      else
        # Store MCI ID for client
        # TODO: store MCI Unique ID as well
        external_id = create_external_id(
          source: client,
          value: result.parsed_body,
          external_request_log: save_log!(result, payload),
        )
      end

      Rails.logger.info "Gave client #{client.id} an external ID with primary key of #{external_id.id}"

      client
    end

    # Update client details in MCI
    #
    # @param client [Hmis::Hud::Client]
    # @return [Hmis::Hud::Client]
    def update_client(client)
      raise(Error, 'Client needs to be saved first') unless client.persisted?

      external_id = get_external_id(client)

      raise(Error, 'Client must already have an MCI id') if external_id.nil?

      payload = MciPayload.from_client(client, mci_id: external_id.value)

      result = conn.post('clients/v1/api/clients/updateclient', payload)

      save_log!(result, payload)

      raise(Error, result.error) if result.error

      Rails.logger.info "Updated MCI information for client #{client.id} with external ID with primary key of #{external_id.id}"

      client
    end

    # def table_values(table_name)
    #   value = table_name.upcase.gsub(/[^A-Z_]/, '')
    #   result = conn.get("clients/v1/api/Lookup/#{value}")

    #   result.parsed_body.map { |x| [x['key'], x['value']] }.to_h
    # end

    # def gender(code: nil, word: nil)
    #   @gender_lookup ||= table_values('GENDER')
    #   @gender_lookup_inverted ||= @gender_lookup.invert

    #   raise(Error, 'Only specify code or word') if code.present? && word.present?

    #   code.present? ? @gender_lookup[code.to_s] : @gender_lookup_inverted[word]
    # end

    # def lookup_tables
    #   conn.get('clients/v1/api/Lookup/logicalTables')
    # end

    def self.enabled?
      ::GrdaWarehouse::RemoteCredentials::Oauth.active.where(slug: SYSTEM_ID).exists?
    end

    # returns the first client record matching this MCI Id
    # @param mci_id [String]
    # @return [Hmis::Hud::Client, nil]
    def find_client_by_mci(mci_id)
      # If multiple clients with this mci id, choose client with earliest creation date
      client_scope
        .order(DateCreated: :asc)
        .first_by_external_id(namespace: SYSTEM_ID, value: mci_id)
    end

    # @param source [ApplicationRecord]
    # @param value [String]
    # @return [HmisExternalApis::ExternalId]
    def create_external_id(source:, value:, **attrs)
      external_ids.create!(source: source, value: value, remote_credential: creds, **attrs)
    end

    private

    def external_ids
      HmisExternalApis::ExternalId.where(namespace: SYSTEM_ID)
    end

    def save_log!(result, payload)
      ExternalRequestLog.create!(
        initiator: creds,
        content_type: result.content_type,
        http_method: result.http_method,
        ip: result.ip,
        request_headers: result.request_headers,
        request: payload,
        response: result.body,
        requested_at: Time.now,
        url: result.url,
      )
    end

    def get_external_id(source)
      external_ids.where(source: source).first
    end

    def creds
      @creds ||= ::GrdaWarehouse::RemoteCredential.active.where(slug: SYSTEM_ID).first!
    end

    def conn
      @conn ||=
        OauthClientConnection.new(
          client_id: creds.client_id,
          client_secret: creds.client_secret,
          token_url: creds.token_url,
          base_url: creds.base_url,
          headers: creds.additional_headers,
          scope: creds.oauth_scope,
        )
    end

    def client_scope
      ::Hmis::Hud::Client.where(data_source: data_source)
    end

    def data_source
      @data_source ||= HmisExternalApis::AcHmis.data_source
    end
  end
end
