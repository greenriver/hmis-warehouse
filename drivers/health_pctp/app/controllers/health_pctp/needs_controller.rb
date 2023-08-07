###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthPctp
  class NeedsController < IndividualPatientController
    include AjaxModalRails::Controller

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_careplan
    before_action :set_need, only: [:edit, :update, :destroy]

    def index
    end

    def new
      @modal_size = :xxl
      @need = @careplan.needs.build
    end

    def create
      @need = @careplan.needs.create(needs_params)
    end

    def edit
      @modal_size = :xxl
    end

    def update
      @need.update(needs_params)
    end

    def destroy
      @need.destroy
    end

    private def needs_params
      params.require(:health_pctp_need).permit(
        :domain,
        :start_date,
        :end_date,
        :status,
        :need_or_condition,
      )
    end

    private def set_careplan
      @careplan = @patient.pctps.find(params[:careplan_id])
    end

    private def set_need
      @need = @careplan.needs.find(params[:id])
    end
  end
end
