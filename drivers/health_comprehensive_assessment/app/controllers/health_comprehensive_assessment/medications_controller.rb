###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthComprehensiveAssessment
  class MedicationsController < IndividualPatientController
    include AjaxModalRails::Controller

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_assessment
    before_action :set_medication, only: [:edit, :update, :destroy]

    def index
    end

    def new
      @modal_size = :xxl
      @medication = @assessment.medications.build
    end

    def create
      @medication = @assessment.medications.create(medication_params)
    end

    def edit
      @modal_size = :xxl
    end

    def update
      @medication.update(medication_params)
    end

    def destroy
      @medication.destroy
    end

    private def medication_params
      params.require(:health_comprehensive_assessment_medication).permit(:medication, :dosage, :side_effects)
    end

    private def set_assessment
      @assessment = @patient.comprehensive_assessments.find(params[:assessment_id])
    end

    private def set_medication
      @medication = @assessment.medications.find(params[:id])
    end
  end
end
