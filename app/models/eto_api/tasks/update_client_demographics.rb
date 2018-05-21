# Fetch client demographics via the ETO API for clients
# who have a record in ApiClientDataSourceId
module EtoApi::Tasks
  class UpdateClientDemographics
    include ActionView::Helpers::DateHelper
    include NotifierConfig
    attr_accessor :send_notifications, :notifier_config, :notifier

    # optionally pass an array of client source ids
    def initialize client_ids:[], batch_time: 45.minutes, run_time: 5.hours, trace: false, one_off: false
      @clients = []
      @client_ids = client_ids || []
      @trace = trace
      @batch_time = batch_time
      @restart = Time.now + @batch_time
      @run_time = run_time
      @stop_time = Time.now + run_time
      @one_off = one_off

      setup_notifier('ETO API Importer')
      
      #@api.trace = false
    end

    private def defined_demographic_value value:, cdid:, site_id:
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
      # 439 = Assigened Staff (pine street) 597 (HomeStart)
      #
      # 635 = Assigned Counselor
      #
      # 639 = Main Outreach Counselor
      
      # Loop over all items in the config
      api_config = YAML.load(ERB.new(File.read("#{Rails.root}/config/eto_api.yml")).result)[Rails.env]
      api_config.to_a.reverse.to_h.each do |key, conf|
        @data_source_id = conf['data_source_id']

        @api = EtoApi::Detail.new(trace: @trace, api_connection: key)
        @api.connect

        cs = load_candidates(type: :demographic)
        current_hmis_clients = GrdaWarehouse::HmisClient.count
        current_hmis_forms = GrdaWarehouse::HmisForm.count
        if @one_off
          msg = "Importing #{cs.size} clients from the api, trigged by visiting the client in the UI."
        else
          msg = "Importing #{cs.size} clients from the api, restarting every #{time_ago_in_words(@batch_time.from_now)}, stopping after #{time_ago_in_words(@run_time.from_now)}.  There are currently #{current_hmis_clients} HMIS Clients and #{current_hmis_forms} HMIS Forms"
        end
        Rails.logger.info msg
        notifier.ping msg if send_notifications
        @clients = load_candidates(type: :demographic)
        @clients.find_in_batches(batch_size: 10) do |clients|
          clients.each do |client|
            found = fetch_demographics(client)
            if found.present?
              fetch_assessments(client)
            end
            if Time.now > @restart
              Rails.logger.info "Restarting after #{time_ago_in_words(@batch_time.from_now)}"
              @api = nil
              sleep(5)
              @api = EtoApi::Detail.new(trace: @trace)
              @api.connect
              @restart = Time.now + @batch_time
            end
            if Time.now > @stop_time
              current_hmis_clients = GrdaWarehouse::HmisClient.count
              current_hmis_forms = GrdaWarehouse::HmisForm.count
              msg = "Stopping #{self.class.name} after #{time_ago_in_words(@run_time.from_now)}.  There are currently #{current_hmis_clients} HMIS Clients and #{current_hmis_forms} HMIS Forms"
              Rails.logger.info msg 
              notifier.ping msg if send_notifications
              return
            end
          end
        end
        # @clients = load_candidates(type: :assessment)
        # @clients.each do |client|
        #   fetch_assessments(client)
        # end
      end
    end

    def fetch_assessments client
      subject_id = client.hmis_client.subject_id
      return unless subject_id.present?
      # hard-coding touch_point_id: 75 because that's the only one we care about at the moment
      
      site_id = client.site_id_in_data_source

      # See /admin/eto_api/assessments for details
      # 75 = HUD Entry/Exit Assessment
      # 211 = Add Triage assessment
      assessment_ids = GrdaWarehouse::HMIS::Assessment.fetch_for_data_source(@data_source_id).pluck(:assessment_id)

      assessment_ids.each do |tp_id|
        responses = @api.list_touch_point_responses(site_id: site_id, subject_id: subject_id, touch_point_id: tp_id)
        if responses
          save_touch_points(
            site_id: site_id, 
            touch_point_id: tp_id, 
            responses: responses, 
            client_id: client.client_id, 
            subject_id: subject_id
          )
        end
      end
    end

    def fetch_demographics client
      hmis_client = nil
      response = @api.client_demographic(client_id: client.id_in_data_source.gsub(',',''), site_id: client.site_id_in_data_source) rescue nil
      if response
        hmis_client = GrdaWarehouse::HmisClient.where(client_id: client.client_id).first_or_initialize
        hmis_client.response = response.to_json

        hmis_client.subject_id = response['SubjectID']
        hmis_client.consent_form_status = defined_value(client: client, response: response, label: 'Consent Form:')
        hmis_client.outreach_counselor_name = defined_value(client: client, response: response, label: 'Main Outreach Conselor')
        
        cm = entity(client: client, response: response, entity_label: 'Case Manager/Advocate')
        hmis_client.case_manager_name = cm.try(:[], 'EntityName')
        hmis_client.case_manager_attributes = cm if hmis_client.case_manager_name.present?

        staff = entity(client: client, response: response, entity_label: 'AssignedStaffID')
        hmis_client.assigned_staff_name = staff.try(:[], 'EntityName')
        hmis_client.assigned_staff_attributes = staff if hmis_client.assigned_staff_name.present?

        counselor = entity(client: client, response: response, entity_label: 'Assigned Counselor')
        hmis_client.counselor_name = staff.try(:[], 'EntityName')
        hmis_client.counselor_attributes = counselor if hmis_client.counselor_name.present?

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
      responses.each do |response|
        response_id = response["TouchPointResponseID"]
        program_id = response["ProgramID"]
        hmis_form = GrdaWarehouse::HmisForm.where(
          client_id: client_id, 
          subject_id: subject_id, 
          response_id: response_id,
          assessment_id: touch_point_id,
          data_source_id: @data_source_id,
          site_id: site_id
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
        answers = {}
        answers[:assessment_title] = assessment_name
        answers[:assessment_identifier] = response['TouchPointIdentifier']
        answers[:sections] = []
        section = nil
        assessment['TouchPointElement'].each do |element|
          element_type = display_as_form_element(element_type: element['ElementType'])
          if element_type == 'Section header'
            answers[:sections] << section if section.present?
            section = {section_title: element['Stimulus'], questions: []}
          else
            value = response_element(element_id: element['ElementID'], response: response).try(:[], 'Value')
            section[:questions] << {
              question: element['Stimulus'],
              answer: value,
              type: element_type,
            }
            # Some special cases
            if element['Stimulus'] == 'A-1. At what point is this data being collected?'
               hmis_form.assessment_type = value
            end                
          end
        end
        # Save off the last section
        answers[:sections] << section if section.present?
        staff = @api.staff(site_id: site_id, id: response['AuditStaffID'])
        hmis_form.staff = "#{staff['FirstName']} #{staff['LastName']}"
        hmis_form.collected_at = @api.parse_date(response['ResponseCreatedDate'])
        hmis_form.name = assessment_name
        hmis_form.collection_location = @api.program(site_id: site_id, id: program_id)
        hmis_form.response = response
        hmis_form.answers = answers
        hmis_form.assessment_type = assessment_name unless hmis_form.assessment_type.present?
        hmis_form.save
      end
    end

    private def display_as_form_element(element_type:)
      # 35: Section header
      # 6: Radio
      # 4: Drop-down
      # 9: Date
      # 5: Text
      # 2: TextArea
      types = {
        35 => 'Section header',
        6 => 'Radio',
        4 => 'Drop-down',
        9 => 'Date',
        5 => 'Textfield',
        2 => 'Textarea',
      }
      types.try(:[], element_type)
    end

    private def response_element(element_id: , response:)
      response['ResponseElements'].select{|m| m['ElementID'] == element_id}.first
    end

    private def entity client:, response:, entity_label:
      item_cdid = @api.attribute_id(attribute_name: entity_label, site_id: client.site_id_in_data_source)
      item_entity_id = response['CustomDemoData'].detect{|m| m['CDID'].to_i == item_cdid}.try(:[], 'value')
      @api.entity_by_id(entity_id: item_entity_id.to_i, site_id: client.site_id_in_data_source)
    end

    private def defined_value client:, response:, label: 
      item_cdid = @api.attribute_id(attribute_name: label, site_id: client.site_id_in_data_source)
      item_value = response['CustomDemoData'].detect do 
        |m| m['CDID'].to_i == item_cdid
      end.try(:[], 'value')
      return nil unless item_value.present?
      defined_demographic_value(value: item_value.to_i, cdid: item_cdid, site_id: client.site_id_in_data_source)
    end

    private def load_candidates type:
      return [] unless type.present?
      scope = GrdaWarehouse::ApiClientDataSourceId.joins(:client)
      if @client_ids.any?
        # Force a specific candidate set
        scope.where(client_id: @client_ids, data_source_id: @data_source_id)
      else
        # Load anyone who's not been updated recently
        case type
        when :demographic
          # scope.where.not(client_id: GrdaWarehouse::HmisClient.select(:client_id)).
          #   where(data_source_id: @data_source_id).
          #   order(last_contact: :desc)
          scope.where.not(client_id: GrdaWarehouse::HmisClient.select(:client_id).
            where(['updated_at < ?', 3.days.ago.to_date])
          ).
          where(data_source_id: @data_source_id)
        when :assessment
          scope.joins(:hmis_client)
            # .where(['updated_at < ?', 1.week.ago.to_date])
        end
      end
    end

  end
end
