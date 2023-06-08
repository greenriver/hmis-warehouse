###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthPctp
  class CareplansController < IndividualPatientController
    include AjaxModalRails::Controller

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_careplan, only: [:edit, :update, :show, :destroy]

    def new
      @careplan = if @patient.pctps.in_progress.exists?
        @patient.pctps.in_progress.first
      else
        @patient.pctps.create!(user: current_user)
      end
      redirect_to edit_client_health_pctp_careplan_path(@client, @careplan)
    end

    def edit
    end

    def update
      @careplan.update(careplan_params)
      respond_with @careplan, location: client_health_careplans_path(@client)
    end

    def show
    end

    def destroy
      @careplan.destroy
      respond_with @careplan, location: client_health_careplans_path(@client)
    end

    GROUP_PARAMS = [
      :accommodation_types,
      :accessibility_equipment,
    ].freeze

    private def careplan_params
      permitted_cols = ::HealthComprehensiveAssessment::Assessment.column_names.map(&:to_sym) -
        [:id, :user_id, :patient_id, :created_at, :updated_at] # Deny protected columns, be careful adding new columns!

      permitted_cols -= [:reviewed_by_ccm_id, :reviewed_by_ccm_on] unless current_user.can_approve_cha?
      permitted_cols -= [:reviewed_by_rn_id, :reviewed_by_rn_on] unless current_user.can_approve_careplan?

      permitted_group_cols = GROUP_PARAMS.map { |key| [key, []] }.to_h
      params.require(:health_pctp_careplan).permit(permitted_cols, **permitted_group_cols)
    end

    private def set_careplan
      @careplan = @patient.pctps.find(params[:id])
    end

    private def careplan_source
      HealthPctp::Careplan
    end
  end
end
