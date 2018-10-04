class HelloSignController < ActionController::Base
  def callback
    Rails.logger.info "HelloSign Callback data: params: #{params.ai(plain: true)}"

    response = CallbackResponse.new(params[:json])

    if response.valid? && response.has_careplan?
      response.process!
      Rails.logger.info "#{response.signer_email_addresses.join('; ')} have signed."
    end

    # HelloSign expects this. Do not change or remove:
    render text: "Hello API Event Received"
  end

  class CallbackResponse
    attr_accessor :signable_document, :json

    def initialize(json)
      self.json = json
    end

    def valid?
      begin
        !!_data && !!_signature_request
      rescue TypeError, JSON::ParserError
        return false
      end
    end

    def signable_document
      return @signable_document unless @signable_document.nil?

      signable_document_id = _signature_request.dig('metadata', 'signable_document_id') 

      @signable_document = Health::SignableDocument.find(signable_document_id)
    end

    def careplan
      return nil unless signable_document.signable.is_a? Health::Careplan

      signable_document.signable
    end

    def process!
      signable_document.update_who_signed_from_hello_sign_callback!(_signature_request)
      signable_document.update_careplan_and_health_file!(careplan)
    end

    def has_careplan?
      !!careplan
    end

    def signer_email_addresses
      _signature_request['signatures'].
        select { |s| s['status_code'] == 'signed' }.
        map do |s|
          s['signer_email_address']
        end
    end

    private

    def _signature_request 
      @signature_request ||= _data.dig('signature_request')
    end

    def _data
      @_data ||= JSON.parse(json)
    end
  end
end
