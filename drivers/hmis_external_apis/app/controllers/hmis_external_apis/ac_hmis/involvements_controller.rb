###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class InvolvementsController < HmisExternalApis::BaseController
    def client
      # ClientInvolvement.new(client_params)
      render json: { something: :happening }
    end

    def program
      # ProgramInvolvement.new(program_params)
      render json: { something: :happening }
    end

    protected

    def internal_system
      @internal_system ||= HmisExternalApis::InternalSystem.where(name: 'Involvements').first
    end

    def program_params
      params.permit(:program_id, :start_date, :end_date)
    end

    def client_params
      params.permit(:start_date, :end_date, mci_ids: [])
    end
  end
end
