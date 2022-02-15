###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health::Soap
  class FileList
    def initialize(file_list, soap)
      @file_list = file_list
      @soap = soap
    end

    def payloads(payload_type)
      @file_list.select { |file| file['PayloadType'] == payload_type }.map do |file|
        request_type(file['PayloadType']).new(file['PayloadID'], @soap)
      end
    end

    private def request_type(response_type)
      @request_type_map ||= {
        Health::Soap::MassHealth::ENROLLMENT_RESPONSE_PAYLOAD_TYPE => EnrollmentPayload
      }
      @request_type_map[response_type]
    end
  end
end
