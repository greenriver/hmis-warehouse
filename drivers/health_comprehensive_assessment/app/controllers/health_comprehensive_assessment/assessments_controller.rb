###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthComprehensiveAssessment
  class AssessmentsController < IndividualPatientController
    include AjaxModalRails::Controller

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_assessment, only: [:edit, :update, :show, :destroy]

    def new
      @assessment = if @patient.comprehensive_assessments.in_progress.exists?
        @patient.comprehensive_assessments.in_progress.first
      else
        @patient.comprehensive_assessments.create!(user: current_user)
      end
      redirect_to edit_client_health_comprehensive_assessment_assessment_path(@client, @assessment)
    end

    def edit
    end

    def update
      @assessment.update(ca_params)
    end

    GROUP_PARAMS = [
      :message_ok, :internet_access, :disabled, :funders, :hip_fracture_status, :other_fracture_status,
      :chronic_pain_status, :alzheimers_status, :dementia_status, :stroke_status, :parkinsons_status,
      :hypertension_status, :cad_status, :chf_status, :copd_status, :asthma_status, :apnea_status,
      :anxiety_status, :bipolar_status, :depression_status, :schizophrenia_status, :cancer_status, :diabetes_status,
      :arthritis_status, :ckd_status, :liver_status, :transplant_status, :weight_status, :other_condition_status,
      :can_communicate_about, :assessed_needs, :substance_use, :sud_treatment_sources, :accessibility_equipment,
      :has_supports, :supports, :advanced_directive, :has_legal_involvement, :legal_involvements, :financial_supports
    ].freeze

    def ca_params
      permitted_cols = ::HealthComprehensiveAssessment::Assessment.column_names.map(&:to_sym) -
        [:id, :user_id, :patient_id, :created_at, :updated_at] # Deny only a few columns, be careful adding new columns!

      permitted_group_cols = GROUP_PARAMS.map { |key| [key, []] }.to_h
      params.require(:health_comprehensive_assessment_assessment).permit(permitted_cols, **permitted_group_cols)
    end

    private def set_assessment
      @assessment = @patient.comprehensive_assessments.find(params[:id])
    end
  end
end
