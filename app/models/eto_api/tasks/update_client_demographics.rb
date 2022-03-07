###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Fetch client demographics via the ETO API for clients
# who have a record in ApiClientDataSourceId

# NB: To bring in additional data, you may need to setup some ETO configs.  Here's an example

# config = GrdaWarehouse::EtoApiConfig.create(
#   data_source_id: 3,
#   demographic_fields: {
#     consent_form_status: 'Consent Form:',
#     outreach_counselor_name: 'Main Outreach Counselor',
#   },
#   demographic_fields_with_attributes: {
#     case_manager_name: {entity_label: 'Case Manager/Advocate', attributes: :case_manager_attributes},
#     assigned_staff_name: {entity_label: 'AssignedStaffID', attributes: :assigned_staff_attributes},
#     counselor_name: {entity_label: 'Assigned Counselor', attributes: :counselor_attributes},
#   },
#   additional_fields: {
#     hud_last_permanent_zip: 422,
#     hud_last_permanent_zip_quality: 423,
#   },
#   touchpoint_fields: {
#     assessment_type: 'A-1. At what point is this data being collected?',
#     housing_status: 'A-6. Where did you sleep last night?',
#   },
# )

module EtoApi::Tasks
  class UpdateClientDemographics
    include ActionView::Helpers::DateHelper
    include NotifierConfig
    attr_accessor :send_notifications, :notifier_config, :notifier

    # optionally pass an array of client source ids
    def initialize(client_ids: [], batch_time: 45.minutes, run_time: 5.hours, trace: false, one_off: false)
      @client_ids = client_ids || []
      @trace = trace
      @batch_time = batch_time
      @restart = Time.now + @batch_time
      @run_time = run_time
      @stop_time = Time.now + run_time
      @one_off = one_off
      @start_time = Time.now

      setup_notifier('ETO API Importer')

      # @api.trace = false
    end

    private def defined_demographic_value(value:, cdid:, site_id:)
      options = @api.demographic_defined_values(cdid: cdid, site_id: site_id).map do |m|
        [m['ID'], m['Text']]
      end.to_h
      options[value]
    end

    def run!
      return unless GrdaWarehouse::Config.get(:eto_api_available)

      # Some useful-ish CDIDs
      # 1062 = consent form status

      # 331 = Case Manager/Advocate - EntityId
      # 439 = Assigned Staff (pine street) 597 (HomeStart)
      #
      # 635 = Assigned Counselor
      #
      # 639 = Main Outreach Counselor

      # 422 Zip Code of Last Permanent Address (HUD) - BPHC only
      # 423 Zip Code Type (HUD) - BPHC only

      # Loop over all items in the config
      api_config = EtoApi::Base.api_configs
      api_config.to_a.reverse.to_h.each do |key, conf|
        @data_source_id = conf['data_source_id']
        @custom_config = GrdaWarehouse::EtoApiConfig.active.find_by(data_source_id: @data_source_id)

        @api = EtoApi::Detail.new(trace: @trace, api_connection: key)
        @api.connect

        # This number may be larger than the original client_id list since each client may be
        # in more than one site
        cs = candidate_scope(type: :demographic)

        current_hmis_clients = GrdaWarehouse::HmisClient.count
        current_hmis_forms = GrdaWarehouse::HmisForm.count
        if @one_off
          msg = ''
          # msg = "Importing #{cs.size} clients from the api, trigged by visiting the client in the UI."
        else
          msg = "Importing #{cs.size} clients from the api, restarting every #{time_ago_in_words(@batch_time.from_now)}, stopping after #{time_ago_in_words(@run_time.from_now)}.  There are currently #{current_hmis_clients} HMIS Clients and #{current_hmis_forms} HMIS Forms"
        end
        Rails.logger.info msg if msg.present?
        notifier.ping msg if send_notifications && msg.present?
        candidate_ids = candidate_scope(type: :demographic).pluck(:id)
        candidate_ids.each_slice(10) do |ids|
          clients = candidate_scope(type: :demographic).
            where(id: ids)
          clients.each do |client|
            next unless client.present?

            begin
              found = fetch_demographics(client)
              fetch_assessments(client) if found.present?
              client.update(temporary_high_priority: false) if client.temporary_high_priority
              if Time.now > @restart
                Rails.logger.info "Restarting after #{time_ago_in_words(@batch_time.from_now)}"
                @api = nil
                sleep(5)
                @api = EtoApi::Detail.new(trace: @trace, api_connection: key)
                @api.connect
                @restart = Time.now + @batch_time
              end
              if Time.now > @stop_time
                current_hmis_clients = GrdaWarehouse::HmisClient.count
                current_hmis_forms = GrdaWarehouse::HmisForm.count
                msg = "Stopping #{self.class.name} after #{time_ago_in_words(@start_time)}.  There are currently #{current_hmis_clients} HMIS Clients and #{current_hmis_forms} HMIS Forms; current source client: #{client.client_id}; processing source clients: #{clients.map(&:client_id)}"
                Rails.logger.info msg
                notifier.ping msg if send_notifications
                return # rubocop:disable Lint/NonLocalExitFromIterator
              end
              found.maintain_client_consent if @one_off && found.present?
            rescue Exception => e
              notifier.ping "ERROR #{e.message} for api client #{client.id}, source_client: #{client.client_id} in data source #{@data_source_id}"
            end
          end
        end
      end
      true
    end

    def fetch_assessments(client)
      subject_id = client.hmis_client.subject_id
      return unless subject_id.present?

      site_id = client.site_id_in_data_source

      # See /admin/eto_api/assessments for details
      # HUD assessments don't show up in the API list, ids are hard coded in ENV['ETO_API_HUD_TOUCH_POINT_ID1']
      assessment_ids = GrdaWarehouse::HMIS::Assessment.fetch_for_data_source(@data_source_id).distinct.pluck(:assessment_id)

      assessment_ids.each do |tp_id|
        responses = @api.list_touch_point_responses(site_id: site_id, subject_id: subject_id, touch_point_id: tp_id)
        next unless responses

        save_touch_points(
          site_id: site_id,
          touch_point_id: tp_id,
          responses: responses,
          client_id: client.client_id,
          subject_id: subject_id,
        )
      end
    end

    def fetch_demographics(client)
      hmis_client = nil
      api_response = begin
                       @api.client_demographic(client_id: client.id_in_data_source.gsub(',', ''), site_id: client.site_id_in_data_source)
                     rescue StandardError
                       nil
                     end
      if api_response
        hmis_client = GrdaWarehouse::HmisClient.where(client_id: client.client_id).first_or_initialize
        hmis_client.response = api_response.to_json

        hmis_client.subject_id = api_response['SubjectID']

        # overridden with custom attributes
        hud_last_permanent_zip = nil
        hud_last_permanent_zip_quality = nil

        if @custom_config.present?
          @custom_config.demographic_fields.each do |key, label|
            hmis_client[key] = defined_value(client: client, response: api_response, label: label)
          end

          # cm = entity(client: client, response: api_response, entity_label: 'Case Manager/Advocate')
          # hmis_client.case_manager_name = cm.try(:[], 'EntityName')
          # hmis_client.case_manager_attributes = cm if hmis_client.case_manager_name.present?

          # staff = entity(client: client, response: api_response, entity_label: 'AssignedStaffID')
          # hmis_client.assigned_staff_name = staff.try(:[], 'EntityName')
          # hmis_client.assigned_staff_attributes = staff if hmis_client.assigned_staff_name.present?

          # counselor = entity(client: client, response: api_response, entity_label: 'Assigned Counselor')
          # hmis_client.counselor_name = staff.try(:[], 'EntityName')
          # hmis_client.counselor_attributes = counselor if hmis_client.counselor_name.present?

          @custom_config.demographic_fields_with_attributes.each do |key, details|
            data = entity(client: client, response: api_response, entity_label: details['entity_label'])
            if data.present?
              hmis_client[key] = data.try(:[], 'EntityName')
              hmis_client[details['attributes']] = data if hmis_client[key].present?
            end
          end

          # This is only valid for Boston...
          # if @data_source_id == 3
          #   hud_last_permanent_zip = api_response["CustomDemoData"].select{|m| m['CDID'] == 422}&.first&.try(:[], 'value')
          #   hud_last_permanent_zip_quality = api_response["CustomDemoData"].select{|m| m['CDID'] == 423}&.first&.try(:[], 'value')

          # Special cases for fields that don't exist on hmis_client
          @custom_config.additional_fields.each do |key, cdid|
            case key
            when 'hud_last_permanent_zip'
              hud_last_permanent_zip = api_response['CustomDemoData'].select { |m| m['CDID'] == cdid }&.first&.try(:[], 'value')
            when 'hud_last_permanent_zip_quality'
              hud_last_permanent_zip_quality = api_response['CustomDemoData'].select { |m| m['CDID'] == cdid }&.first&.try(:[], 'value')
            when 'sexual_orientation'
              value = api_response['CustomDemoData'].select { |m| m['CDID'] == cdid }&.first&.try(:[], 'value')
              defined_demographic_value(value: value, cdid: cdid, site_id: client.site_id_in_data_source)
            when 'phone'
              hmis_client.phone = api_response['CustomDemoData'].select { |m| m['CDID'] == cdid }&.first&.try(:[], 'value')
            when 'email'
              hmis_client.email = api_response['CustomDemoData'].select { |m| m['CDID'] == cdid }&.first&.try(:[], 'value')
            else
              hmis_client[key] = api_response['CustomDemoData'].select { |m| m['CDID'] == cdid }&.first&.try(:[], 'value')
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
          phone: hmis_client&.phone,
          email: hmis_client&.email,
          language_1: hmis_client&.language_1,
          language_2: hmis_client&.language_2,
          youth_current_zip: hmis_client&.youth_current_zip,
        }
        hmis_client.eto_last_updated = @api.parse_date(api_response['AuditDate'])
        if hmis_client.changed?
          hmis_client.save
        else
          hmis_client.touch # make a note that we tried
        end
      end
      hmis_client
    end

    private def save_touch_points(site_id:, touch_point_id:, responses:, client_id:, subject_id:)
      # Fetch assessment structure
      assessment = @api.touch_point(site_id: site_id, id: touch_point_id)
      assessment_name = assessment['TouchPointName']
      responses.each do |api_response|
        response_id = api_response['TouchPointResponseID']
        program_id = api_response['ProgramID']
        hmis_form = GrdaWarehouse::HmisForm.where(
          client_id: client_id,
          subject_id: subject_id,
          response_id: response_id,
          assessment_id: touch_point_id,
          data_source_id: @data_source_id,
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

        staff = @api.staff(site_id: site_id, id: api_response['AuditStaffID']) # Returns nil if it can't be found
        if staff.present?
          hmis_form.staff = "#{staff['FirstName']} #{staff['LastName']}"
        else
          hmis_form.staff = "ETO Staff ID: #{api_response['AuditStaffID']}"
        end
        hmis_form.staff_email = staff['Email']
        # Add email
        hmis_form.collected_at = @api.parse_date(api_response['ResponseCreatedDate'])
        hmis_form.name = assessment_name
        hmis_form.collection_location = @api.program(site_id: site_id, id: program_id)
        hmis_form.api_response = api_response
        hmis_form.answers = answers
        hmis_form.assessment_type = assessment_name unless hmis_form.assessment_type.present?
        hmis_form.eto_last_updated = @api.parse_date(api_response['AuditDate'])
        begin
          hmis_form.save
          hmis_form.create_qualifying_activity!
        rescue Exception
          # msg = "Failed to save, probably dirty: #{e.message}"
          # notifier.ping msg if send_notifications
        end
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

    private def entity(client:, response:, entity_label:)
      item_cdid = @api.attribute_id(attribute_name: entity_label, site_id: client.site_id_in_data_source)
      item_entity_id = response['CustomDemoData'].detect { |m| m['CDID'].to_i == item_cdid }.try(:[], 'value')
      @api.entity_by_id(entity_id: item_entity_id.to_i, site_id: client.site_id_in_data_source)
    end

    private def defined_value(client:, response:, label:)
      item_cdid = @api.attribute_id(attribute_name: label, site_id: client.site_id_in_data_source)
      item_value = response['CustomDemoData'].detect do |m|
        m['CDID'].to_i == item_cdid
      end.try(:[], 'value')
      return nil unless item_value.present?

      defined_demographic_value(value: item_value.to_i, cdid: item_cdid, site_id: client.site_id_in_data_source)
    end

    # Use client_ids passed in,
    # OR
    # If we have anyone flagged as high-priority, process those
    # OR
    # any client who we've created a record in ApiClientDataSourceId for who hasn't been
    # updated in the past 3 days
    private def candidate_scope(type:)
      return GrdaWarehouse::ApiClientDataSourceId.joins(:client).none unless type.present?

      scope = GrdaWarehouse::ApiClientDataSourceId.joins(:client).
        includes(:hmis_client).
        references(:hmis_client)
      if @client_ids.any?
        # Force a specific candidate set
        scope.where(client_id: @client_ids, data_source_id: @data_source_id)
      else
        # Load anyone who's not been updated recently
        case type
        when :demographic
          # any high-priority?
          if GrdaWarehouse::ApiClientDataSourceId.high_priority.exists?
            scope.high_priority
          else
            hc_t = GrdaWarehouse::HmisClient.arel_table
            scope.where.not(client_id: GrdaWarehouse::HmisClient.select(:client_id).
              where(hc_t[:updated_at].lt(3.days.ago.to_date))).
              where(data_source_id: @data_source_id).
              order(Arel.sql("#{hc_t[:updated_at].asc.to_sql} NULLS FIRST"))
          end
        when :assessment
          scope.joins(:hmis_client)
          # .where(['updated_at < ?', 1.week.ago.to_date])
        end
      end
    end
  end
end
