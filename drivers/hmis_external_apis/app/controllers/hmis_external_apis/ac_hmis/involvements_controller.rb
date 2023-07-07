###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class InvolvementsController < HmisExternalApis::BaseController
    MAX_RESPONSE_SIZE_TO_SAVE = 1.kilobyte

    def client
      involvement = nil

      json_payload = log_request_with_truncation do
        involvement = ClientInvolvement.new(client_params)
        involvement.validate_request!
        involvement.to_json
      end

      render json: json_payload, status: (involvement.ok? ? :ok : :bad_request)
    end

    def program
      involvement = nil

      json_payload = log_request_with_truncation do
        involvement = ProgramInvolvement.new(program_params)
        involvement.validate_request!
        involvement.to_json
      end

      render json: json_payload, status: (involvement.ok? ? :ok : :bad_request)
    end

    protected

    def log_request_with_truncation &block
      block.call.tap do |json_payload|
        request_log.update!(response: json_payload.first(MAX_RESPONSE_SIZE_TO_SAVE))
      end
    end

    def internal_system
      @internal_system ||= HmisExternalApis::InternalSystem.where(name: 'Involvements').first
    end

    def program_params
      params.permit(:start_date, :end_date, program_ids: [])
    end

    def client_params
      params.permit(:start_date, :end_date, mci_ids: [])
    end
  end
end
