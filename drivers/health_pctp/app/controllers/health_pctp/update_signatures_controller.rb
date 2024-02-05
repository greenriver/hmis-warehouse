###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthPctp
  class UpdateSignaturesController < IndividualPatientController
    include AjaxModalRails::Controller
    include HealthFileController

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_careplan
    before_action :set_upload_object, only: [:edit, :update]

    def edit
      @modal_size = :xxl
    end

    def update
      @careplan.update(careplan_params)

      set_upload_object
      @careplan.health_file.set_calculated!(current_user.id, @client.id) if @careplan.health_file.present?

      redirect_to client_health_careplans_path(@client)
    end

    private def careplan_params
      params.require(:health_pctp_careplan).permit(
        :patient_signed_on,
        :verbal_approval,
        :verbal_approval_followup,
        :provided_to_patient,
        health_file_attributes: [
          :id,
          :file,
          :file_cache,
        ],
      )
    end

    def set_upload_object
      @upload_object = @careplan
      @location = edit_client_health_pctp_careplan_path(client_id: @client.id, id: @careplan.id)
      @download_path = @upload_object.downloadable? ? download_client_health_pctp_careplan_path(client_id: @client.id, id: @careplan.id) : 'javascript:void(0)'
      @download_data = @upload_object.downloadable? ? {} : { confirm: 'Form errors must be fixed before you can download this file.' }
      @remove_path = @upload_object.downloadable? ? remove_file_client_health_pctp_careplan_path(client_id: @client.id, id: @careplan.id) : '#'
    end

    private def set_careplan
      @careplan = @patient.pctps.find(params[:careplan_id])
    end
  end
end
