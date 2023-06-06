###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class InvolvementsController < HmisExternalApis::BaseController
    def client
      involvement = ClientInvolvement.new(client_params)

      involvement.validate_request!

      render json: involvement.to_json, status: (involvement.ok? ? :ok : :bad_request)
    end

    def program
      involvement = ProgramInvolvement.new(program_params)

      involvement.validate_request!

      render json: involvement.to_json, status: (involvement.ok? ? :ok : :bad_request)
    end

    protected

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
