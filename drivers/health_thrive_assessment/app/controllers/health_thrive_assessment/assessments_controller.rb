###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthThriveAssessment
  class AssessmentsController < HealthController
    include AjaxModalRails::Controller

    before_action :set_patient
    before_action :set_assessment, only: [:edit, :update, :show, :destroy]

    def new
      if @patient.thrive_assessments.in_progress.exists?
        @assessment = @patient.thrive_assessments.in_progress.first
      else
        @assessment = @patient.thrive_assessments.create!(user: current_user)
      end
      redirect_to edit_client_health_thrive_assessment_assessment_path(@client, @assessment)
    end

    def edit
    end

    def update
      @assessment.update(assessment_params)
      redirect_to client_health_careplans_path(@client)
    end

    def show
    end

    def destroy
      @assessment.destroy
      redirect_to client_health_careplans_path(@client)
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

    private def set_patient
      @client = ::GrdaWarehouse::Hud::Client.find(params[:client_id])
      @patient = @client.patient
    end

    private def set_assessment
      @assessment = @patient.thrive_assessments.find(params[:id])
    end

    private def assessment_source
      HealthThriveAssessment::Assessment
    end
  end
end
