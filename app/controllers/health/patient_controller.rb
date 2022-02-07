###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class PatientController < IndividualPatientController
    include AjaxModalRails::Controller
    include ClientPathGenerator
    include ActionView::Helpers::NumberHelper

    helper HealthOverviewHelper

    before_action :set_client, only: [:index]
    before_action :set_hpc_patient, only: [:index, :update]

    def index
      load_patient_metrics
      render layout: !request.xhr?
    end

    def update
      @patient.update(patient_params)
      @patient.build_team_member!(Health::Team::CareCoordinator, patient_params[:care_coordinator_id].to_i, current_user) if patient_params[:care_coordinator_id].present?
      @patient.build_team_member!(Health::Team::Nurse, patient_params[:nurse_care_manager_id].to_i, current_user) if patient_params[:nurse_care_manager_id].present?
      if request.xhr?
        head(:ok)
        nil
      else
        respond_with(@patient, location: health_patients_path)
      end
    end

    def patient_params
      params.require(:patient).permit(
        :care_coordinator_id,
        :nurse_care_manager_id,
      )
    end

    def flash_interpolation_options
      { resource_name: 'Patient' }
    end

    protected def title_for_show
      "#{@client.name} - Health"
    end
  end
end
