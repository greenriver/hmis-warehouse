###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthThriveAssessment
  class AssessmentsController < IndividualPatientController
    include AjaxModalRails::Controller

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_assessment, only: [:edit, :update, :show, :destroy]

    def new
      @assessment = if @patient.thrive_assessments.in_progress.exists?
        @patient.thrive_assessments.in_progress.first
      else
        thrive = @patient.thrive_assessments.create!(user: current_user)
        @patient.hrsn_screenings.create(instrument: thrive)
        thrive
      end
      redirect_to edit_client_health_thrive_assessment_assessment_path(@client, @assessment)
    end

    def edit
    end

    def update
      @assessment.update(assessment_params)
      @patient.current_qa_factory.complete_hrsn(@assessment) if @assessment.completed_on.present?
      respond_with @assessment, location: client_health_careplans_path(@client)
    end

    def show
    end

    def destroy
      @patient.hrsn_screenings.find_by(instrument: @assessment).destroy
      @assessment.destroy
      respond_with @assessment, location: client_health_careplans_path(@client)
    end

    private def assessment_params
      params.require(:health_thrive_assessment_assessment).permit(
        :decline_to_answer,
        :housing_status,
        :food_insecurity,
        :food_worries,
        :trouble_drug_cost,
        :trouble_medical_transportation,
        :trouble_utility_cost,
        :trouble_caring_for_family,
        :unemployed,
        :interested_in_education,
        :help_with_housing,
        :help_with_food,
        :help_with_drug_cost,
        :help_with_medical_transportation,
        :help_with_utilities,
        :help_with_childcare,
        :help_with_eldercare,
        :help_with_job_search,
        :help_with_education,
        :completed_on,
      )
    end

    private def set_assessment
      @assessment = @patient.thrive_assessments.find(params[:id])
    end

    private def assessment_source
      HealthThriveAssessment::Assessment
    end
  end
end
