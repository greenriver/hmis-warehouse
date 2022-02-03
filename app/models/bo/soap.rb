###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'curb'

module Bo
  class Soap
    RequestFailed = Class.new(StandardError)

    def initialize(username:, password:)
      @username = username
      @password = password
    end

    def client_lookup_standard(url, start_time:, end_time:)
      data_from(url, client_lookup_standard_xml(start_time: start_time, end_time: end_time))
    end

    def distinct_touch_point_lookup(url, start_time:, end_time:, touch_point_id:)
      data_from(url, distinct_touch_point_lookup_xml(start_time: start_time, end_time: end_time, touch_point_id: touch_point_id))
    end

    def site_touch_point_lookup(url, _options: {})
      data_from(url, site_touch_point_lookup_xml)
    end

    def disability_lookup(url, touch_point_id:, touch_point_question_id:)
      data_from(
        url,
        disability_lookup_xml(
          touch_point_id: touch_point_id,
          touch_point_question_id: touch_point_question_id,
        ),
      )
    end

    def response_lookup(_url)
      raise NotImplementedError
    end

    private def got_response?(response)
      response.response_code == 200 && response.body_str.present?
    end

    def data_from(url, xml)
      response = request(url, xml)
      raise RequestFailed, "Failed to request #{url}; #{response.response_code} http code" unless got_response?(response)

      parsed_result = Hash.from_xml(response.body_str)
      begin
        table = parsed_result.dig('Envelope', 'Body', 'runQueryAsAServiceResponse', 'table')
        return [] if table.blank?

        table['row'].map do |row|
          row.map do |k, v|
            [k.downcase.underscore.to_sym, v]
          end.to_h
        end
      rescue StandardError
        raise RequestFailed, "Failed to parse response #{url}; #{response.response_code} http code"
      end
    end

    def request(url, xml)
      url += '&authType=secEnterprise&locale=en_US&timeout=60&ConvertAnyType=false'
      Curl.post(url, xml) do |curl|
        curl.headers['User-Agent'] = 'OpenPath API Consumer'
        curl.headers['Content-type'] = 'text/xml'
        curl.headers['charset'] = 'UTF-8'
        # curl.headers['SoapAction'] = 'ClientLookupStandard/runQueryAsAService'
      end
    end

    def client_lookup_standard_xml(start_time:, end_time:)
      <<~HEREDOC
        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:cli="ClientLookupStandard">
           <soapenv:Header>
              <cli:QaaWSHeader>
                 <!--Optional:-->
                 <cli:sessionID>?</cli:sessionID>
                 <!--Optional:-->
                 <cli:serializedSession>?</cli:serializedSession>
                 <!--Optional:-->
                 <cli:ClientType>?</cli:ClientType>
                 <!--Optional:-->
                 <cli:AuditingObjectID>?</cli:AuditingObjectID>
                 <!--Optional:-->
                 <cli:AuditingObjectName>?</cli:AuditingObjectName>
              </cli:QaaWSHeader>
           </soapenv:Header>
           <soapenv:Body>
              <cli:runQueryAsAService>
                 <cli:login>#{@username}</cli:login>
                 <cli:password>#{@password}</cli:password>
                 <cli:Enter_value_s__for__Date_Last_Updated___End_>#{end_time.strftime('%FT%T.%L')}</cli:Enter_value_s__for__Date_Last_Updated___End_>
                 <cli:Enter_value_s__for__Date_Last_Updated___Start_>#{start_time.strftime('%FT%T.%L')}</cli:Enter_value_s__for__Date_Last_Updated___Start_>
              </cli:runQueryAsAService>
           </soapenv:Body>
        </soapenv:Envelope>
      HEREDOC
    end

    def distinct_touch_point_lookup_xml(start_time:, end_time:, touch_point_id:)
      <<~HEREDOC
        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:dis="DistinctTouchPointLookup">
           <soapenv:Header>
              <dis:QaaWSHeader>
                 <!--Optional:-->
                 <dis:sessionID>?</dis:sessionID>
                 <!--Optional:-->
                 <dis:serializedSession>?</dis:serializedSession>
                 <!--Optional:-->
                 <dis:ClientType>?</dis:ClientType>
                 <!--Optional:-->
                 <dis:AuditingObjectID>?</dis:AuditingObjectID>
                 <!--Optional:-->
                 <dis:AuditingObjectName>?</dis:AuditingObjectName>
              </dis:QaaWSHeader>
           </soapenv:Header>
           <soapenv:Body>
              <dis:runQueryAsAService>
                 <dis:login>#{@username}</dis:login>
                 <dis:password>#{@password}</dis:password>
                 <dis:Enter_value_s__for__Date_Last_Updated___End_>#{end_time.strftime('%FT%T.%L')}</dis:Enter_value_s__for__Date_Last_Updated___End_>
                 <!--Zero or more repetitions:-->
                 <dis:Enter_value_s__for__TouchPoint_Unique_Identifier_>#{touch_point_id}</dis:Enter_value_s__for__TouchPoint_Unique_Identifier_>
                 <dis:Enter_value_s__for__Date_Last_Updated___Start_>#{start_time.strftime('%FT%T.%L')}</dis:Enter_value_s__for__Date_Last_Updated___Start_>
              </dis:runQueryAsAService>
           </soapenv:Body>
        </soapenv:Envelope>
      HEREDOC
    end

    def site_touch_point_lookup_xml
      <<~HEREDOC
        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:dis="SiteTouchPointLookup">
           <soapenv:Header>
              <dis:QaaWSHeader>
                 <!--Optional:-->
                 <dis:sessionID>?</dis:sessionID>
                 <!--Optional:-->
                 <dis:serializedSession>?</dis:serializedSession>
                 <!--Optional:-->
                 <dis:ClientType>?</dis:ClientType>
                 <!--Optional:-->
                 <dis:AuditingObjectID>?</dis:AuditingObjectID>
                 <!--Optional:-->
                 <dis:AuditingObjectName>?</dis:AuditingObjectName>
              </dis:QaaWSHeader>
           </soapenv:Header>
           <soapenv:Body>
              <dis:runQueryAsAService>
                 <dis:login>#{@username}</dis:login>
                 <dis:password>#{@password}</dis:password>
              </dis:runQueryAsAService>
           </soapenv:Body>
        </soapenv:Envelope>
      HEREDOC
    end

    def disability_lookup_xml(touch_point_id:, touch_point_question_id:)
      <<~HEREDOC
          <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:dis="DisabilityVerifications">
           <soapenv:Header>
              <dis:QaaWSHeader>
                 <!--Optional:-->
                 <dis:sessionID>?</dis:sessionID>
                 <!--Optional:-->
                 <dis:serializedSession>?</dis:serializedSession>
                 <!--Optional:-->
                 <dis:ClientType>?</dis:ClientType>
                 <!--Optional:-->
                 <dis:AuditingObjectID>?</dis:AuditingObjectID>
                 <!--Optional:-->
                 <dis:AuditingObjectName>?</dis:AuditingObjectName>
              </dis:QaaWSHeader>
           </soapenv:Header>
           <soapenv:Body>
              <dis:runQueryAsAService>
                 <dis:login>#{@username}</dis:login>
                 <dis:password>#{@password}</dis:password>
                 <dis:Enter_value_s__for__TouchPoint_Unique_Identifier_>#{touch_point_id}</dis:Enter_value_s__for__TouchPoint_Unique_Identifier_>
                 <dis:Enter_value_s__for__Question_Unique_Identifier_>#{touch_point_question_id}</dis:Enter_value_s__for__Question_Unique_Identifier_>
              </dis:runQueryAsAService>
           </soapenv:Body>
        </soapenv:Envelope>
      HEREDOC
    end
  end
end
