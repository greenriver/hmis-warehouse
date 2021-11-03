###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Bo
  class ClientIdLookup
    include NotifierConfig
    attr_accessor :send_notifications, :notifier_config, :notifier
    attr_reader :data_source_id

    # api_site_identifier is the numeral that represents the same connection
    # on the API side
    def initialize(data_source_id:, debug: true, start_time: 6.months.ago, force_disability_verification: false)
      @data_source_id = data_source_id
      @start_time = start_time
      @debug = debug
      @force_disability_verification = force_disability_verification
      (@api_site_identifier, @api_config) = api_config_from_data_source_id(@data_source_id)

      @config = Bo::Config.find_by(data_source_id: @data_source_id)
      setup_notifier('ETO QaaWS Importer')
      api_connect
    end

    def update_all!
      rebuild_eto_client_lookups
      rebuild_eto_touch_point_lookups
      # rebuild_subject_response_lookups
      set_disability_verifications
    end

    def fetch_site_touch_point_map(one_off: false)
      return unless @config.site_touch_point_map_cuid.present?

      settings = {
        url: "#{@config.url}?wsdl=1&cuid=#{@config.site_touch_point_map_cuid}",
        method: :site_touch_point_lookup,
      }
      message_options = {}
      if one_off
        call_once(settings, message_options)
      else
        call_with_retry(settings, message_options)
      end
    end

    # def api_config_from_site_identifier(site_identifier)
    #   key = ENV.fetch("ETO_API_SITE#{site_identifier}")
    #   EtoApi::Base.api_configs[key]
    # end

    def api_config_from_data_source_id(data_source_id)
      EtoApi::Base.api_config_for_data_source_id(data_source_id)
    end

    def api_connect
      @custom_config = GrdaWarehouse::EtoApiConfig.active.find_by(data_source_id: @data_source_id)
      @api = EtoApi::Detail.new(trace: @trace, api_connection: @api_site_identifier)
      @api.connect
    end

    def fetch_subject_response_lookup(one_off: false)
      settings = {
        url: "#{@config.url}?wsdl=1&cuid=#{@config.subject_response_lookup_cuid}",
        method: :response_lookup,
      }
      message_options = {}
      if one_off
        call_once(settings, message_options)
      else
        call_with_retry(settings, message_options)
      end
    end

    def fetch_client_lookup(one_off: false, start_time: 1.weeks.ago, end_time: Time.now)
      settings = {
        url: "#{@config.url}?wsdl=1&cuid=#{@config.client_lookup_cuid}",
        method: :client_lookup_standard,
      }
      message_options = {
        start_time: start_time,
        end_time: end_time,
      }

      if one_off
        call_once(settings, message_options)
      else
        call_with_retry(settings, message_options)
      end
    end

    def fetch_touch_point_modification_dates(one_off: false, start_time: 1.weeks.ago, end_time: Time.now, tp_id:)
      settings = {
        url: "#{@config.url}?wsdl=1&cuid=#{@config.touch_point_lookup_cuid}",
        method: :distinct_touch_point_lookup,
      }
      message_options = {
        start_time: start_time,
        end_time: end_time,
        touch_point_id: tp_id,
      }

      if one_off
        soap = Bo::Soap.new(username: @config.user, password: @config.pass)
        soap.distinct_touch_point_lookup settings[:url]
      else
        call_with_retry(settings, message_options)
      end
    end

    def week_ranges
      start_time = @start_time
      weeks = []
      while start_time < Date.current
        end_time = [start_time + 1.months, Time.now].min
        weeks << [start_time, end_time]
        start_time = end_time
      end
      weeks
    end

    def fetch_batches_of_clients
      rows = []
      msg = "Fetching #{week_ranges.count} #{'batch'.pluralize(week_ranges.count)} of clients. From #{week_ranges.first.first} to #{week_ranges.last.last}"
      Rails.logger.info msg
      @notifier.ping msg if send_notifications && msg.present?
      week_ranges.each_with_index do |(start_time, end_time), index|
        Rails.logger.info "Fetching #{index + 1} -- #{start_time} to #{end_time}" if @debug
        response = fetch_client_lookup(
          start_time: start_time,
          end_time: end_time,
        )
        response_rows = response if response.present?
        rows += response_rows if response_rows.present?
      end
      msg = 'Fetched batches of clients.'
      Rails.logger.info msg
      @notifier.ping msg if send_notifications && msg.present?
      rows
    end

    def fetch_batches_of_touch_point_dates
      rows = []
      total_batches = week_ranges.count * touch_point_ids.count
      msg = "Fetching #{total_batches} #{'batch'.pluralize(week_ranges.count)} of touch points. From #{week_ranges.first.first} to #{week_ranges.last.last} for data source #{@data_source_id}"
      Rails.logger.info msg
      @notifier.ping msg if send_notifications && msg.present?
      week_ranges.each_with_index do |(start_time, end_time), index|
        # fetch responses for one touch point at a time to avoid timeouts
        touch_point_ids.each_with_index do |tp_id, tp_index|
          Rails.logger.info "Fetching batch #{(index * week_ranges.count) + (tp_index + 1)} (TP: #{tp_id}) -- #{start_time} to #{end_time} for data source #{@data_source_id}" if @debug
          begin
            response = fetch_touch_point_modification_dates(
              start_time: start_time,
              end_time: end_time,
              tp_id: tp_id,
            )
          rescue Bo::Soap::RequestFailed => e
            msg = "FAILED to fetch batch #{start_time} .. #{end_time} for TP: #{tp_id} \n #{e.message} for data source #{@data_source_id}"
            Rails.logger.info msg
            @notifier.ping msg if send_notifications && msg.present?

            response = nil
          end
          rows += response if response.present?
        end
      end
      msg = "Fetched batches of touch points. Found #{rows.count} touch point responses for data source #{@data_source_id}"
      Rails.logger.info msg
      @notifier.ping msg if send_notifications && msg.present?
      rows
    end

    def rebuild_subject_response_lookups
      @subject_rows = fetch_subject_response_lookup
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

        guid = row[:participant_enterprise_identifier].delete('-')
        client_id = client_ids_by_guid[guid]
        # debugging
        # if Rails.env.development?
        #   client_id = client_ids_by_guid.values.sample
        # end
        # end debugging
        next if client_id.blank?

        new_clients << GrdaWarehouse::EtoQaaws::ClientLookup.new(
          data_source_id: @data_source_id,
          client_id: client_id,
          enterprise_guid: guid,
          participant_site_identifier: row[:participant_site_identifier].to_i,
          site_id: site_id_from_name(row[:site_name]),
          subject_id: row[:subject_unique_identifier].to_i,
          last_updated: row[:date_last_updated].to_time.localtime,
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
        next if row[:participant_enterprise_identifier].blank?

        guid = row[:participant_enterprise_identifier].delete('-')
        client_id = client_ids_by_guid[guid]
        # Debugging
        client_id = client_ids_by_guid.values.sample if Rails.env.development?
        # END Debugging
        next if client_id.blank?
        next if row[:date_last_updated].blank?

        new_rows << GrdaWarehouse::EtoQaaws::TouchPointLookup.new(
          data_source_id: @data_source_id,
          client_id: client_id,
          subject_id: row[:subject_identifier].to_i,
          site_id: site_id_from_name(row[:site_name]),
          assessment_id: row[:touchpoint_unique_identifier].to_i,
          response_id: row[:response_unique_identifier].to_i,
          last_updated: row[:date_last_updated].to_time.localtime,
        )
      end
      GrdaWarehouse::EtoQaaws::TouchPointLookup.transaction do
        GrdaWarehouse::EtoQaaws::TouchPointLookup.where(data_source_id: @data_source_id).delete_all
        GrdaWarehouse::EtoQaaws::TouchPointLookup.import(new_rows)
      end
    end

    def call_once(settings, message_options)
      soap = Bo::Soap.new(username: @config.user, password: @config.pass)
      soap.send(settings[:method], settings[:url], message_options)
    end

    # Try a few times, re-try if we get some specific errors or the body is empty
    def call_with_retry(settings, message_options)
      response = ''
      failures = 0
      while failures < 25
        begin
          soap = Bo::Soap.new(username: @config.user, password: @config.pass)
          response = soap.send(settings[:method], settings[:url], message_options)
        rescue NoMethodError => e
          failures += 1
          Rails.logger.info "failed with NoMethodError, #{failures} failures; #{settings[:url]}"
          Rails.logger.debug e.inspect
          sleep((1..5).to_a.sample)
          next
        end
        break if response.present?

        msg = "FAILURE: unable to successfully fetch #{settings[:url]}; response blank; options: #{message_options.inspect}"
        Rails.logger.info msg
        # @notifier.ping msg if send_notifications && msg.present?
        break
      end
      response
    end

    def fetch_disability_verifications(one_off: false)
      return unless @config.disability_verification_cuid.present?

      msg = 'Fetching disability verifications'
      Rails.logger.info msg
      @notifier.ping msg if send_notifications && msg.present?
      settings = {
        url: "#{@config.url}?wsdl=1&cuid=#{@config.disability_verification_cuid}",
        method: :disability_lookup,
      }
      message_options = {
        touch_point_id: @config.disability_touch_point_id,
        touch_point_question_id: @config.disability_touch_point_question_id,
      }
      if one_off
        call_once(settings, message_options)
      else
        call_with_retry(settings, message_options)
      end
    end

    def set_disability_verifications
      return unless @config.disability_verification_cuid.present?

      @disability_verifications = fetch_disability_verifications.
        group_by { |row| row[:participant_enterprise_identifier].delete('-') }
      personal_ids = @disability_verifications.keys
      source_clients = GrdaWarehouse::Hud::Client.source.where(
        data_source_id: @data_source_id,
        PersonalID: personal_ids,
      ).select(:id, :PersonalID, :disability_verified_on, :data_source_id)
      updated_source_counts = 0
      updated_destination_counts = 0
      source_clients.each do |client|
        verifications = @disability_verifications[client.PersonalID]
        max_date = verifications.map { |row| row[:date_last_updated].to_time }.max
        # only set the verification date if it was blank before or is newer
        # then, check the destination client and update that as well
        # We could batch this to improve performance if necessary, but after the first load
        # this should only be a handful of clients each day
        next unless client.disability_verified_on.blank? || max_date > client.disability_verified_on || (@force_disability_verification && max_date >= client.disability_verified_on)

        client.update(disability_verified_on: max_date)
        updated_source_counts += 1
        dest_client = client.destination_client
        # reflect changes on the destination client if the changes to the source client data are newer
        next unless dest_client.disability_verified_on.blank? || client.disability_verified_on > dest_client.disability_verified_on || @force_disability_verification

        dest_client.update(disability_verified_on: client.disability_verified_on)

        verification = verifications.detect { |v| v[:date_last_updated].to_time == max_date }
        if verification
          verification_source = GrdaWarehouse::VerificationSource::Disability.where(client_id: dest_client.id).first_or_create
          verification_source.update(location: verification[:site_name], verified_at: max_date)
        end

        updated_destination_counts += 1
      end
      msg = "Updated #{updated_source_counts} source disability verifications"
      Rails.logger.info msg
      @notifier.ping msg if send_notifications && msg.present?
      msg = "Updated #{updated_destination_counts} destination disability verifications"
      Rails.logger.info msg
      @notifier.ping msg if send_notifications && msg.present?
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

    def site_id_from_name(site_name)
      @site_ids ||= sites.invert
      @site_ids[site_name]
    end
  end
end
