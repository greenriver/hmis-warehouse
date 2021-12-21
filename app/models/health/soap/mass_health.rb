###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'curb'

module Health::Soap
  class MassHealth
    RequestFailed = Class.new(StandardError)

    ENROLLMENT_RESPONSE_PAYLOAD_TYPE = 'X12_834_Response_005010X220A1'.freeze
    ELIGIBILITY_RESPONSE_PAYLOAD_TYPE = 'X12_005010_Request_Batch_Results_271'.freeze

    def initialize(test: false)
      @config = Config.where(name: 'masshealth').first_or_initialize
      if test
        @url = @config.test_url
      else
        @url = @config.production_url
      end
    end

    def configured?
      @config.user.present? && @config.pass.present? && @config.sender.present? && @config.receiver.present? && @url.present?
    end

    def realtime_eligibility_inquiry_request(edi_doc:)
      result = request(
        action: 'RealTimeTransaction',
        xml: realtime_eligibility_inquiry_request_xml(edi_doc),
      )
      return parse_result(result)
    end

    def batch_eligibility_inquiry(edi_doc:)
      result = request_with_attachment(
        action: 'BatchSubmitTransaction',
        xml: batch_eligibility_request_xml(edi_doc),
        attachment: edi_doc,
      )
      return parse_result(result)
    end

    def file_list
      result = generic_results_retrieval_request(payload_type: 'FILELIST', payload_id: 'FILELIST')
      file_list = Array.wrap(Hash.from_xml(result.response)&.dig('FileList', 'File')).uniq
      return ::Health::Soap::FileList.new(file_list, self)
    rescue StandardError
      message = result&.response&.error_message
      raise message if message.present?

      raise # Don't swallow the original exception if we don't have an error message from the API
    end

    def generic_results_retrieval_request(payload_type:, payload_id:)
      result = request(
        action: 'GenericBatchRetrievalTransaction',
        xml: generic_results_retrieval_request_xml(payload_type, payload_id),
      )
      return parse_result(result)
    end

    def success?(result)
      return false unless result.first.is_a?(Hash)

      result.first.dig('Envelope', 'Body', 'COREEnvelopeBatchSubmissionResponse', 'ErrorCode') == 'Success' ||
        result.first.dig('Envelope', 'Body', 'COREEnvelopeRealTimeResponse', 'ErrorCode') == 'Success' ||
        result.first.dig('Envelope', 'Body', 'COREEnvelopeBatchResultsRetrievalResponse', 'ErrorCode') == 'Success'
    end

    def response(result)
      result.last ||
        result.first.dig('Envelope', 'Body', 'COREEnvelopeRealTimeResponse', 'Payload')
    end

    def payload_id(result)
      result.first.dig('Envelope', 'Body', 'COREEnvelopeBatchSubmissionResponse', 'PayloadID') ||
        result.first.dig('Envelope', 'Body', 'COREEnvelopeRealTimeResponse', 'PayloadID')
    end

    def error_message(result)
      return result unless result.first.is_a?(Hash)

      result.first.dig('Envelope', 'Body', 'COREEnvelopeBatchSubmissionResponse', 'ErrorMessage') ||
        result.first.dig('Envelope', 'Body', 'COREEnvelopeRealTimeResponse', 'ErrorMessage') ||
        result.first.dig('Envelope', 'Body', 'Fault', 'detail', 'Message')
    end

    # Submit a simple request
    private def request(action:, xml:)
      response = Curl.post(@url, request_xml(xml)) do |curl|
        curl.headers['User-Agent'] = 'OpenPath MassHealth Interface'
        curl.headers['Content-type'] = 'text/xml'
        curl.headers['charset'] = 'UTF-8'
        curl.headers['SoapAction'] = action
      end
      raise RequestFailed if response.response_code != 200 || response.body_str.blank?

      response
    end

    # Submit a multi-part request with an attachment
    private def request_with_attachment(action:, xml:, attachment:)
      boundary = "Part-#{SecureRandom.uuid}"
      response = Curl.post(@url, request_with_attachment_xml(xml, attachment, boundary)) do |curl|
        curl.headers['User-Agent'] = 'OpenPath MassHealth Interface'
        curl.headers['Content-type'] = " multipart/related; type=\"application/xop+xml\"; start=\"rootpart\"; start-info=\"application/soap+xml\"; action=\"#{action}\"; boundary=\"#{boundary}\""
        curl.headers['charset'] = 'UTF-8'
      end
      raise RequestFailed if response.response_code != 200 || response.body_str.blank?

      response
    end

    # Parse the response. Generally, MassHealth responds with a multipart, so we use the Mail parser to decode the message
    private def parse_result(result)
      body = result.body_str
      if body[0..1] == '--'
        header = "Content-Type: multipart/alternative; boundary=\"#{body.lines.first.strip[2..]}\"\r\n\r\n"
      else
        header = "Content-Type: text/plain\r\n\r\n"
      end
      message = Mail.read_from_string(header + body)
      if message.multipart?
        return SoapResponse.new(self, [Hash.from_xml(message.parts.first.decoded), message.parts.last.decoded]) if message.parts.size > 1

        return SoapResponse.new(self, [Hash.from_xml(message.parts.first.decoded), nil])
      else
        decoded = message.decoded
        return SoapResponse.new(self, [Hash.from_xml(decoded), nil]) if decoded[0..4] == '<?xml'

        return SoapResponse.new(self, [message.decoded, nil])
      end
    end

    private def generic_results_retrieval_request_xml(payload_type, payload_id)
      timestamp = Time.now.utc.iso8601
      <<~HEREDOC
        <cor:COREEnvelopeBatchResultsRetrievalRequest>
           <PayloadType>#{payload_type}</PayloadType>
           <ProcessingMode>Batch</ProcessingMode>
           <PayloadID>#{payload_id}</PayloadID>
           <TimeStamp>#{timestamp}</TimeStamp>
           <SenderID>#{@config.sender}</SenderID>
           <ReceiverID>#{@config.receiver}</ReceiverID>
           <CORERuleVersion>2.2.0</CORERuleVersion>
        </cor:COREEnvelopeBatchResultsRetrievalRequest>
      HEREDOC
    end

    private def realtime_eligibility_inquiry_request_xml(edi_doc)
      timestamp = Time.now.utc.iso8601
      payload_id = SecureRandom.uuid
      <<~HEREDOC
        <cor:COREEnvelopeRealTimeRequest>
           <PayloadType>X12_270_Request_005010X279A1</PayloadType>
           <ProcessingMode>RealTime</ProcessingMode>
           <PayloadID>#{payload_id}</PayloadID>
           <TimeStamp>#{timestamp}</TimeStamp>
           <SenderID>#{@config.sender}</SenderID>
           <ReceiverID>#{@config.receiver}</ReceiverID>
           <CORERuleVersion>2.2.0</CORERuleVersion>
           <Payload><![CDATA[#{edi_doc}]]></Payload>
        </cor:COREEnvelopeRealTimeRequest>
      HEREDOC
    end

    private def batch_eligibility_request_xml(attachment)
      timestamp = Time.now.utc.iso8601
      payload_id = SecureRandom.uuid
      checksum = Digest::SHA1.hexdigest(attachment)
      <<~HEREDOC
        <cor:COREEnvelopeBatchSubmission>
          <PayloadType>X12_270_Request_005010X279A1</PayloadType>
          <ProcessingMode>Batch</ProcessingMode>
          <PayloadID>#{payload_id}</PayloadID>
          <PayloadLength>#{attachment.length}</PayloadLength>
          <TimeStamp>#{timestamp}</TimeStamp>
          <SenderID>#{@config.sender}</SenderID>
          <ReceiverID>#{@config.receiver}</ReceiverID>
          <CORERuleVersion>2.2.0</CORERuleVersion>
          <CheckSum>#{checksum}</CheckSum>
           <Payload>
            <xop:Include href="cid:attachment" xmlns:xop="http://www.w3.org/2004/08/xop/include"/>
           </Payload>
        </cor:COREEnvelopeBatchSubmission>
      HEREDOC
    end

    private def request_xml(body)
      <<~HEREDOC
        <soap:Envelope xmlns:cor="http://www.caqh.org/SOAP/WSDL/CORERule2.2.0.xsd" xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
          <soap:Header>
            #{wsse_header_xml}
          </soap:Header>
          <soap:Body>
            #{body}
          </soap:Body>
        </soap:Envelope>
      HEREDOC
    end

    private def request_with_attachment_xml(body, attachment, boundary)
      <<~HEREDOC
        --#{boundary}
        Content-Type: application/xop+xml; charset=UTF-8; type="application/soap+xml"; action="BatchSubmitTransaction"
        Content-Transfer-Encoding: binary
        Content-ID: rootpart

        #{request_xml(body)}
        --#{boundary}
        Content-Type: application/xml
        Content-Transfer-Encoding: binary
        Content-ID: attachment

        #{attachment}
        --#{boundary}--
      HEREDOC
    end

    private def wsse_header_xml
      <<~HEREDOC
        <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
            xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
          <wsse:UsernameToken>
            <wsse:Username>#{@config.user}</wsse:Username>
            <wsse:Password>#{@config.pass}</wsse:Password>
          </wsse:UsernameToken>
        </wsse:Security>
      HEREDOC
    end
  end
end
