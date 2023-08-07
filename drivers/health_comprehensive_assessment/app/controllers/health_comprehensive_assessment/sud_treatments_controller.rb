###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthComprehensiveAssessment
  class SudTreatmentsController < IndividualPatientController
    include AjaxModalRails::Controller

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_assessment
    before_action :set_treatment, only: [:edit, :update, :destroy]

    def index
    end

    def new
      @modal_size = :xxl
      @treatment = @assessment.sud_treatments.build
    end

    def create
      @treatment = @assessment.sud_treatments.create(treatment_params)
    end

    def edit
      @modal_size = :xxl
    end

    def update
      @treatment.update(treatment_params)
    end

    def destroy
      @treatment.destroy
    end

    private def treatment_params
      params.require(:health_comprehensive_assessment_sud_treatment).permit(
        :service_type,
        :service_dates,
        :reason,
        :provider_name,
        :inpatient,
        :completed,
      )
    end

    private def set_assessment
      @assessment = @patient.comprehensive_assessments.find(params[:assessment_id])
    end

    private def set_treatment
      @treatment = @assessment.sud_treatments.find(params[:id])
    end
  end
end
