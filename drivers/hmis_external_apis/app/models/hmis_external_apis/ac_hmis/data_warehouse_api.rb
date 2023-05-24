###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class DataWarehouseApi
    SYSTEM_ID = 'ac_hmis_warehouse'.freeze

    def self.enabled?
      ::GrdaWarehouse::RemoteCredential.active.where(slug: SYSTEM_ID).exists?
    end

    # Returns the DW Client (Golden Record), for the specified mci_unique_id.
    def golden_client_by_mci_unique_id(mci_unique_id)
      conn.get("client/#{mci_unique_id}")
        .then { |r| handle_error(r) }
    end

    # Returns the client records, for all DW sources, for the specified
    # mci_unique_id.
    def clients_by_mci_unique_id(mci_unique_id)
      conn.get("clients/sources/#{mci_unique_id}")
        .then { |r| handle_error(r) }
    end

    # Returns the DW Client (Golden Record), for the specified SrcSysKey/ClientId.
    def client_by_client_id(client_id)
      conn.get("client/#{src_sys_key}/#{client_id}")
        .then { |r| handle_error(r) }
    end

    # Returns the client records, for the specified source, that have had
    # changes. Returns a paged cursor object ordered by lastModifiedDate in
    # descending order (most recent to least recent). Make repeated requests in
    # order to retrieve the changes through the desired point in time (up to 6
    # months of changes).
    def first_page_of_changes
      conn.get("clients/source/#{src_sys_key}/changes?incdemographic=N&inccontactinfo=N&incaddress=N")
        .then { |r| handle_error(r) }
    end

    def each_change(&block)
      page_count = 0
      record_count = 0

      catch :done do
        result = first_page_of_changes

        loop do
          page_count += 1

          result.parsed_body['data'].each do |record|
            block.call(record, record_count, page_count)
            record_count += 1
          end

          next_page = result.parsed_body.dig('paging', 'next')

          throw :done unless next_page.present?

          path = next_page.sub(conn.base_url, '')
          result = conn.get(path)
        end
      end
      return OpenStruct.new(record_count: record_count, page_count: page_count)
    end

    protected

    def src_sys_key
      creds.other_values('src_sys_key').tap do |val|
        raise 'You have to configure a src_sys_key in the remote credential' if val.nil?
        raise 'You have to configure a src_sys_key between 0 and 999' if val.to_i.negative? || val.to_i > 999
      end
    end

    def handle_error(result)
      raise HmisErrors::ApiError, result.error if result.error

      result
    end

    def creds
      @creds ||= ::GrdaWarehouse::RemoteCredential.active.where(slug: SYSTEM_ID).first!
    end

    def conn
      @conn ||= HmisExternalApis::OauthClientConnection.new(
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
