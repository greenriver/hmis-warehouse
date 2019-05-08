module Bo
  class ClientIdLookup
    # api_site_identifier is the numeral that represents the same connection
    # on the API side
    def initialize api_site_identifier:
      @api_site_identifier = api_site_identifier
      api_connect()
    end

    def api_connect
      key = ENV.fetch("ETO_API_SITE#{@api_site_identifier}")
      conf = EtoApi::Base.api_configs[key]
      @data_source_id = conf['data_source_id']
      @custom_config = GrdaWarehouse::EtoApiConfig.find_by(data_source_id: @data_source_id)

      @api = EtoApi::Detail.new(trace: @trace, api_connection: key)
      @api.connect

    end

    def fetch_client_modifications
      wsdl_url = ENV['BO_WSDL_URL_1']
      params = {
        wsdl: 1,
        cuid: ENV['BO_HMIS_PARTICIPANTS'],
      }
      url = wsdl_url + params.to_query

      client = Savon.client(wsdl: url)

      # client.operations
      # => [:run_query_as_a_service, :run_query_as_a_service_ex, :values_of_site_name]

      response = client.call(:run_query_as_a_service, message: { login: ENV['BO_USER_1'], password: ENV['BO_PASS_1'], Cms: ENV['BO_SERVER_1']});
      # Return the individual rows
      response.body[:run_query_as_a_service_response][:table][:row]
    end

    # This can be *very* slow
    def guid_lookup
      @guid_lookup ||= begin
        wsdl_url = ENV['BO_WSDL_URL_1']
        params = {
          wsdl: 1,
          cuid: ENV['BO_GUID_LOOKUP_1'],
        }
        url = wsdl_url + params.to_query
        client = Savon.client(wsdl: url, read_timeout: 600, log_level: :debug)
        response = client.call(:run_query_as_a_service, message: { login: ENV['BO_USER_1'], password: ENV['BO_PASS_1'], Cms: ENV['BO_SERVER_1'] });
        response.body[:run_query_as_a_service_response][:table][:row]
      end
    end

    def sites_and_participant_ids_by_guid
      @sites_and_participant_ids_by_guid ||= guid_lookup.map do |row|
        [row[:participant_enterprise_identifier], row]
      end.to_h
    end

    def site_id_for guid
      site_name = sites_and_participant_ids_by_guid[guid].try(:[], :site_name)
      site_id_from_name(site_name)
    end

    def testing
      wsdl_url = ENV['BO_WSDL_URL_1']
      params = {
        wsdl: 1,
        cuid: ENV['BO_TOUCHPOINT_RESPONSE_MODIFICATION_DATES_1'],
      }

      url = wsdl_url + params.to_query

      client = Savon.client(wsdl: url)

      puts client.operations
      # => [:run_query_as_a_service, :run_query_as_a_service_ex, :values_of_site_name]

      response = client.call(:run_query_as_a_service, message: { login: ENV['BO_USER_1'], password: ENV['BO_PASS_1'], Cms: ENV['BO_SERVER_1']});
      # response.body
    end

    def sites
      @sites ||= @api.sites
    end

    def site_id_from_name site_name
      @site_ids ||= sites.invert
      @site_ids[site_name]
    end
  end
end
