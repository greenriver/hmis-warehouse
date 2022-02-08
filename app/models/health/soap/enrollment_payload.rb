###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health::Soap
  class EnrollmentPayload < Payload
    def response
      @soap.generic_results_retrieval_request(payload_type: 'X12_834_Request_005010X220A1', payload_id: @payload_id)
    end
  end
end
