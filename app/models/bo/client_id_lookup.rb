require 'qaaws'
module Bo
  class ClientIdLookup
    # api_site_identifier is the numeral that represents the same connection
    # on the API side
    def initialize api_site_identifier:, debug: true, start_time: 6.months.ago
      @api_site_identifier = api_site_identifier
      @start_time = start_time
      @debug = debug
      @api_config = api_config_from_site_identifier @api_site_identifier
      @data_source_id = @api_config['data_source_id']
      @config = Bo::Config.find_by(data_source_id: @data_source_id)
      api_connect()
    end

    def update_all!
      rebuild_eto_client_lookups
      rebuild_eto_touch_point_lookups
      # rebuild_subject_response_lookups
    end

    def api_config_from_site_identifier site_identifier
      key = ENV.fetch("ETO_API_SITE#{site_identifier}")
      EtoApi::Base.api_configs[key]
    end

    def api_connect
      key = ENV.fetch("ETO_API_SITE#{@api_site_identifier}")
      @custom_config = GrdaWarehouse::EtoApiConfig.find_by(data_source_id: @data_source_id)
      @api = EtoApi::Detail.new(trace: @trace, api_connection: key)
      @api.connect
    end

    def fetch_subject_response_lookup one_off: false
      client_config = {
        username: @config.user,
        password: @config.pass,
        endpoint: @config.url,
        cuid: @config.subject_response_lookup_cuid,
        # url_options: {authType: 'secEnterprise', locale: 'en_US', ConvertAnyType: 'false'},
      }
       message = {
        'login' => @config.user,
        'password' => @config.pass,
      }
      if one_off
        response = Qaaws.new(client_config).request(message)
      else
        response = call_with_retry(client_config, message)
      end
    end

    def fetch_client_lookup one_off: false, start_time: 1.weeks.ago.strftime('%FT%T.%L'), end_time: Time.now.strftime('%FT%T.%L')
      client_config = {
        username: @config.user,
        password: @config.pass,
        endpoint: @config.url,
        cuid: @config.client_lookup_cuid,
      }
      message = {
        'login' => @config.user,
        'password' => @config.pass,
        # 'Cms' => @config.server,
        'Enter_value_s__for__Date_Last_Updated___Start_' => start_time,
        'Enter_value_s__for__Date_Last_Updated___End_' => end_time,
      }
      if one_off
        response = Qaaws.new(client_config).request(message)
      else
        response = call_with_retry(client_config, message)
      end
    end

    def fetch_touch_point_modification_dates one_off: false, start_time: 1.weeks.ago.strftime('%FT%T.%L'), end_time: Time.now.strftime('%FT%T.%L')
      client_config = {
        username: @config.user,
        password: @config.pass,
        endpoint: @config.url,
        cuid: @config.touch_point_lookup_cuid,
      }
      message = {
        'login' => @config.user,
        'password' => @config.pass,
        # 'Cms' => @config.server,
        'Enter_value_s__for__Date_Last_Updated___Start_' => start_time,
        'Enter_value_s__for__Date_Last_Updated___End_' => end_time,
        # DEBUGGING line
        # 'Enter_value_s__for__TouchPoint_Unique_Identifier_' => [186],
        'Enter_value_s__for__TouchPoint_Unique_Identifier_' => touch_point_ids,
      }
      if one_off
        response = Qaaws.new(client_config).request(message)
      else
        response = call_with_retry(client_config, message)
      end
    end

    def week_ranges
      start_time = @start_time
      weeks = []
      while start_time < Date.today
        end_time = [start_time + 1.week, Time.now].min
        weeks << [start_time, end_time]
        start_time = end_time
      end
      return weeks
    end

    def fetch_batches_of_clients
      rows = []
      Rails.logger.info "Fetching #{week_ranges.count} batches of clients. From #{week_ranges.first.first} to #{week_ranges.last.last}" if @debug
      week_ranges.each_with_index do |(start_time, end_time), index|
        Rails.logger.info "Fetching #{index + 1} -- #{start_time} to #{end_time}" if @debug
        response = fetch_client_lookup(
          start_time: start_time,
          end_time: end_time
        )
        response_rows = response.raw_table if response.present?
        if response_rows.present?
          rows += response_rows
        end
      end
      return rows
    end

    def fetch_batches_of_touch_point_dates
      rows = []
      Rails.logger.info "Fetching #{week_ranges.count} batches of touch points. From #{week_ranges.first.first} to #{week_ranges.last.last}" if @debug
      week_ranges.each_with_index do |(start_time, end_time), index|
        Rails.logger.info "Fetching #{index + 1} -- #{start_time} to #{end_time}" if @debug
        response = fetch_touch_point_modification_dates(
          start_time: start_time,
          end_time: end_time
        )
        response_rows = response.raw_table if response.present?
        if response_rows.present?
          rows += response_rows
        end
      end
      return rows
    end

    def rebuild_subject_response_lookups
      @subject_rows = fetch_subject_response_lookup&.raw_table
      return unless @subject_rows.present?
      new_subjects = []
      @subject_rows.each do |row|
        new_subjects << GrdaWarehouse::EtoQaaws::SubjectResponseLookup.new(
          subject_id: row[:subject_identifier],
          response_id: row[:response_unique_identifier],
        )
        GrdaWarehouse::EtoQaaws::SubjectResponseLookup.transaction do
          GrdaWarehouse::EtoQaaws::SubjectResponseLookup.delete_all
          GrdaWarehouse::EtoQaaws::SubjectResponseLookup.import(new_subjects)
        end
      end

    end

    # Maintain the last six months of change records for clients
    def rebuild_eto_client_lookups
      @client_rows = fetch_batches_of_clients
      new_clients = []
      @client_rows.each do |row|
        site_id = site_id_from_name(row[:site_name])
        next if site_id.blank?
        guid = row[:participant_enterprise_identifier].gsub('-', '')
        client_id = client_ids_by_guid[guid]
        if Rails.env.development?
          client_id = client_ids_by_guid.values.sample
        end
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

    # Maintain the last 6 months of touch points
    def rebuild_eto_touch_point_lookups
      @touch_point_lookups = fetch_batches_of_touch_point_dates
      new_rows = []
      # new_rows should be authoritative for anything in this data source
      @touch_point_lookups.uniq.each do |row|
        guid = row[:participant_enterprise_identifier].gsub('-', '')
        client_id = client_ids_by_guid[guid]
        if Rails.env.development?
          client_id = client_ids_by_guid.values.sample
        end
        next if client_id.blank?
        new_rows << GrdaWarehouse::EtoQaaws::TouchPointLookup.new(
          data_source_id: @data_source_id,
          client_id: client_id,
          subject_id: row[:subject_identifier].to_i,
          site_id: site_id_from_name(row[:site_name]),
          assessment_id: row[:touch_point_unique_identifier].to_i,
          response_id: row[:response_unique_identifier].to_i,
          last_updated: row[:date_last_updated],
        )
      end
       GrdaWarehouse::EtoQaaws::TouchPointLookup.transaction do
        GrdaWarehouse::EtoQaaws::TouchPointLookup.where(data_source_id: @data_source_id).delete_all
        GrdaWarehouse::EtoQaaws::TouchPointLookup.import(new_rows)
      end
    end

    # Try a few times, re-try if we get some specific errors or the body is empty
    def call_with_retry client_options, message
      response = ''
      failures = 0
      while failures < 25
        begin
          response = Qaaws.new(client_options).request(message)
        rescue NoMethodError => e
          failures += 1
          Rails.logger.info "failed with NoMethodError, #{failures} failures; #{Qaaws.new(client_options).wsdl_location}"
          Rails.logger.debug e.inspect
          sleep (1..5).to_a.sample
        rescue Savon::InvalidResponseError => e
          failures += 1
          Rails.logger.info "failed with Savon::InvalidResponseError, #{failures} failures; #{Qaaws.new(client_options).wsdl_location}"
          Rails.logger.debug e.inspect
          sleep (1..5).to_a.sample
        rescue Qaaws::QaawsError => e
          failures += 1
          Rails.logger.info "failed with Qaaws::QaawsError, #{failures} failures; #{Qaaws.new(client_options).wsdl_location}"
          Rails.logger.debug e.inspect
          sleep (1..5).to_a.sample
        end
        if response.present?
          break
        end
      end
      return response
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
