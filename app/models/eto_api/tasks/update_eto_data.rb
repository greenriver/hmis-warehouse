###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Tool to update data via the ETO API based on results from QaaWS via Bo::ClientIdLookup
# require 'newrelic_rpm'
module EtoApi::Tasks
  class UpdateEtoData
    include ActionView::Helpers::DateHelper
    include NotifierConfig
    attr_accessor :send_notifications, :notifier_config, :notifier

    def initialize(
      batch_time: 45.minutes,
      run_time: 5.hours,
      trace: false,
      one_off: false,
      client_ids: nil
    )
      @trace = trace
      @batch_time = batch_time
      @restart = Time.now + @batch_time
      @run_time = run_time
      @stop_time = Time.now + run_time
      @one_off = one_off
      @client_ids = client_ids

      setup_notifier('ETO API Importer -- QaaWS based')
    end

    def run!
      return unless GrdaWarehouse::Config.get(:eto_api_available)

      update_demographics!
      update_touch_points!
    end

    def update_demographics!
      # compare existing hmis_clients and updated_at to eto_client_lookups last_updated.
      # If the hmis_client is older, fetch
      # if the hmis_client doesn't exist, fetch
      api_config = EtoApi::Base.api_configs
      api_config.to_a.reverse.to_h.each do |key, conf|
        @data_source_id = conf['data_source_id']

        api = EtoApi::Detail.new(trace: @trace, api_connection: key)
        api.connect
        existing_hmis_clients = GrdaWarehouse::HmisClient.joins(:client).
          merge(GrdaWarehouse::Hud::Client.where(data_source_id: @data_source_id))
        existing_hmis_clients = existing_hmis_clients.where(client_id: @client_ids) if @client_ids.present?
        existing_hmis_clients = existing_hmis_clients.pluck(
          :client_id,
          :subject_id,
          :eto_last_updated,
        ).
          map do |client_id, subject_id, eto_last_updated|
          [[client_id, subject_id], eto_last_updated]
        end.to_h

        eto_client_lookups = GrdaWarehouse::EtoQaaws::ClientLookup.where(data_source_id: @data_source_id)
        eto_client_lookups = eto_client_lookups.where(client_id: @client_ids) if @client_ids.present?
        eto_client_lookups = eto_client_lookups.pluck(*eto_client_lookup_columns).
          map do |row|
          Hash[eto_client_lookup_columns.zip(row)]
        end

        to_fetch = []

        eto_client_lookups.each do |row|
          existing_updated = existing_hmis_clients[[row[:client_id], row[:subject_id]]]
          # timezones seem to get very confused, just check the date.
          next unless existing_updated.blank? || existing_updated.to_date < row[:last_updated].to_date

          to_fetch << {
            client_id: row[:client_id],
            participant_site_identifier: row[:participant_site_identifier],
            site_id: row[:site_id],
            subject_id: row[:subject_id],
            data_source_id: row[:data_source_id],
          }
        end

        new_count = (to_fetch.map { |m| [m[:client_id], m[:subject_id]] }.uniq - existing_hmis_clients.keys.uniq).count
        update_count = to_fetch.count - new_count
        msg = "Fetching #{to_fetch.count} #{'client'.pluralize(to_fetch.count)}, #{new_count} new, #{update_count} updates for data_source #{@data_source_id} via the ETO API"
        # Give some space to the Slack API
        sleep(2)
        # NOTE: only send a slack message if we are pulling more than 10
        @notifier.ping msg if to_fetch.count > 10
        # Rails.logger.info "Pre fetching demo: #{NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample} -- MEM DEBUG"
        to_fetch.each do |row|
          # Rails.logger.info "Fetching demo: #{NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample} -- MEM DEBUG"
          GC.start
          save_demographics(
            api: api,
            client_id: row[:client_id],
            participant_site_identifier: row[:participant_site_identifier],
            site_id: row[:site_id],
            subject_id: row[:subject_id],
            data_source_id: row[:data_source_id],
          )
          # Rails.logger.info "Fetched demo: #{NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample} -- MEM DEBUG"
        end
        # Rails.logger.info "All demo fetched demo: #{NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample} -- MEM DEBUG"
        msg = "Fetched #{to_fetch.count} #{'client'.pluralize(to_fetch.count)} via the ETO API"
        Rails.logger.info msg
        # Give some space to the Slack API
        sleep(2)
        # NOTE: only send a slack message if we are pulling more than 10
        @notifier.ping msg if to_fetch.count > 10
      end
      # prevent returning the config
      true
    end

    private def eto_client_lookup_columns
      @eto_client_lookup_columns ||= [
        :client_id,
        :subject_id,
        :last_updated,
        :site_id,
        :participant_site_identifier,
        :data_source_id,
      ]
    end

    def update_touch_points!
      api_config = EtoApi::Base.api_configs
      api_config.to_a.reverse.to_h.each do |key, conf|
        @data_source_id = conf['data_source_id']

        api = EtoApi::Detail.new(trace: @trace, api_connection: key)
        api.connect
        existing_touch_points = GrdaWarehouse::HmisForm.where(data_source_id: @data_source_id)
        existing_touch_points = existing_touch_points.where(client_id: @client_ids) if @client_ids.present?
        existing_touch_points = existing_touch_points.pluck(
          :client_id,
          :site_id,
          :assessment_id,
          :subject_id,
          :response_id,
          :eto_last_updated,
        ).map do |client_id, site_id, assessment_id, subject_id, response_id, eto_last_updated|
          [[client_id, site_id, assessment_id, subject_id, response_id], eto_last_updated]
        end.to_h

        eto_touch_point_lookups = GrdaWarehouse::EtoQaaws::TouchPointLookup.
          joins(:hmis_assessment).
          merge(GrdaWarehouse::HMIS::Assessment.fetch_for_data_source(@data_source_id)).
          where(data_source_id: @data_source_id)
        eto_touch_point_lookups = eto_touch_point_lookups.where(client_id: @client_ids) if @client_ids.present?
        eto_touch_point_lookups = eto_touch_point_lookups.pluck(*eto_touch_point_lookup_columns).
          map do |row|
          Hash[eto_touch_point_lookup_columns.zip(row)]
        end

        to_fetch = []
        # Rails.logger.info "Pre-load: #{NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample} -- MEM DEBUG"
        eto_touch_point_lookups.each do |row|
          key = [row[:client_id], row[:site_id], row[:assessment_id], row[:subject_id], row[:response_id]]
          existing_updated = existing_touch_points[key]
          # timezones seem to get very confused, just check the date.
          next unless existing_updated.blank? || existing_updated.to_date < row[:last_updated].to_date

          # @notifier.ping "#{row[:client_id]} existing_updated: #{existing_updated.to_date}; last_updated: #{row[:last_updated].to_date}"

          to_fetch << {
            client_id: row[:client_id],
            site_id: row[:site_id],
            assessment_id: row[:assessment_id],
            subject_id: row[:subject_id],
            response_id: row[:response_id],
            data_source_id: row[:data_source_id],
            last_updated: row[:last_updated],
          }
        end
        # Rails.logger.info "Post-load: #{NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample} -- MEM DEBUG"
        new_count = (to_fetch.map(&:values).uniq - existing_touch_points.keys.uniq).count
        update_count = to_fetch.count - new_count
        msg = "Fetching #{to_fetch.count} touch #{'point'.pluralize(to_fetch.count)}, #{new_count} new, #{update_count} updates for data_source #{@data_source_id} via the ETO API"
        Rails.logger.info msg
        # Give some space to the Slack API
        sleep(2)
        # NOTE: only send a slack message if we are pulling more than 10
        @notifier.ping msg if to_fetch.count > 10

        touch_points_saved = 0
        to_fetch.each do |row|
          GC.start
          saved = save_touch_point(
            api: api,
            site_id: row[:site_id],
            touch_point_id: row[:assessment_id],
            client_id: row[:client_id],
            subject_id: row[:subject_id],
            response_id: row[:response_id],
            data_source_id: row[:data_source_id],
            last_updated: row[:last_updated],
          )
          touch_points_saved += 1 if saved
        end
        msg = "Fetched #{touch_points_saved} of #{to_fetch.count} touch #{'point'.pluralize(to_fetch.count)} via the ETO API"
        Rails.logger.info msg
        # Give some space to the Slack API
        sleep(2)
        # NOTE: only send a slack message if we are pulling more than 10
        @notifier.ping msg if touch_points_saved > 10
      end
      # prevent returning the config
      true
    end

    private def eto_touch_point_lookup_columns
      @eto_touch_point_lookup_columns ||= [
        :client_id,
        :site_id,
        :assessment_id,
        :subject_id,
        :response_id,
        :last_updated,
        :data_source_id,
      ]
    end

    def save_demographics(api:, client_id:, participant_site_identifier:, site_id:, subject_id:, data_source_id:)
      hmis_client = fetch_demographics(
        api: api,
        client_id: client_id,
        participant_site_identifier: participant_site_identifier,
        site_id: site_id,
        subject_id: subject_id,
        data_source_id: data_source_id,
      )
      hmis_client&.save
    end

    def fetch_demographics(api:, client_id:, participant_site_identifier:, site_id:, subject_id:, data_source_id:)
      @custom_config = GrdaWarehouse::EtoApiConfig.active.find_by(data_source_id: data_source_id)

      hmis_client = nil
      # puts "requesting client #{client_id} (#{participant_site_identifier}), from #{site_id}"
      api_response = begin
        api.client_demographic(client_id: participant_site_identifier, site_id: site_id)
      rescue StandardError
        nil
      end
      # puts api_response.present?
      if api_response
        hmis_client = GrdaWarehouse::HmisClient.where(client_id: client_id, subject_id: subject_id).first_or_initialize
        hmis_client.response = api_response.to_json

        hmis_client.subject_id = api_response['SubjectID']

        # overridden with custom attributes
        hud_last_permanent_zip = nil
        hud_last_permanent_zip_quality = nil

        if @custom_config.present?
          @custom_config.demographic_fields.each do |key, label|
            hmis_client.assign_attributes(key => defined_value(api: api, site_id: site_id, response: api_response, label: label))
          end

          @custom_config.demographic_fields_with_attributes.each do |key, details|
            data = entity(api: api, site_id: site_id, response: api_response, entity_label: details['entity_label'])
            next unless data.present?

            value = data.dig('EntityName')
            hmis_client.assign_attributes(key => value)
            hmis_client.assign_attributes(details['attributes'] => data) if value.present?
          end

          # Special cases for fields that don't exist on hmis_client
          @custom_config.additional_fields.each do |key, cdid|
            case key
            when 'hud_last_permanent_zip'
              hud_last_permanent_zip = api_response['CustomDemoData'].select { |m| m['CDID'] == cdid }&.first&.try(:[], 'value')
            when 'hud_last_permanent_zip_quality'
              hud_last_permanent_zip_quality = api_response['CustomDemoData'].select { |m| m['CDID'] == cdid }&.first&.try(:[], 'value')
            when 'sexual_orientation'
              value = api_response['CustomDemoData'].select { |m| m['CDID'] == cdid }&.first&.try(:[], 'value')
              defined_demographic_value(api: api, value: value, cdid: cdid, site_id: site_id)
            else
              value = api_response['CustomDemoData'].select { |m| m['CDID'] == cdid }&.first&.try(:[], 'value')
              hmis_client.assign_attributes(key => value)
            end
          end
        end

        hmis_client.processed_fields = {
          consent_form_status: hmis_client&.consent_form_status,
          outreach_counselor_name: hmis_client&.outreach_counselor_name,
          case_manager_name: hmis_client&.case_manager_name,
          case_manager_attributes: hmis_client&.case_manager_attributes,
          assigned_staff_name: hmis_client&.assigned_staff_name,
          assigned_staff_attributes: hmis_client&.assigned_staff_attributes,
          counselor_name: hmis_client&.counselor_name,
          counselor_attributes: hmis_client&.counselor_attributes,
          hud_last_permanent_zip: hud_last_permanent_zip,
          hud_last_permanent_zip_quality: hud_last_permanent_zip_quality,
          consent_confirmed_on: hmis_client&.consent_confirmed_on,
          consent_expires_on: hmis_client&.consent_expires_on,
          sexual_orientation: hmis_client&.sexual_orientation,
        }
        hmis_client.eto_last_updated = api.parse_date(api_response['AuditDate'])
      end
      hmis_client
    end

    private def defined_demographic_value(api:, value:, cdid:, site_id:)
      options = api.demographic_defined_values(cdid: cdid, site_id: site_id).map do |m|
        [m['ID'], m['Text']]
      end.to_h
      options[value]
    end

    def fetch_touch_point(api:, site_id:, touch_point_id:, client_id:, subject_id:, response_id:, data_source_id:, last_updated: nil)
      @custom_config = GrdaWarehouse::EtoApiConfig.active.find_by(data_source_id: data_source_id)

      api_response = api.touch_point_response(
        site_id: site_id,
        response_id: response_id,
        touch_point_id: touch_point_id,
      )
      return nil unless api_response.present?

      # Fetch assessment structure
      assessment = api.touch_point(site_id: site_id, id: touch_point_id)
      assessment_name = assessment['TouchPointName']

      # Rails.logger.info "Loading TP: #{assessment_name}: #{NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample} -- MEM DEBUG"

      response_id = api_response['TouchPointResponseID']
      program_id = api_response['ProgramID']
      hmis_form = GrdaWarehouse::HmisForm.where(
        client_id: client_id,
        subject_id: subject_id,
        response_id: response_id,
        assessment_id: touch_point_id,
        data_source_id: data_source_id,
        site_id: site_id,
      ).first_or_initialize
      #   { assessment_title: 'Title',
      #     assessment_identifier: 'Project Name',
      #     sections: [{
      #       section_title: 'Title',
      #       questions: [{question: 'Question Title', answer: 'Value submitted', type: 'Radio'}]
      #     }]
      #   }
      # We have yet to determine how to discover where ElementTypes are defined,
      # but through investigation
      # we know:
      # ElementType:
      # 35: Section header
      # 6: Radio
      # 4: Drop-down
      # 9: Date
      # 5: Text
      # 2: TextArea
      # 24: Phone
      # 27: Table? Repeating field? Group?
      # 1: table header? group?
      answers = {}
      answers[:assessment_title] = assessment_name
      answers[:assessment_identifier] = api_response['TouchPointIdentifier']
      answers[:sections] = []
      section = nil
      sub_section = nil
      sub_sections = []

      assessment['TouchPointElement'].each do |element|
        element_type = display_as_form_element(element_type: element['ElementType'])
        if element_type == 'Section header'
          answers[:sections] << section if section.present? # save off the previous section
          section = { section_title: element['Stimulus'], questions: [] }
        elsif element['GridOrTable'].present?
          element['GridOrTable']['Elements'].each do |sub_element|
            sub_element_type = display_as_form_element(element_type: sub_element['ElementType'])
            if sub_element_type == 'Section header'
              sub_sections << sub_section if sub_section.present? # save off the previous sub-section
              sub_section = { section_title: sub_element['Stimulus'], questions: [] }
            else
              value = response_element(element_id: sub_element['ElementID'], response: api_response).try(:[], 'Value')
              sub_section[:questions] << {
                question: sub_element['Stimulus'],
                answer: value,
                type: sub_element_type,
              }
            end
          end
        elsif element_type == 'Address'
          value = address_from_response(element_id: element['ElementID'], response: api_response)
          section[:questions] << {
            question: element['Stimulus'],
            answer: value,
            type: element_type,
          }
        else
          value = response_element(element_id: element['ElementID'], response: api_response).try(:[], 'Value')
          section[:questions] << {
            question: element['Stimulus'],
            answer: value,
            type: element_type,
          }
          if @custom_config.present?
            # Some special cases
            # if element['Stimulus'] == 'A-1. At what point is this data being collected?'
            #    hmis_form.assessment_type = value
            # end
            @custom_config.touchpoint_fields.each do |key, stimulus|
              hmis_form[key] = value if element['Stimulus'] == stimulus
            end
          end
        end
      end
      # Save off the last sub_section
      sub_sections << sub_section if sub_section.present?
      # Save off the last section
      answers[:sections] << section if section.present?
      sub_sections.each do |s_section|
        answers[:sections] << s_section
      end

      staff = api.staff(site_id: site_id, id: api_response['AuditStaffID'])
      if staff
        hmis_form.staff = "#{staff['FirstName']} #{staff['LastName']}"
        hmis_form.staff_email = staff['Email']
      end
      # Add email
      hmis_form.collected_at = api.parse_date(api_response['ResponseCreatedDate'])
      hmis_form.name = assessment_name
      hmis_form.collection_location = api.program(site_id: site_id, id: program_id)
      hmis_form.api_response = api_response
      hmis_form.answers = answers
      hmis_form.assessment_type = assessment_name unless hmis_form.assessment_type.present?

      # Persist updated date from ETO, sometimes the API returns an AuditDate that is
      # earlier than the QaaWS last updated, use the most recent, so we don't fetch
      # this over and over.
      api_updated_at = api.parse_date(api_response['AuditDate'])
      hmis_form.eto_last_updated = [last_updated, api_updated_at].compact.max
      hmis_form
    end

    def save_touch_point(api:, site_id:, touch_point_id:, client_id:, subject_id:, response_id:, data_source_id:, last_updated: nil)
      hmis_form = fetch_touch_point(
        api: api,
        site_id: site_id,
        touch_point_id: touch_point_id,
        client_id: client_id,
        subject_id: subject_id,
        response_id: response_id,
        data_source_id: data_source_id,
        last_updated: last_updated,
      )
      return unless hmis_form

      begin
        hmis_form.save
        hmis_form.create_qualifying_activity!
        true
      rescue Exception
        # msg = "Failed to save, probably dirty: #{e.message}"
        # notifier.ping msg if send_notifications
        false
      end
    end

    private def display_as_form_element(element_type:)
      # 35: Section header
      # 6: Radio
      # 4: Drop-down
      # 9: Date
      # 5: Text
      # 2: TextArea
      # 24: Phone
      types = {
        35 => 'Section header',
        6 => 'Radio',
        4 => 'Drop-down',
        9 => 'Date',
        5 => 'Textfield',
        2 => 'Textarea',
        15 => 'Address',
        24 => 'Textfield',
        1 => 'Section header', # this appears to be a TH element, but it's unclear
      }
      types.try(:[], element_type)
    end

    private def response_element(element_id:, response:)
      response['ResponseElements'].select { |m| m['ElementID'] == element_id }.first
    end

    private def address_from_response(element_id:, response:)
      address_hash = response_element(element_id: element_id, response: response)['ResponseAddressField']
      address = []
      [
        'Name',
        'Company',
        'AddressLine1',
        'AddressLine2',
        'City',
        'State',
        'PostalCode',
        'Country',
      ].each do |k|
        address << "#{k}: #{address_hash[k]}" if address_hash[k].present?
      end
      address.join(";\n")
    end

    private def entity(api:, site_id:, response:, entity_label:)
      item_cdid = api.attribute_id(attribute_name: entity_label, site_id: site_id)
      item_entity_id = response['CustomDemoData'].detect { |m| m['CDID'].to_i == item_cdid }.try(:[], 'value')
      api.entity_by_id(entity_id: item_entity_id.to_i, site_id: site_id)
    end

    private def defined_value(api:, site_id:, response:, label:)
      item_cdid = api.attribute_id(attribute_name: label, site_id: site_id)
      item_value = response['CustomDemoData'].detect do |m|
        m['CDID'].to_i == item_cdid
      end.try(:[], 'value')
      return nil unless item_value.present?

      defined_demographic_value(api: api, value: item_value.to_i, cdid: item_cdid, site_id: site_id)
    end
  end
end
