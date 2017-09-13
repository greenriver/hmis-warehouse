# see https://services.etosoftware.com
require 'json'
require 'restclient'
require 'memoist'

module EtoApi
  class Base
    extend Memoist
    attr_accessor :trace

    def initialize(trace: true, api_connection: 'dnd_eto')
      @trace = trace
      @endpoints = {
        security: 'https://services.etosoftware.com/API/Security.svc',
        forms: 'https://services.etosoftware.com/API/Form.svc',
        search: 'https://services.etosoftware.com/API/Search.svc',
        actor: 'https://services.etosoftware.com/API/Actor.svc',
        touch_pount: 'https://services.etosoftware.com/API/TouchPoint.svc',
        staff: 'https://services.etosoftware.com/API/Staff.svc',
        activity: 'https://services.etosoftware.com/API/Activity.svc',
      }
      api_config = YAML.load(ERB.new(File.read("#{Rails.root}/config/eto_api.yml")).result)[Rails.env]
      @credentials = {
        security: {
          'Email': api_config[api_connection]['email'],
          'Password': api_config[api_connection]['password']
        }
      }
      @enterprise = api_config[api_connection]['enterprise']
    end

    def endpoint(service)
      @endpoints[service]
    end

    def connect
      sso = _api_post_json(
        "#{@endpoints[:security]}/SSOAuthenticate/", @credentials, :content_type => :json, :accept => :json
      )
      sso_result = sso['SSOAuthenticateResult'] or raise 'cant sso'
      @auth_token = sso_result['SSOAuthToken']
      @tz_offset = sso_result['TimeZoneOffset'].to_i.to_s # null => 0
      enterprises = api_get_json "#{@endpoints[:security]}/GetSSOEnterprises/#{@auth_token}"
      @site_creds = nil
      @enterprise_guid = enterprises.detect{|e| e['Value'] == @enterprise}.try{ |e| e['Key'] } or raise "Cant find enterprise: #{@enterprise}"
    end

    def connected?
      @auth_token.present?
    end

    private def debug_log(msg)
      puts msg if self.trace
    end

    private def api_get_json(url, headers={})
      body = api_get_body(url, headers)
      return nil if body.blank?
      JSON.parse(body)
    end

    private def api_get_body(url, headers={})
      connect unless connected?
      debug_log "=> GET #{url}"
      body = RestClient.get(url, headers).body
      debug_log "<= #{body}"
      body
    end

    private def api_post_json(url, body, headers={})
      connect unless connected?
      _api_post_json url, body, headers
    end

    private def _api_post_json(url, body, headers={})
      body_text = body.to_json
      debug_log "=> POST #{url}"
      debug_log "   #{body_text}"
      r = RestClient.post(url, body_text, headers.merge('Content-type' => 'application/json'))
      debug_log "<= #{r.body}"
      JSON.parse(r.body)
    end

    private def api_post_urlencode(url, body, headers={})
      body_text = body.to_param
      debug_log "=> POST #{url}"
      debug_log "   #{body_text}"
      r = RestClient.post(url, body_text, headers.merge('Content-type' => 'application/x-www-form-urlencoded'))
      debug_log "<= #{r.body}"
      JSON.parse(r.body)
    end

    def sites(refresh:false)
      @sites = nil if refresh
      @sites ||= begin
        data = api_get_json "#{@endpoints[:security]}/GetSSOSites/#{@auth_token}/#{@enterprise_guid}"
        Hash[data.map do |s|
          [s['Key'], s['Value']]
        end]
      end
    end
    memoize :sites

    def get_site_creds(site_id)
      return if site_id.nil?
      connect unless connected?
      @site_creds ||= {}
      token = api_get_body(
          "#{@endpoints[:security]}/SSOSiteLogin/#{site_id}/#{@enterprise_guid}/#{@auth_token}/#{@tz_offset}"
        ).gsub('"','') # token is quoted guid for no reason
      @site_creds[site_id] = {
        enterpriseGuid: @enterprise_guid,
        securityToken: token
      }
    end
    memoize :get_site_creds

    def set_program site_id:, program_id:
      creds = get_site_creds(site_id)
      api_post_json "#{@endpoints[:security]}/UpdateCurrentProgram/", {ProgramID: program_id}, creds
    end
    memoize :set_program

    def client_demographic client_id:, site_id:
      creds = get_site_creds(site_id)
      api_get_json "#{@endpoints[:actor]}/participant/#{client_id}", creds
    end
    memoize :client_demographic

    # return client image data or raise an exception
    def client_image client_id:, site_id:
      creds = get_site_creds(site_id)
      connect unless connected?
      response = RestClient.get "#{@endpoints[:actor]}/participant/#{client_id}/image", creds
      response.body
    end

    def enrollments client_id:, site_id:
      creds = get_site_creds(site_id)
      api_get_json "#{@endpoints[:actor]}/participant/enrollment/#{client_id}", creds
    end
    memoize :enrollments

    def site_demographics program_id: nil, site_id:
      creds = get_site_creds(site_id)
      program_ids = if program_id
        [program_id]
      else
        programs(site_id: site_id).keys
      end
      program_ids.flat_map do |program_id|
        api_get_json("#{@endpoints[:forms]}/Forms/Sites/GetSiteDemographics/#{program_id.to_i}", creds).each do |r|
          r['ProgramID'] = program_id
        end
      end
    end
    memoize :site_demographics

    def list_point_of_services program_id: nil, site_id:
      creds = get_site_creds(site_id)
      program_ids = if program_id
        [program_id]
      else
        programs(site_id: site_id).keys
      end
      program_ids.flat_map do |program_id|
        api_get_json("#{@endpoints[:forms]}/Forms/POSList/#{program_id.to_i}", creds).each do |r|
          r['ProgramID'] = program_id
        end
      end
    end
    memoize :list_point_of_services

    # pos_id is a string
    def get_point_of_service pos_id:, site_id:
      creds = get_site_creds(site_id)
      api_get_json "#{@endpoints[:forms]}/Forms/POS/#{pos_id}", creds
    end

    def get_point_of_service_info pos_id:, site_id:
      creds = get_site_creds(site_id)
      api_get_json "#{@endpoints[:forms]}/Forms/POS/GetPosInfo/#{pos_id}", creds
    end

    # def get_point_of_service_for_client program_id: nil, actor_type:, site_id:
    #   creds = get_site_creds(site_id)
    #   program_ids = if program_id
    #     [program_id]
    #   else
    #     programs(site_id: site_id).keys
    #   end
    #   program_ids.flat_map do |program_id|
    #     api_post_json "#{@endpoints[:forms]}/Forms/POS/GetAllActorPOS", {programid: program_id, actorType: actor_type}, creds
    #   end
    # end
     
    def get_client_efforts staff_id:, program_id:, client_id:, site_id:
      creds = get_site_creds(site_id)
      api_get_json "#{@endpoints[:forms]}/Forms/Effort/#{staff_id}/#{program_id}/#{client_id}", creds
    end

    def activities program_id:nil, site_id:, all_activities: nil
      creds = get_site_creds(site_id)
      program_ids = if program_id
        [program_id]
      else
        programs(site_id: site_id).keys
      end
      program_ids.flat_map do |program_id|
        api_get_json"#{@endpoints[:activity]}/Activities/GetActivities?ProgramId#{program_id.to_i}&GetAllActivitySettings=1", creds
      end
    end

    def demographic_defined_values cdid:, site_id:
      creds = get_site_creds(site_id)
      api_get_json "#{@endpoints[:forms]}/Forms/Sites/GetDemographicsDefinedTextValues/#{cdid.to_i}", creds
    end
    memoize :demographic_defined_values

    def entity_types(site_id:)
      creds = get_site_creds(site_id)
      api_get_json "#{@endpoints[:forms]}/Forms/Entity/GetEntityTypes", creds
    end
    memoize :entity_types

    def entity_sub_types(entity_type_id:, site_id:)
      creds = get_site_creds(site_id)
      api_get_json "#{@endpoints[:forms]}/Forms/Entity/GetEntitySubTypes/#{entity_type_id}", creds
    end
    memoize :entity_sub_types

    def entities_by_entity_type_id(entity_type_id:, entity_subtype_id:, programId:, site_id:)
      creds = get_site_creds(site_id)
      api_get_json "#{@endpoints[:forms]}/Forms/Entity/GetEntitiesByEntityTypeID/#{entity_type_id}/#{entity_subtype_id}/#{programId}", creds
    end
    memoize :entities_by_entity_type_id

    def entity_by_id(entity_id:, site_id:)
      creds = get_site_creds(site_id)
      api_get_json "#{@endpoints[:forms]}/Forms/Entity/#{entity_id}", creds
    end
    memoize :entity_by_id

    def entity_contacts(entity_id:, site_id:)
      creds = get_site_creds(site_id)
      api_get_json "#{@endpoints[:forms]}/Forms/Entity/#{entity_id}/Contacts", creds
    end
    memoize :entity_contacts

    def entities(entity_type_id:, entity_subtype_id:, program_id: nil, site_id: )
      program_ids = if program_id
        [program_id]
      else
        programs(site_id).keys
      end
      Hash[program_ids.flat_map do |program_id|
        entitiesByEntityTypeID(entity_type_id,entity_subtype_id,program_id,site_id).map do |e|
          [e['EntityID'], e['EntityName']]
        end
      end]
    end
    memoize :entities

    # # Not sure what this returns, but it works
    # def getEntityAttributesPerSite site_id
    #   creds = get_site_creds(site_id)
    #   api_get_json "#{@endpoints[:forms]}/Forms/Entity/GetEntityAttributesPerSite", creds
    # end

    # # Not sure what this returns, but it works
    # def getAllEntityAttributes site_id
    #   creds = get_site_creds(site_id)
    #   api_get_json "#{@endpoints[:forms]}/Forms/Entity/GetAllEntityAttributes", creds
    # end

    def charactersitic_types_by_id
      {
        1 => 'Non-exclusive choice',
        2 => 'Exclusive Choice',
        3 => 'Arbitrary Text',
        4 => 'Arbitrary Text (long)',
        5 => 'Section Header',
        6 => 'Percent',
        7 => 'Money',
        8 => 'Number',
        9 => 'Boolean',
        10 => 'Date'
      }
    end
    def survey_element_types_by_id
      charactersitic_types_by_id
    end

    def get_entity_by_subject subject_id:, site_id:
      creds = get_site_creds(site_id)
      api_get_json "#{@endpoints[:forms]}/Forms/EntityBySubject/#{subject_id}", creds
    end
    memoize :get_entity_by_subject

    # Not sure what this returns, but it works
    def getAllEntityAttributesDefinedTextValues cdid:, site_id:
      creds = get_site_creds(site_id)
      api_get_json "#{@endpoints[:forms]}/Forms/Entity/GetAllEntityAttributesDefinedTextValues/#{cdid.to_i}", creds
    end


    def assessments(client_id:, site_id:)
      creds = get_site_creds(site_id)
      api_post_json "#{@endpoints[:forms]}/Forms/Assessments/GetAllAssessements/", {surveyResponderType: 0, CLID: client_id.to_s}, creds
    end
    memoize :assessments

    def thrive_assessments(client_id:, site_id:)
      creds = get_site_creds(site_id)
      api_post_json "#{@endpoints[:forms]}/Forms/Assessments/GetAllAssessmentsThrive/", {surveyResponderType: 0, CLID: client_id.to_s}, creds
    end
    memoize :thrive_assessments

    def programs(site_id:, refresh:false)
      creds = get_site_creds(site_id)
      @programs_by_site ||= {}
      @programs_by_site[site_id] = nil if refresh
      @programs_by_site[site_id] ||= begin
        data = api_get_json "#{@endpoints[:forms]}/Forms/Program/GetPrograms/#{site_id}", creds
        Hash[data.map do |p|
          [p['ID'], p['Name']]
        end]
      end
    end
    memoize :programs

    def program(site_id:, id: )
      self.programs(site_id: site_id)[id] if id
    end

    # "HUD Assessment (Entry/Update/Annual/Exit)" is TouchPointID: 75, it doesn't show up in the lists
    # by site
    def touch_points(site_id:, program_id: nil)
      api_get_json "#{@endpoints[:touch_pount]}/ListTouchPoint", get_site_creds(site_id)
    end
    memoize :touch_points

    # "HUD Assessment (Entry/Update/Annual/Exit)" is TouchPointID: 75
    def touch_point(site_id:, id: )
      api_get_json "#{@endpoints[:touch_pount]}/GetTouchPoint?#{{TouchPointID: id}.to_param}&PopulateElementCollection=true", get_site_creds(site_id)
    end
    memoize :touch_point

    def touch_point_response(site_id:, response_id:, touch_point_id:)
      api_get_json "#{@endpoints[:touch_pount]}/GetTouchPointResponse?#{{TouchPointID: touch_point_id, TouchPointResponseID: response_id}.to_param}&PopulateElementCollection=true", get_site_creds(site_id)
    end
    memoize :touch_point_response

    def touch_point_response_by_response_set_id(site_id:, response_set_id:, touch_point_id:)
      api_get_json "#{@endpoints[:touch_pount]}/GetTouchPointResponsesByID?#{{TouchPointID: id, ResponseSetID: response_set_id}.to_param}&PopulateElementCollection=true", get_site_creds(site_id)
    end
    memoize :touch_point_response_by_response_set_id

    def list_touch_point_responses(site_id:, subject_id:, touch_point_id:)
      api_get_json "#{@endpoints[:touch_pount]}/ListTouchPointResponses?#{{SubjectID: subject_id,TouchPointID: touch_point_id}.to_param}", get_site_creds(site_id)
    end
    memoize :list_touch_point_responses

    def touch_point_collection_types(site_id:)
      api_get_json "#{@endpoints[:touch_pount]}/ListCollectionTypes", get_site_creds(site_id)
    end
    memoize :touch_point_collection_types

    def staff(site_id:, id:)
      creds = get_site_creds(site_id)
      api_get_json "#{@endpoints[:staff]}/#{id.to_i}", creds
    end
    memoize :staff

    def search_program(search_term:, program_id: nil, site_id: nil)
      creds = get_site_creds(site_id)
      api_get_json "#{@endpoints[:search]}/Search/#{program_id}/#{search_term}", creds
    end
    memoize :search_program

    def test
      connect unless connected?

      # puts "Sites"
      # sites.each_pair do |id, name|
      #   puts "#{id} => #{name}"
      # end
      # puts

      self.site_id = 19

      puts "Using site '#{site}' (#{site_id}"
      # programs.each_pair do |id, name|
      #   puts "#{id} => #{name}"
      # end

      self.program_id = 51

      puts "Using program '#{program}' (#{program_id})"

      nil
    end

    # Forms/Assessments/GetAssessmentElementResponse/

    def advanced_search(search_params, site_id)
      creds = get_site_creds(site_id)
      api_post_json "#{@endpoints[:search]}/Search/AdvancedSearch/", search_params, creds
    end

    def parse_date(str)
      if md = %r|\A\/Date\((?<ms>-?[\d]+)(?<h>[-+]\d\d)(?<m>\d\d)\)\/\z|.match(str)
        tz = ActiveSupport::TimeZone.all.detect do |z|
          z.utc_offset == (md[:h].to_i*60*60)+(md[:m].to_i*60)
        end
        tz.at(md[:ms].to_f/1000)
      end
    end
  end
end