###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Health::Soap
  class SoapResponse

    def initialize(soap, response)
     @soap = soap
     @response = response
    end

    def success?
      @soap.success?(@response)
    end

    def response
      @soap.response(@response)
    end

    def payload_id
      @soap.payload_id(@response)
    end

    def error_message
      @soap.error_message(@response)
    end
  end
end
