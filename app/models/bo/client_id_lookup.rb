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

    # Try a few times, re-try if we get some specific errors or the body is empty
    def call_with_retry client, options
      response = ''
      failures = 0
      while failures < 25
        begin
          puts "attempting to call #{client.wsdl.document}"
          response = client.call(*options)
        rescue NoMethodError => e
          failures += 1
          Rails.logger.info "failed with NoMethodError, #{failures} failures; #{client.wsdl.document}"
          Rails.logger.debug e.inspect
          sleep 5
        rescue Savon::InvalidResponseError => e
          failures += 1
          Rails.logger.info "failed with Savon::InvalidResponseError, #{failures} failures; #{client.wsdl.document}"
          Rails.logger.debug e.inspect
          sleep 5
        end
        if response.present? && response.body.present?
          break
        end
      end
      return response
    end

    def fetch_client_lookup
      wsdl_url = ENV['BO_WSDL_URL_1']
      url = wsdl_url + { cuid: ENV['BO_CLIENT_LOOKUP_WSDL_1'] }.to_query
      client = Savon.client(
        wsdl: url,
        open_timeout: 5,
        read_timeout: 2_400,
        log_level: :debug,
        log: true,
        filters: [:password]
      )

      response = call_with_retry(client, [
        :run_query_as_a_service,
          message: {
            'login' => ENV['BO_USER_1'],
            'password' => ENV['BO_PASS_1'],
            'Cms' => ENV['BO_SERVER_1'],
          }
        ]
      )
    end

    def fetch_client_lookup_manual start_time: 1.weeks.ago.strftime('%FT%T.%L'), end_time: Time.now.strftime('%FT%T.%L')
      wsdl_url = ENV['BO_WSDL_URL_1']
      url = wsdl_url + { cuid: ENV['BO_CLIENT_LOOKUP_STANDARD_1'], timeout: 600 }.to_query
      client = Savon.client(
        wsdl: url,
        open_timeout: 5,
        read_timeout: 2_400,
        log_level: :debug,
        log: true,
        filters: [:password]
      )
      response = client.call(
        :run_query_as_a_service,
        message: {
          'login' => ENV['BO_USER_1'],
          'password' => ENV['BO_PASS_1'],
          'Cms' => ENV['BO_SERVER_1'],
          'Enter_value_s__for__Date_Last_Updated___Start_' => start_time,
          'Enter_value_s__for__Date_Last_Updated___End_' => end_time,
        }
      )
    end

    def fetch_touch_point_modification_dates start_time: 1.weeks.ago.strftime('%FT%T.%L'), end_time: Time.now.strftime('%FT%T.%L')
      wsdl_url = ENV['BO_WSDL_URL_1']
      url = wsdl_url + { cuid: ENV['BO_DISTINCT_TOUCH_POINT_RESPONSE_MODIFICATION_DATES_1'] }.to_query
      client = Savon.client(
        wsdl: url,
        open_timeout: 5,
        read_timeout: 2_400,
        log_level: :debug,
        log: true,
        filters: [:password]
      )

      response = call_with_retry(client, [
        :run_query_as_a_service,
        message: {
         'login' => ENV['BO_USER_1'],
          'password' => ENV['BO_PASS_1'],
          'Cms' => ENV['BO_SERVER_1'],
          'Enter_value_s__for__Date_Last_Updated___Start_' => start_time,
          'Enter_value_s__for__Date_Last_Updated___End_' => end_time,
          # FIXME:
          'Enter_value_s__for__TouchPoint_Unique_Identifier_' => [186],
          # 'Enter_value_s__for__TouchPoint_Unique_Identifier_' => touch_point_ids,
          TouchPoint_Unique_Identifier: 143,
        }
      ])
    end

    def fetch_touch_point_modification_dates_manual start_time: 1.weeks.ago.strftime('%FT%T.%L'), end_time: Time.now.strftime('%FT%T.%L')
      wsdl_url = ENV['BO_WSDL_URL_1']
      url = wsdl_url + { cuid: ENV['BO_DISTINCT_TOUCH_POINT_RESPONSE_MODIFICATION_DATES_1'] }.to_query
      client = Savon.client(
        wsdl: url,
        open_timeout: 5,
        read_timeout: 2_400,
        log_level: :debug,
        log: true,
        filters: [:password]
      )

       response = client.call(
        :run_query_as_a_service,
        message: {
          'login' => ENV['BO_USER_1'],
          'password' => ENV['BO_PASS_1'],
          'Cms' => ENV['BO_SERVER_1'],
          'Enter_value_s__for__Date_Last_Updated___Start_' => start_time,
          'Enter_value_s__for__Date_Last_Updated___End_' => end_time,
          # FIXME:
          'Enter_value_s__for__TouchPoint_Unique_Identifier_' => [186],
          # 'Enter_value_s__for__TouchPoint_Unique_Identifier_' => touch_point_ids,
          TouchPoint_Unique_Identifier: 143,
        }
      )

    end

    def rebuild_eto_client_lookups
      response = fetch_client_lookup
      rows = response.body[:run_query_as_a_service_response][:table][:row]
      new_clients = []
      rows.each do |row|
        site_id = site_id_from_name(row[:site_name])
        next if site_id.blank?
        guid = row[:participant_enterprise_identifier].gsub('-', '')
        client_id = client_ids_by_guid[guid]
        next if client_id.blank?

        new_clients << GrdaWarehouse::EtoQaaws::ClientLookup.new(
          data_source_id: @data_source_id,
          client_id: client_id,
          enterprise_guid: guid,
          participant_site_identifier: row[:participant_site_identifier].to_i,
          site_id: site_id_from_name(row[:site_name]),
          subject_id: row[:subject_unique_identifier].to_i,
          last_updated: row[:date_last_updated],
        )
      end
      GrdaWarehouse::EtoQaaws::ClientLookup.transaction do
        GrdaWarehouse::EtoQaaws::ClientLookup.where(data_source_id: @data_source_id).delete_all
        GrdaWarehouse::EtoQaaws::ClientLookup.import(new_clients)
      end
    end

    def rebuild_eto_touch_point_lookups
      response = fetch_touch_point_modification_dates
      rows = response.body[:run_query_as_a_service_response][:table][:row]
      new_rows = []
      existing_rows = []
      # TODO: figure out match to existing and which we don't already have
      # remove any we already have, then insert both batches
      # uniq one data_source_id, subject_id, response_id
      rows.uniq.each do |row|

      end
    end

    def existing_eto_touch_point_lookups
      @existing_eto_touch_point_lookups ||= GrdaWarehouse::EtoQaaws::TouchPointLookup.where(data_source_id: @data_source_id).distinct.pluck(:subject_id, :response_id)
    end

    def touch_point_ids
      @touch_point_ids ||= GrdaWarehouse::HMIS::Assessment.fetch_for_data_source(@data_source_id).
        distinct.
        pluck(:assessment_id)
    end

    def client_ids_by_guid
      @client_ids_by_guid ||= GrdaWarehouse::Hud::Client.
        where(data_source_id: @data_source_id).pluck(:PersonalID, :id).to_h
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
